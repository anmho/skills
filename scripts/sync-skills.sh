#!/usr/bin/env bash
# Materialise external skills listed in skills-manifest.yaml into ./skills/.
# agent-skills-eval does not follow symlinks, so we copy. Manifest entries are
# rebuilt every run so the runner sees the canonical source as it is right now.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${SKILLS_MANIFEST:-${REPO_ROOT}/skills-manifest.yaml}"
SKILLS_DIR="${REPO_ROOT}/skills"

if [[ ! -f "${MANIFEST}" ]]; then
  echo "sync-skills: no manifest at ${MANIFEST}, nothing to sync" >&2
  exit 0
fi

# Parse `<slug>: <path>` pairs under the `external:` key. Two-space indent
# expected, comments and blank lines ignored. Source paths may use ~.
python3 - "$MANIFEST" "$SKILLS_DIR" <<'PY'
import os, shutil, sys, re

manifest_path, skills_dir = sys.argv[1], sys.argv[2]

# Hand-rolled tiny YAML reader so we don't require PyYAML.
in_external = False
entries = []
with open(manifest_path) as f:
    for raw in f:
        line = raw.rstrip("\n")
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if not line.startswith(" "):
            in_external = (stripped == "external:")
            continue
        if not in_external:
            continue
        m = re.match(r"\s+([A-Za-z0-9_.\-]+):\s*(.+?)\s*$", line)
        if m:
            entries.append((m.group(1), os.path.expanduser(m.group(2))))

if not entries:
    print("sync-skills: manifest has no external: entries")
    sys.exit(0)

for slug, src in entries:
    if not os.path.isdir(src):
        print(f"sync-skills: ERROR source missing for '{slug}': {src}", file=sys.stderr)
        sys.exit(1)
    dst = os.path.join(skills_dir, slug)
    if os.path.islink(dst) or os.path.exists(dst):
        if os.path.islink(dst):
            os.unlink(dst)
        else:
            shutil.rmtree(dst)
    shutil.copytree(src, dst, symlinks=False)
    print(f"sync-skills: {slug} <= {src}")
PY
