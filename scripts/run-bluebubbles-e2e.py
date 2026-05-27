#!/usr/bin/env python3
"""Inject BlueBubbles webhook events into Hermes and grade agent replies.

By default uses **capture-only** mode: inbound webhooks still exercise the real
agent, but outbound iMessage is suppressed via ~/.hermes/.e2e_suppress_imessage
(chat-presence plugin). Replies are read from ~/.hermes/.e2e_last_reply.json so
you do not get synthetic traffic in your owner self-DM.

Set HERMES_E2E_CAPTURE_ONLY=0 to poll BlueBubbles for real sent bubbles (only
safe when chat is not your owner home DM, or set HERMES_E2E_ALLOW_OWNER_DM=1).
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable
from uuid import uuid4

REPO_ROOT = Path(__file__).resolve().parents[1]
HERMES_DIR = Path.home() / ".hermes"
HERMES_ENV = HERMES_DIR / ".env"
E2E_SUPPRESS_FLAG = HERMES_DIR / ".e2e_suppress_imessage"
E2E_PENDING_FILE = HERMES_DIR / ".e2e_pending.json"
E2E_LAST_REPLY_FILE = HERMES_DIR / ".e2e_last_reply.json"
DEFAULT_CHAT_GUID = "any;-;+19492454518"
DEFAULT_SENDER = "+19492454518"
WEBHOOK_HOST = "localhost"  # Hermes binds *:8645 (IPv6); 127.0.0.1 may refuse
WEBHOOK_PORT = 8645
WEBHOOK_PATH = "/bluebubbles-webhook"
MARKER_RE = re.compile(r"\[e2e:([a-z0-9_-]+):([a-f0-9]{8})\]", re.I)


def load_env_value(key: str) -> str:
    if key in os.environ:
        return os.environ[key].strip()
    if not HERMES_ENV.is_file():
        return ""
    for line in HERMES_ENV.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        if k.strip() == key:
            return v.strip().strip('"').strip("'")
    return ""


def capture_only_enabled() -> bool:
    return os.environ.get("HERMES_E2E_CAPTURE_ONLY", "1").strip().lower() not in (
        "0",
        "false",
        "no",
    )


def owner_handles() -> set[str]:
    handles: set[str] = set()
    for key in ("HERMES_OWNER_HANDLES", "BLUEBUBBLES_ALLOWED_USERS"):
        raw = load_env_value(key)
        if raw:
            handles.update(h.strip() for h in raw.split(",") if h.strip())
    if DEFAULT_SENDER:
        handles.add(DEFAULT_SENDER)
    return handles


def is_owner_home_dm(chat_guid: str, sender: str) -> bool:
    home = load_env_value("BLUEBUBBLES_HOME_CHANNEL") or DEFAULT_CHAT_GUID
    return chat_guid.strip() == home.strip() and sender.strip() in owner_handles()


def set_capture_mode(enabled: bool, *, marker: str = "", eval_id: str = "") -> None:
    HERMES_DIR.mkdir(parents=True, exist_ok=True)
    if enabled:
        E2E_PENDING_FILE.write_text(
            json.dumps({"marker": marker, "eval_id": eval_id}, indent=2)
        )
        E2E_SUPPRESS_FLAG.touch()
        if E2E_LAST_REPLY_FILE.is_file():
            E2E_LAST_REPLY_FILE.unlink()
    else:
        E2E_SUPPRESS_FLAG.unlink(missing_ok=True)
        E2E_PENDING_FILE.unlink(missing_ok=True)
        E2E_LAST_REPLY_FILE.unlink(missing_ok=True)


def extract_user_text(prompt: str) -> str:
    prefix = "In a BlueBubbles/iMessage chat, the user asks:"
    if prompt.strip().startswith(prefix):
        return prompt.split(":", 1)[1].strip()
    return prompt.strip()


@dataclass
class E2ECase:
    eval_id: str
    prompt: str
    checks: list[Callable[[str], tuple[bool, str]]] = field(default_factory=list)
    timeout_s: int = 120
    skill_slash: str | None = None  # e.g. gmail-threads → "/gmail-threads …"


def check_contains(substr: str, label: str | None = None) -> Callable[[str], tuple[bool, str]]:
    def _fn(text: str) -> tuple[bool, str]:
        ok = substr.lower() in text.lower()
        return ok, f"{label or substr!r}: {'found' if ok else 'missing'}"

    return _fn


def check_regex(pattern: str, label: str) -> Callable[[str], tuple[bool, str]]:
    rx = re.compile(pattern, re.I | re.S)

    def _fn(text: str) -> tuple[bool, str]:
        ok = bool(rx.search(text))
        return ok, f"{label}: {'matched' if ok else 'no match'}"

    return _fn


def check_max_lines(n: int) -> Callable[[str], tuple[bool, str]]:
    def _fn(text: str) -> tuple[bool, str]:
        lines = [ln for ln in text.strip().splitlines() if ln.strip()]
        ok = len(lines) <= n
        return ok, f"≤{n} lines: got {len(lines)}"

    return _fn


def check_any_contains(*substrings: str, label: str = "any of") -> Callable[[str], tuple[bool, str]]:
    def _fn(text: str) -> tuple[bool, str]:
        lower = text.lower()
        hit = next((s for s in substrings if s.lower() in lower), None)
        ok = hit is not None
        found = repr(hit) if hit else "none found"
        return ok, f"{label}: {found}"

    return _fn


def check_not_contains(substr: str, label: str) -> Callable[[str], tuple[bool, str]]:
    def _fn(text: str) -> tuple[bool, str]:
        ok = substr.lower() not in text.lower()
        return ok, f"not {label}: {'ok' if ok else 'found forbidden phrase'}"

    return _fn


def post_webhook(password: str, chat_guid: str, sender: str, text: str) -> None:
    payload = {
        "type": "new-message",
        "data": {
            "guid": f"e2e-{uuid4()}",
            "text": text,
            "handle": {"address": sender},
            "isFromMe": False,
            "chats": [{"guid": chat_guid, "chatIdentifier": sender}],
        },
    }
    url = f"http://{WEBHOOK_HOST}:{WEBHOOK_PORT}{WEBHOOK_PATH}?password={urllib.request.quote(password)}"
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read().decode()
        if resp.status != 200 or body.strip().lower() not in ("ok", '"ok"'):
            raise RuntimeError(f"webhook unexpected response {resp.status}: {body[:200]}")


def bb_messages_after(chat_guid: str, after_epoch: int) -> list[dict[str, Any]]:
    cmd = [
        "bluebubbles",
        "messages",
        "list",
        "--chat",
        chat_guid,
        "--from-me",
        "--after",
        str(after_epoch),
        "--limit",
        "30",
        "-o",
        "json",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or proc.stdout.strip() or "messages list failed")
    data = json.loads(proc.stdout)
    rows = data.get("data") if isinstance(data, dict) else data
    if not isinstance(rows, list):
        return []
    return [r for r in rows if isinstance(r, dict)]


def collect_new_agent_texts(
    chat_guid: str,
    after_epoch: int,
    baseline_guids: set[str],
) -> list[str]:
    texts: list[str] = []
    for msg in bb_messages_after(chat_guid, after_epoch):
        guid = str(msg.get("guid") or "")
        if guid in baseline_guids:
            continue
        text = str(msg.get("text") or msg.get("message") or "").strip()
        if text and not MARKER_RE.search(text):
            texts.append(text)
    return texts


def wait_for_reply(
    chat_guid: str,
    started_at: float,
    timeout_s: int,
    baseline_guids: set[str],
    quiet_s: float = 12.0,
) -> str:
    """Wait until the agent stops sending bubbles for quiet_s seconds (multi-turn)."""
    after_epoch = int(started_at) - 2
    deadline = time.time() + timeout_s
    last_change = 0.0
    combined = ""

    while time.time() < deadline:
        parts = collect_new_agent_texts(chat_guid, after_epoch, baseline_guids)
        blob = "\n\n".join(parts).strip()
        if blob and blob != combined:
            combined = blob
            last_change = time.time()
        elif combined and last_change and (time.time() - last_change) >= quiet_s:
            return combined
        time.sleep(2)

    if combined:
        return combined
    raise TimeoutError(f"no agent reply within {timeout_s}s")


def wait_for_captured_reply(
    marker: str,
    timeout_s: int,
    quiet_s: float = 12.0,
) -> str:
    """Wait until the gateway stops appending captured outbound parts."""
    deadline = time.time() + timeout_s
    last_change = 0.0
    combined = ""

    while time.time() < deadline:
        if E2E_LAST_REPLY_FILE.is_file():
            try:
                payload = json.loads(E2E_LAST_REPLY_FILE.read_text())
            except json.JSONDecodeError:
                payload = {}
            if str(payload.get("marker") or "") == marker:
                blob = str(payload.get("reply") or "").strip()
                if blob and blob != combined:
                    combined = blob
                    last_change = time.time()
                elif combined and last_change and (time.time() - last_change) >= quiet_s:
                    return combined
        time.sleep(2)

    if combined:
        return combined
    raise TimeoutError(
        f"no captured agent reply within {timeout_s}s "
        f"(is Hermes running with chat-presence plugin loaded?)"
    )


def run_case(
    password: str,
    chat_guid: str,
    sender: str,
    case: E2ECase,
    *,
    capture_only: bool,
) -> dict[str, Any]:
    token = uuid4().hex[:8]
    marker = f"[e2e:{case.eval_id}:{token}]"
    user_text = extract_user_text(case.prompt)
    if case.skill_slash:
        user_text = f"/{case.skill_slash.strip('/')} {user_text}"
    inbound = f"{marker}\n{user_text}"

    print(f"\n=== {case.eval_id} ===", flush=True)
    mode = "capture-only (no iMessage outbound)" if capture_only else "live iMessage"
    print(f"mode: {mode}", flush=True)
    print(f"→ user: {user_text[:120]}{'…' if len(user_text) > 120 else ''}", flush=True)

    started = time.time()
    baseline: set[str] = set()
    if not capture_only:
        baseline = {str(m.get("guid") or "") for m in bb_messages_after(chat_guid, int(started) - 60)}

    if capture_only:
        set_capture_mode(True, marker=marker, eval_id=case.eval_id)
    try:
        post_webhook(password, chat_guid, sender, inbound)
        if capture_only:
            reply = wait_for_captured_reply(marker, case.timeout_s)
        else:
            reply = wait_for_reply(chat_guid, started, case.timeout_s, baseline)
    finally:
        if capture_only:
            set_capture_mode(False)

    print(f"← agent ({len(reply)} chars):", flush=True)
    preview = reply.replace("\n", " \\n ")
    print(f"   {preview[:400]}{'…' if len(preview) > 400 else ''}", flush=True)

    if re.search(r"rate limit|HTTP 429|usage limit", reply, re.I):
        raise RuntimeError(
            "Hermes provider rate-limited (HTTP 429); retry E2E later or switch model"
        )

    results: list[dict[str, Any]] = []
    passed = 0
    for check in case.checks:
        ok, evidence = check(reply)
        results.append({"passed": ok, "evidence": evidence})
        print(f"   {'PASS' if ok else 'FAIL'}: {evidence}", flush=True)
        if ok:
            passed += 1

    return {
        "eval_id": case.eval_id,
        "marker": marker,
        "reply": reply,
        "passed": passed,
        "failed": len(results) - passed,
        "total": len(results),
    }


def main() -> int:
    password = load_env_value("BLUEBUBBLES_PASSWORD")
    if not password:
        print("BLUEBUBBLES_PASSWORD not set in env or ~/.hermes/.env", file=sys.stderr)
        return 2

    chat_guid = load_env_value("HERMES_E2E_CHAT_GUID") or load_env_value(
        "BLUEBUBBLES_HOME_CHANNEL"
    ) or DEFAULT_CHAT_GUID
    sender = (
        load_env_value("HERMES_E2E_SENDER")
        or load_env_value("BLUEBUBBLES_ALLOWED_USERS").split(",")[0].strip()
        or DEFAULT_SENDER
    )
    capture_only = capture_only_enabled()

    if is_owner_home_dm(chat_guid, sender) and not capture_only:
        allow = os.environ.get("HERMES_E2E_ALLOW_OWNER_DM", "").strip().lower() in (
            "1",
            "true",
            "yes",
        )
        if not allow:
            print(
                "Refusing live E2E in owner home DM (injects as you → agent texts you back).\n"
                "Use default capture-only (HERMES_E2E_CAPTURE_ONLY=1) or set "
                "HERMES_E2E_ALLOW_OWNER_DM=1 to override.",
                file=sys.stderr,
            )
            return 2

    primary_cases = [
        E2ECase(
            eval_id="bb-iconfit-email",
            timeout_s=180,
            skill_slash="gmail-threads",
            prompt="In a BlueBubbles/iMessage chat, the user asks: where's the iconfit confirmation email",
            checks=[
                check_contains("mail.google.com", "gmail url"),
                check_any_contains(
                    "iconfit",
                    "michael",
                    "confirmation",
                    "A88123",
                    "orders@iconfit",
                    label="order/email mention",
                ),
                check_not_contains("want me to check gmail", "no gmail clarify"),
                check_max_lines(6),
            ],
        ),
        E2ECase(
            eval_id="bb-gmail-tax-status",
            timeout_s=180,
            skill_slash="gmail-threads",
            prompt="In a BlueBubbles/iMessage chat, the user asks: What is the status of my tax collection document email to jenny and mom",
            checks=[
                check_contains("mail.google.com", "gmail url"),
                check_any_contains(
                    "tax",
                    "jenny",
                    "mom",
                    "draft",
                    "document",
                    label="tax thread mention",
                ),
                check_not_contains("attached w2", "no full body paste"),
                check_max_lines(6),
            ],
        ),
    ]

    optional_cases = [
        E2ECase(
            eval_id="bb-saturday",
            timeout_s=180,
            skill_slash="bluebubbles-cli",
            prompt="In a BlueBubbles/iMessage chat, the user asks: Where did I go on Saturday? Today is 2026-05-27 (Wednesday) in America/Los_Angeles.",
            checks=[
                check_regex(r"seven\s*lions|bill\s*graham", "venue/event"),
                check_not_contains("i'll search", "tool preamble"),
                check_max_lines(5),
            ],
        ),
        E2ECase(
            eval_id="bb-pr-links",
            timeout_s=180,
            skill_slash="gmail-threads",
            prompt="In a BlueBubbles/iMessage chat, the user asks: Send me the links for my top graphite prs to review",
            checks=[
                check_regex(r"github\.com/", "github url"),
                check_not_contains("i'll search", "tool preamble"),
                check_max_lines(8),
            ],
        ),
        E2ECase(
            eval_id="gmail-send-link",
            skill_slash="gmail-threads",
            prompt="I just looked up an email with thread_id 18f4c2a1b2d3e4f5. Send me the link.",
            checks=[
                check_contains("mail.google.com", "gmail url"),
                check_contains("18f4c2a1b2d3e4f5", "thread id in url or text"),
                check_max_lines(6),
            ],
            timeout_s=180,
        ),
    ]

    include_optional = os.environ.get("HERMES_E2E_OPTIONAL", "").strip().lower() in (
        "1",
        "true",
        "yes",
    )
    cases = primary_cases + (optional_cases if include_optional else [])

    # Filter: HERMES_E2E_CASES=bb-iconfit-email,bb-gmail-tax-status,bb-pr-links
    only = load_env_value("HERMES_E2E_CASES")
    if only:
        wanted = {x.strip() for x in only.split(",") if x.strip()}
        all_cases = primary_cases + optional_cases
        cases = [c for c in all_cases if c.eval_id in wanted]

    mode_label = "capture-only" if capture_only else "live iMessage"
    print(
        f"BlueBubbles E2E ({mode_label}) → Hermes webhook "
        f"(chat={chat_guid}, sender={sender})",
        flush=True,
    )
    if capture_only and not E2E_SUPPRESS_FLAG.parent.is_dir():
        print("warning: ~/.hermes missing; capture flag may not be honored", flush=True)

    summaries = []
    for case in cases:
        try:
            summaries.append(
                run_case(
                    password,
                    chat_guid,
                    sender,
                    case,
                    capture_only=capture_only,
                )
            )
        except Exception as exc:
            print(f"   ERROR: {exc}", flush=True)
            summaries.append({"eval_id": case.eval_id, "error": str(exc), "passed": 0, "failed": 1, "total": 1})

    total_pass = sum(s.get("passed", 0) for s in summaries)
    total_fail = sum(s.get("failed", 0) for s in summaries)
    print(f"\nE2E summary: {total_pass} passed, {total_fail} failed checks", flush=True)
    return 0 if total_fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
