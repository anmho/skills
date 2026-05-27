# anmho/skills

Custom Codex skills repository.

## Install a skill

```bash
npx skills add anmho/skills --skill <skill-name> --global -y
```

Example:

```bash
npx skills add anmho/skills --skill bluebubbles-cli --global -y
npx skills add anmho/skills --skill auth --global -y
npx skills add anmho/skills --skill graphite --global -y
npx skills add anmho/skills --skill notifications --global -y
npx skills add anmho/skills --skill symphony --global -y
npx skills add anmho/skills --skill tab-organizer-cleanup --global -y
```

`npx skills add` symlinks into agent skill directories by default (`--copy` to materialize files).

## Helper script

Use the local helper script to list available skills or install one:

```bash
scripts/skills.sh list
scripts/skills.sh install bluebubbles-cli
scripts/skills.sh install auth
scripts/skills.sh install notifications
scripts/skills.sh install auth anmho/skills --agent codex claude-code
```

## Repository structure

- `scripts/skills.sh`
- `skills/<skill-name>/SKILL.md`
- `skills/<skill-name>/evals/evals.json` (optional quality evals per [agentskills.io](https://agentskills.io/skill-creation/evaluating-skills))

Validate a skill locally:

```bash
skills/auth/scripts/validate.sh
# or all skills that ship a validate script:
scripts/validate-all-skills.sh
```

## CI evals

Pull requests and pushes that touch `skills/**` run [agent-skills-eval](https://github.com/darkrishabh/agent-skills-eval) in GitHub Actions (`.github/workflows/skill-evals.yml`):

1. **validate** — structure checks (`scripts/validate-all-skills.sh`), no API key
2. **eval** — `with_skill` vs `without_skill` judge grading (needs repo secret `OPENAI_API_KEY`)

Configure the secret: GitHub → **anmho/skills** → Settings → Secrets → Actions → `OPENAI_API_KEY`.

Run locally (same as CI):

```bash
# DeepSeek from Vault (same as `deepseek-api-key` zsh alias):
export DEEPSEEK_API_KEY="$(deepseek-api-key)"
EVAL_PROVIDER=deepseek ./scripts/run-evals.sh

# Or let run-evals.sh read Vault when DEEPSEEK_API_KEY is unset (needs `vault` + token):
# EVAL_PROVIDER=deepseek ./scripts/run-evals.sh

# CI uses OPENAI_API_KEY from GitHub Actions secrets instead.
open agent-skills-workspace/iteration-1/report/index.html
```

`scripts/sync-skills.sh` copies canonical skills from `skills-manifest.yaml`
(usually `~/.hermes/skills/...`) into `./skills/` before each run.

### Live Hermes / BlueBubbles E2E

`scripts/run-bluebubbles-e2e.py` injects synthetic inbound webhooks into the local
Hermes gateway and grades replies. **Capture-only is the default** — outbound
iMessage is suppressed via `~/.hermes/.e2e_suppress_imessage` so tests do not
spam your owner self-DM.

```bash
# Hermes gateway must be running (see preflight output if not)
./scripts/run-bluebubbles-e2e-preflight.sh
./scripts/run-bluebubbles-e2e.py

# Mock evals + live E2E
./scripts/run-all-evals.sh
./scripts/run-all-evals.sh --e2e-only
HERMES_E2E_CASES=bb-iconfit-email ./scripts/run-bluebubbles-e2e.py
```

Requires `BLUEBUBBLES_PASSWORD` in env or `~/.hermes/.env`. Restart the gateway
after updating `~/.hermes/plugins/chat-presence` (E2E capture hook).

This repository intentionally stays lightweight and contains only skill definitions.
