# Project Memory

Long-lived knowledge that code cannot express. Two kinds:

- **`domains/`** — one file per game system (intent, invariants, gotchas). Owned by Architect + Director.
- **`failures/`** — post-mortems. Owned by QA. See `failures/TEMPLATE.md`.

## Freshness rule

Every domain doc starts with a `Last verified: YYYY-MM-DD` line. A doc older than the code it describes is a bug (Constitution P5) — fix it or delete it.

## What does NOT belong here

Conversation transcripts, session logs, restatements of code, or anything git history already records.
