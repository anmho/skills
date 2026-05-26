---
name: tab-organizer-cleanup
description: Clean up Andrew's Chrome tabs using the local tab-organizer CLI. Use when asked to clean up tabs, organize tabs, delete inactive/duplicate/junk/done browser tabs, list tab cleanup groups, or undo a tab cleanup.
---

# Tab Organizer Cleanup

Use the linked `tab-organizer` CLI from `/Users/andrewho/repos/projects/tab-organizer` as the source of truth for tab inventory and cleanup. Do not bypass it with raw AppleScript, Computer Use, or direct Chrome DevTools calls during normal cleanup; if the CLI result looks wrong, fix the CLI and rerun it.

## Workflow

1. Check that the command is installed:

```bash
which tab-organizer
tab-organizer --help
```

2. Inspect cleanup candidates:

```bash
tab-organizer list --group cleanup --json
```

3. Delete cleanup-safe groups through the CLI:

```bash
tab-organizer delete --group duplicates --json
tab-organizer delete --group junk --json
tab-organizer delete --group done --json
```

For broad "clean up my tabs" requests, use the explicit inactive cleanup group:

```bash
tab-organizer delete --group inactive --json
```

This keeps the active tab in each Chrome window and closes non-active tabs.

4. Verify final state:

```bash
tab-organizer list --group cleanup --json
```

5. Restore the last deleted batch if needed:

```bash
tab-organizer undo --json
```

## Policy

- Believe `tab-organizer` output. If it reports no tabs or unexpected candidates, report that and fix the CLI instead of using a hidden fallback path.
- Do not publish the package; local `bun link` is the expected install path.
- Do not delete arbitrary IDs unless the user explicitly asks for specific tabs. Prefer cleanup groups.
- Normal cleanup must not steal focus from the user's active browser window.
- Include the workspace path `/Users/andrewho/repos/projects/tab-organizer` in status or final messages.
