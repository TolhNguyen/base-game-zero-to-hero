# ADR-0003: Mechanical governance enforcement via git hooks

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner (full-autonomy grant, chat 2026-07-02)

## Context

The Constitution's Protected Core rules (P8 dependencies, core-change-needs-ADR) were documents only; nothing stopped a session from silently violating them. Phase 2 plan Task 13 mandates mechanical enforcement.

## Decision

Add `tools/validate_deps.sh` (P8 one-way dependency check) and `tools/validate_protected.sh` (staged protected-path changes require a new ADR; ADRs immutable except Status line, never deletable). Both run in `tools/check.sh` and in a `.githooks/pre-commit` hook activated by `tools/install_hooks.sh` (per-clone, one time). Human-only escape hatch: `ALLOW_CORE=1`.

## Alternatives considered

- Server-side hooks / CI enforcement — rejected: no server, local-only by owner decision.
- Trusting agent discipline — rejected: Constitution P4, verifiable over plausible.
- Full test run in pre-commit — rejected: too slow per commit; `tools/check.sh` remains the evidence command.

## Consequences

Easier: silent core edits become mechanically impossible on hooked clones. Harder: every fresh clone must run `tools/install_hooks.sh` (documented in README). The validators themselves are protected paths; changing them requires a new ADR.
