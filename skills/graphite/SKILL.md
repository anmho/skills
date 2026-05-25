---
name: graphite
description: >-
  Manage Graphite stacked branches and pull requests with the `gt` CLI. Use
  when creating, restacking, submitting, syncing, or inspecting stacked PRs;
  when choosing between Graphite and GitHub PR backends; or when working with
  Graphite Inbox/review flows.
---

# Graphite

Use Graphite when a repo wants stacked branches/PRs instead of independent
GitHub branches. Prefer the local `gt` CLI for stack operations.

## Verify availability

```bash
command -v gt
gt --version
gt status
```

If `gt status` says the repo is not initialized, do not guess stack state.
Initialize only when the user asks:

```bash
gt init
```

## Stack workflow

Before changing branches:

```bash
git status --short --branch
gt log
```

Typical flow:

```bash
gt sync
gt create -m "type: concise subject"
# edit files
git add <files>
git commit -m "type: concise subject"
gt submit --stack
```

When editing an existing stack branch:

```bash
git status --short --branch
gt log
# edit files
git add <files>
gt modify -m "type: concise subject"
gt restack
gt submit --stack
```

After submitting, verify the GitHub PR shape:

```bash
gh pr view --json number,url,headRefName,baseRefName,state,isDraft
```

## Rules

- Keep one logical change per stack branch.
- Use conventional commit subjects unless the repo explicitly says otherwise.
- Never silently change a PR base; verify and report the final base/head.
- If Graphite auth, initialization, or submit fails, report the exact blocker
  instead of falling back to a wrong-base PR.
- Prefer `gt submit --stack` for stacked PR publication; use direct `gh pr`
  only when the repo is not using Graphite or the user asks for GitHub-only.

## Symphony integration guidance

For Symphony PR handoff work, Graphite should be an optional backend:

1. Detect `gt` with `command -v gt`.
2. Confirm repo initialization with `gt status` or `gt log`.
3. Use `gt submit --stack` when configured for Graphite.
4. Verify PR base/head with `gh pr view`.
5. Comment a clear blocker in Linear if Graphite cannot submit the stack.

Recommended config shape:

```yaml
pr:
  backend: graphite # graphite | github
  submit_stack: true
```
