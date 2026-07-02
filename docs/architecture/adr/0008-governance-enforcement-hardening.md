# ADR-0008: Close enforcement gaps in validators and boot smoke

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner (chat 2026-07-02, "làm đi" on the external-review triage)

## Context

External code review (2026-07-02) found the existing rules were not fully
machine-enforced (adversarially verified before this change):

1. Boot smoke grepped only *negative* markers and ignored the exit code — a
   failed content scan printed `ERROR: boot: content scan failed`, matched
   nothing, and `tools/check` passed.
2. `validate_deps` only matched `res://` strings — a module referencing
   another module's `class_name` (e.g. `var x: Inventory` in dialogue)
   passed clean.
3. `.githooks/` and `tools/install_hooks.sh` were not protected paths — the
   enforcement mechanism itself was freely editable.
4. Committed task contracts were documented as immutable execution records
   but nothing enforced it.

## Decision

- `tools/check.sh` boot smoke now fails on nonzero exit and requires the
  positive markers `boot: ok` and (when `game/content` exists)
  `boot: content scanned`.
- `validate_deps.sh` additionally flags cross-ring `class_name` references:
  module classes used by core or by sibling modules, demo classes used by
  core or modules. Comment-only lines are ignored.
- `validate_protected.sh` protects `.githooks/*` and
  `tools/install_hooks.sh`, and blocks modify/rename/delete of
  `docs/contracts/TASK-*` files.
- `protected-core.md` and `AGENTS.md` path lists updated to match.

## Alternatives considered

- commit-msg format hook and ADR content linting — deferred; lower value
  than the four gaps above, revisit as follow-up.
- Server-side enforcement (CI) — the project is local-only by design
  (Constitution); hooks guard against mistakes, not malice.

## Consequences

Easier: the review's false-pass and false-negative classes are caught
mechanically; enforcement scripts can no longer be silently edited. Harder:
word-match class detection can false-positive on identifier collisions —
acceptable, it errs toward review. Revisit when: modules reach ~20+ and need
a generated event/manifest catalog (review's Sprint-2 suggestion).
