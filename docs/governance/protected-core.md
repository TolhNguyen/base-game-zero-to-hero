# Protected Core

The Protected Core is the set of paths where a single bad change breaks the whole ecosystem or destroys player data. No agent edits these paths without the Human Owner's explicit prior approval.

## Protected paths

```text
PROTECTED CORE PATHS
- CONSTITUTION.md
- docs/governance/
- game/core/            (Phase 2+)
- tools/check*          (Phase 2+; the validator entry point and its scripts)
- game/core/save/       save schema and migration rules (called out explicitly)
- docs/architecture/adr/  (existing ADRs are immutable; adding new ones is Normal)
```

## Why each path is protected

- `CONSTITUTION.md` — the highest law; silent edits corrupt every downstream rule.
- `docs/governance/` — defines who may change what; if this is editable freely, governance is meaningless.
- `game/core/` — every module depends on it; a breaking change here breaks everything (P8).
- `tools/check*` — the enforcement mechanism itself; a "police" that anyone can rewrite enforces nothing.
- `game/core/save/` — mistakes here destroy player save data permanently (P3).
- `docs/architecture/adr/` — the decision record; history must be immutable (supersede, never edit).

## Core-change procedure

1. **Stop before editing.** Do not make the change first and ask later.
2. **Tell the dev** exactly what you want to change and why.
3. **Wait for explicit approval.** Silence is not approval.
4. Make the change.
5. Write an ADR in `docs/architecture/adr/` recording the decision and the approval (use `TEMPLATE.md`; next 4-digit number).
6. Commit the change and the ADR **together** in one commit.

The pre-commit hook and `tools/check` (Phase 2+) block commits that touch protected paths without a new ADR in the same commit. The ADR is the durable record that the dev approved.
