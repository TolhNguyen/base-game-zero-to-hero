# ADR-0007: Core lifecycle hardening (spawn, scan, pause)

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner (chat 2026-07-02, "làm đi" on the external-review triage)

## Context

External code review (2026-07-02) found three state-lifecycle defects in
Ring-1 services: a failed scene switch leaves `_pending_spawn` set (the next
scene consumes a stale spawn point); `Registry.scan()` clears the index before
scanning (a failed scan leaves a half-loaded registry); the pause menu forces
`paused = false` on close and leaves the tree stuck paused if freed while open
(clobbering pauses owned by cutscenes/modals).

## Decision

- `SceneFlow.goto_scene()` resets `_pending_spawn` when the switch fails.
- `Registry.scan()` builds a fresh index and swaps it in only on success;
  failure leaves the previous index untouched.
- `PauseMenu` records the tree's pause state on `open()`, restores it on
  `close()`, and restores it from `_exit_tree()` when freed while open.

## Alternatives considered

- Reference-counted pause ownership service — YAGNI (P6) with one pause
  source in the base; revisit when a real game stacks pausing systems.
- Registry rollback via copy-on-error — building into a temp dictionary is
  the same guarantee without the copy.

## Consequences

Easier: failed transitions and scans are side-effect-free; pause state
composes with other pausing systems. Harder: nothing measurable. Revisit
when: multiple systems need coordinated pause ownership.
