# ADR-0006: Atomic save writes with one-generation backup

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner (chat 2026-07-02, "làm đi" on the external-review triage)

## Context

External code review (2026-07-02) confirmed `save_game()` wrote directly to
`slot_N.json`. A crash or power loss mid-write truncates the file and destroys
the player's save permanently — a direct P3 violation, and the highest-priority
finding of the review.

## Decision

`save_game()` writes the document to `slot_N.json.tmp`, moves any existing
save to `slot_N.json.bak` (replacing the previous backup), then renames the
temp file into place. `load_game()` falls back to the `.bak` file when the
main file is corrupt (parse failure), with a warning. `delete_slot()` removes
`.bak`/`.tmp` alongside the slot. `list_slots()` is unaffected (suffixes don't
match `*.json`).

## Alternatives considered

- Write-then-fsync without backup — rename gives the same crash window
  guarantee more simply, and the backup additionally survives a corrupting
  *successful* write (bad data, not bad I/O).
- N-generation rotating backups — YAGNI (P6); one generation covers the
  crash-mid-write class. Revisit if a real game needs save archaeology.

## Consequences

Easier: saves survive crashes at any point; corrupt saves self-heal from
backup. Harder: saves briefly occupy 2x disk; `.bak` is one generation only —
two consecutive corrupting writes still lose data. Revisit when: a real game
ships cloud saves or needs rotation.
