# Skill: change-protected-core

- Status: active
- Owner: Architect
- Evidence: ADR-0003 (7e11135), ADR-0004 (b021f6a), ADR-0005 (4857679) — three real core changes through this procedure

## When to use

Any edit under: `CONSTITUTION.md`, `docs/governance/`, `game/core/`, `tools/check*`, `tools/validate_*`, save schema.

## Steps

1. **STOP before editing.** No "change first, ask later".
2. Tell the dev what you want to change and why (in chat). Under the standing full-autonomy grant (2026-07-02) this becomes: state it clearly in the ADR and proceed — the dev reviews the commit log.
3. Write the ADR: next 4-digit number in `docs/architecture/adr/`, template `TEMPLATE.md`. Context (what forced it), Decision (imperative), Alternatives (each with rejection reason), Consequences (+ when to revisit).
4. Make the change. Keep it additive where possible; save-schema changes also need a migration + fixture test (see save-system domain doc).
5. Commit change + ADR **together** — the pre-commit hook rejects protected-path commits without a new ADR in the same commit.
6. Full `tools/check` PASS quoted as evidence.

## Gotchas

- ADRs are immutable: the hook rejects edits (except the `- Status:` line) and deletions. To reverse a decision, write a superseding ADR.
- The hook checks STAGED files — stage the ADR before committing, not after.
- `ALLOW_CORE=1` exists for the human dev only. An agent using it is a governance violation, full stop.
