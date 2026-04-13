# anmho/skills

Custom Codex skills repository.

## Install a skill

```bash
npx skills add anmho/skills --skill <skill-name> -y
```

Example:

```bash
npx skills add anmho/skills --skill bluebubbles-cli -y
```

## Helper script

Use the local helper script to list available skills or install one:

```bash
scripts/skills.sh list
scripts/skills.sh install bluebubbles-cli
```

## Repository structure

- `scripts/skills.sh`
- `skills/<skill-name>/SKILL.md`

This repository intentionally stays lightweight and contains only skill definitions.
