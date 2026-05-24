# anmho/skills

Custom Codex skills repository.

## Install a skill

```bash
npx skills add anmho/skills --skill <skill-name> --global -y
```

Example:

```bash
npx skills add anmho/skills --skill bluebubbles-cli --global -y
npx skills add anmho/skills --skill auth-module --global -y
```

## Helper script

Use the local helper script to list available skills or install one:

```bash
scripts/skills.sh list
scripts/skills.sh install bluebubbles-cli
scripts/skills.sh install auth-module
scripts/skills.sh install auth-module anmho/skills --agent codex claude-code
```

## Repository structure

- `scripts/skills.sh`
- `skills/<skill-name>/SKILL.md`
- `skills/<skill-name>/evals/evals.json` (optional quality evals per [agentskills.io](https://agentskills.io/skill-creation/evaluating-skills))

Validate a skill locally:

```bash
skills/auth-module/scripts/validate.sh
```

This repository intentionally stays lightweight and contains only skill definitions.
