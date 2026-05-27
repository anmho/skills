# Hermes + iMessage bubble splitting (BlueBubbles adapter)

Observed behavior in the Hermes BlueBubbles adapter:

- Outbound text is split into paragraphs first using double-newlines (`\n\n`).
  Each paragraph becomes its own iMessage bubble.
- Then each paragraph is truncated/chunked further if it still exceeds the platform max length (~4000 chars).
- Pagination suffixes like "(1/3)" are stripped for iMessage since bubbles flow naturally.

Also related:
- Typing indicators + read receipts are attempted only when BlueBubbles private API is enabled and the helper is connected; otherwise Hermes no-ops.
