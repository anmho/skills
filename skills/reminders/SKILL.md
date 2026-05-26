---
name: reminders
description: >-
  Manage Hermes reminders and tasks with Google Tasks through the gws CLI. Use
  when the user asks to remind them, add or list tasks, inspect follow-ups,
  change due dates, mark reminders done, or manage life-admin to-dos. Do not
  use for durable conversational memory or preferences such as "remember this
  preference".
---

# Reminders

Use this skill when Hermes needs to create, inspect, update, or complete
reminders and tasks for the user.

## Backend

The selected backend is Google Tasks through the `gws` CLI:

```bash
gws tasks tasklists list --json
gws tasks tasks list --params '{"tasklist":"<tasklist_id>","showCompleted":false,"showDeleted":false}' --json
gws tasks tasks insert --params '{"tasklist":"<tasklist_id>","resource":{"title":"Call Mom","due":"2026-05-27T00:00:00.000Z"}}' --json
gws tasks tasks patch --params '{"tasklist":"<tasklist_id>","task":"<task_id>","resource":{"status":"completed"}}' --json
```

Before the first write in a session, inspect command shape with
`gws tasks --help` and `gws schema tasks.<resource>.<method>` when discovery is
available. Use `tasklists list` to find the default or intended task list ID.

## Routing

Treat these as reminder/task requests:

- "Remind me tomorrow to call Mom."
- "Add a task to renew my passport."
- "What reminders do I have today?"
- "Mark the grocery reminder done."
- Requests to list, inspect, rename, reschedule, update, complete, delete, or
  reopen a reminder/task.

Do not route durable memory requests here. If the user says "remember this
preference", "remember that I like...", or asks you to retain conversational
context without a task/action to track, use the durable memory flow instead.

If the user says "remind me" but omits the needed date or time context, ask one
concise clarification question before creating anything:

```text
When should I remind you?
```

If the user asks for a plain task with no due date, create an undated task.

## Dates, Times, and Notifications

- Resolve relative dates such as "today", "tomorrow", and weekdays in the
  user's timezone. Include the concrete date in the confirmation.
- Store due dates in the task `due` field as an RFC 3339 timestamp at midnight
  for the resolved date.
- Google Tasks API stores only the date portion of `due`; it does not preserve a
  due time. If the user gives a time, put the human time in `notes` and mention
  that the backend only stores the date.
- Google Tasks API does not create device notifications directly. Confirm the
  task was created with its due date, and do not promise a push notification
  unless a separate notification backend is explicitly used.
- Recurrence is not supported by this backend. For recurring reminders, explain
  the limitation and either ask whether to create the next occurrence only or
  create a clearly named non-recurring task if the user explicitly accepts that.

## Operations

Create:

1. Determine whether the request is a dated reminder or an undated task.
2. Resolve or clarify the due date.
3. Insert a Google Task with a short action-oriented `title`.
4. Put extra context, explicit time, recurrence limitation, or source text in
   `notes` when needed.
5. Confirm with title, date if present, and task list.

List or inspect:

1. List task lists if the target list is unknown.
2. List active tasks with `showCompleted:false` and `showDeleted:false`.
3. For "today", use `dueMin` and `dueMax` bounds for the user's local date when
   supported; otherwise filter the JSON client side by `due`.
4. Return concise titles and due dates. Include completed tasks only when asked.

Update or reschedule:

1. Find the task by exact or high-confidence title match.
2. If multiple tasks match, ask one concise clarification question.
3. Patch only the requested fields such as `title`, `notes`, `due`, or
   `status`.

Complete:

1. Find the target task by title or context.
2. Patch `status` to `completed`.
3. Confirm completion without deleting the task.

## Safety

- Prefer reads before writes when matching an existing task.
- Do not create duplicate tasks if an active task with the same title and due
  date already exists; report the existing task instead.
- Never print OAuth tokens or raw credential material from `gws`.
- If `gws` discovery, auth, or network access fails, report the exact blocker
  and do not pretend the reminder was created.
