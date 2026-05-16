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

This repository intentionally stays lightweight and contains only skill definitions.
