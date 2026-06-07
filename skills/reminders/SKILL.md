---
name: reminders
description: >-
  Use when the user asks Hermes to create, inspect, update, complete, or keep
  track of dated reminders, follow-ups, todos, errands, chores, and life-admin
  tasks. Back reminders/tasks with Google Tasks through the local `gws` CLI via
  terminal. Do not use for durable conversational memory or preferences such as
  "remember this preference" unless the user asks for a dated reminder/task.
---

# Reminders

Hermes uses this skill to create, inspect, update, and complete reminders and tasks. The selected backend is **Google Tasks through the local `gws` CLI** via terminal.

## Activation triggers

Load this skill when the user asks to:

- Create a dated reminder: "Remind me tomorrow to call Mom."
- Create an undated task: "Add a task to renew my passport."
- List reminders/tasks: "What reminders do I have today?"
- Update a reminder/task: "Move the passport renewal task to Friday."
- Complete a reminder/task: "Mark the grocery reminder done."
- Create follow-ups or life-admin todos: "Remind me to follow up with Sam next week."

Do **not** load this skill for durable memory/preferences:

- "Remember this preference: I like concise answers."
- "Remember that my deploy window is after 5pm."

For those, route to the memory/preference system instead of creating a task.

## First steps

1. `command -v gws` — if missing, say Google Tasks access needs the local `gws` CLI.
2. `gws auth status` — confirm auth before reading or mutating tasks.
3. Inspect the available Tasks command surface when needed:
   - `gws --help`
   - `gws tasks --help`
   - `gws schema tasks.<resource>.<method>`
4. Use `gws tasks ... --format json` through terminal for reads and writes.

Prefer deterministic task IDs from list/get results before updating or completing a task. Do not guess an ID from the title alone when multiple tasks match.

## Behavior

- **Dated reminder:** create a Google Task with the parsed due date. Resolve relative dates such as "today", "tomorrow", and weekdays in the user's timezone, and include the concrete date in the confirmation.
- **Undated task:** create a Google Task without a due date when the user says "task" or "todo" and does not request a notification or deadline.
- **Missing reminder date:** if the user asks to "remind me" without enough time/date context, ask one concise clarification question before creating anything.
- **Listing:** honor date filters such as today, tomorrow, this week, overdue, and completed/open when available.
- **Completion:** find the matching open task, disambiguate if there are multiple plausible matches, then mark it completed.
- **Updates:** find the matching task first, then update the requested fields such as title, notes, due date, or status.
- **Notifications:** Google Tasks due dates are the source of truth. The Google Tasks API stores only the date portion of `due` and does not create device notifications directly. If the user gives a time, put the human time in `notes`, confirm the date, and do not promise a push notification unless a separate notification backend is explicitly used.
- **Recurrence:** Google Tasks API support for recurrence is limited. If `gws tasks` exposes recurrence fields, use them. Otherwise, explain that recurring reminders are not supported by this backend and offer the nearest single due date or a set of explicit one-off tasks.

## Operations

Create:

1. Determine whether the request is a dated reminder or an undated task.
2. Resolve or clarify the due date.
3. List task lists when the destination list is unknown, then insert a Google Task with a short action-oriented title.
4. Put extra context, explicit time, recurrence limitation, or source text in notes when needed.
5. Confirm with title, date if present, and task list.

List or inspect:

1. List task lists if the target list is unknown.
2. List active tasks with completed/deleted tasks excluded unless requested.
3. For "today", use date bounds when supported; otherwise filter the returned JSON by due date.
4. Return concise titles and due dates.

Update or reschedule:

1. Find the task by exact or high-confidence title match.
2. If multiple tasks match, ask one concise clarification question.
3. Patch only the requested fields such as title, notes, due, or status.

Complete:

1. Find the target task by title or context.
2. Patch status to completed.
3. Confirm completion without deleting the task.

## Command patterns

Discover exact method names and parameter shapes with `gws tasks --help` and `gws schema tasks.<resource>.<method>` because the local CLI may expose Google Tasks resources directly.

Typical flow:

1. List task lists:
   - `gws tasks tasklists list --params '{}' --format json`
2. Create a task:
   - `gws tasks tasks insert --params '{"tasklist":"<TASKLIST_ID>","requestBody":{"title":"Call Mom","due":"2026-06-06T00:00:00.000Z"}}' --format json`
3. List tasks:
   - `gws tasks tasks list --params '{"tasklist":"<TASKLIST_ID>","showCompleted":false,"showDeleted":false}' --format json`
4. Update a task:
   - `gws tasks tasks patch --params '{"tasklist":"<TASKLIST_ID>","task":"<TASK_ID>","requestBody":{"due":"2026-06-12T00:00:00.000Z"}}' --format json`
5. Complete a task:
   - `gws tasks tasks patch --params '{"tasklist":"<TASKLIST_ID>","task":"<TASK_ID>","requestBody":{"status":"completed"}}' --format json`

If the CLI uses a different command spelling, adapt to the discovered schema and keep the same API intent: list task lists, insert tasks, list/filter tasks, patch fields, and patch status to `completed`.

## Ambiguity rules

- Ask one short question when required date/time context is missing for a reminder.
- Ask one short question when multiple existing reminders/tasks match a complete or update request.
- Do not ask for a due date for a plain undated task unless the user implies a deadline or notification.
- Do not convert memory/preferences into tasks unless the user explicitly adds a reminder date/time or todo intent.
- Do not create duplicate tasks if an active task with the same title and due date already exists; report the existing task instead.
- If `gws` discovery, auth, or network access fails, report the exact blocker and do not pretend the reminder was created.
- Never print OAuth tokens or raw credential material from `gws`.

## Output style

Keep responses small. After a successful write, confirm the task title and due date/status in one sentence.
