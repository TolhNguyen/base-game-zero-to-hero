# Change Rules

Exactly two levels of change exist. There is no approval matrix and no third level.

| Level | Scope | Process |
|---|---|---|
| **Normal** | `game/modules/`, `game/demo/`, `game/content/`, domain docs (`docs/memory/`), skills, workflows, README | Agent works → runs `tools/check` (Phase 2+) → commits to `main` with the standard message (task ID + evidence) → dev reviews the commit log. No pre-approval. |
| **Core** | The paths in `protected-core.md`: `game/core/`, `CONSTITUTION.md`, `docs/governance/`, `tools/check` itself, save schema | Agent **stops, warns the dev, explains, waits for explicit approval**, then changes and records an ADR. |

## Commit message format

```text
type(scope): summary

Task: TASK-YYYY-MM-DD-NNN
Evidence: <verification result>
```

Types: `feat | fix | docs | chore | refactor | test`. Example:

```text
docs(inventory): add stacking rules to domain doc

Task: TASK-2026-07-02-003
Evidence: tools/check PASS (all suites); manual review of doc links
```

## Evidence rules

- Every Normal commit body names its task ID (or `ad-hoc` for human commits) and its verification evidence.
- From Phase 2 onward, evidence is a `tools/check` output summary. Until then, evidence is the exact commands run and their results.
- "Evidence: none" is not valid. If nothing was verifiable, the task was mis-scoped — escalate.

## Rollback

- One task = one commit. Rollback = `git revert <sha>`.
- Agents must **never** rewrite published history on `main` (no force-push, no rebase of pushed commits, no amend of published commits).

## Never, regardless of level

- Force-push `main`.
- Delete or edit an existing ADR (write a superseding ADR instead).
- Commit secrets, tokens, or credentials.
- Add third-party dependencies, Godot plugins, or editor addons without dev approval.
