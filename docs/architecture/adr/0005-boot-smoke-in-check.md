# ADR-0005: Boot-smoke step in tools/check

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner (full-autonomy grant, chat 2026-07-02)

## Context

FAIL-2026-07-02-01: a parse error in a demo autoload passed `tools/check` because nothing ever compiled scripts outside test-suite reach. The check verified tests, not the runnable game.

## Decision

`tools/check.sh` gains a final step: run the game headless (`--quit-after 30`) and fail on `SCRIPT ERROR`, `Parse Error`, or autoload instantiation failures in the output. Skipped with `--fast` (pre-commit stays instant).

## Alternatives considered

- Compile-all-scripts step — no first-class Godot CLI for it; the boot run covers autoloads and the start scene chain, which is where the class of bug lives.
- Doing nothing — rejected: P4, and this exact bug shipped once already.

## Consequences

Easier: whole-game parse/boot regressions are caught mechanically. Harder: full check is a few seconds slower. Revisit when: multiple start scenes need smoking (per-game matrix).
