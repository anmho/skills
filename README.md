# anmho/skills

Custom Codex skills repository.

## Install a skill

```bash
npx skills add anmho/skills --skill <skill-name> --global -y
```

Example:

```bash
npx skills add anmho/skills --skill bluebubbles-cli --global -y
npx skills add anmho/skills --skill cost-investigation --global -y
npx skills add anmho/skills --skill grafana-investigation --global -y
npx skills add anmho/skills --skill infrastructure-investigation --global -y
npx skills add anmho/skills --skill auth --global -y
npx skills add anmho/skills --skill notifications --global -y
npx skills add anmho/skills --skill reminders --global -y
npx skills add anmho/skills --skill stack-debugging --global -y
npx skills add anmho/skills --skill symphony --global -y
npx skills add anmho/skills --skill tab-organizer-cleanup --global -y
```

`npx skills add` symlinks into agent skill directories by default (`--copy` to materialize files).

## Helper script

Use the local helper script to list available skills or install one:

```bash
scripts/skills.sh list
scripts/skills.sh install bluebubbles-cli
scripts/skills.sh install cost-investigation
scripts/skills.sh install grafana-investigation
scripts/skills.sh install infrastructure-investigation
scripts/skills.sh install auth
scripts/skills.sh install notifications
scripts/skills.sh install reminders
scripts/skills.sh install stack-debugging anmho/skills --agent codex claude-code
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
export OPENAI_API_KEY=sk-...
scripts/run-evals.sh
open agent-skills-workspace/iteration-1/report/index.html
```

This repository intentionally stays lightweight and contains only skill definitions.
