# Workflows

A workflow is an ordered checklist with gates — steps where either a human must approve or a command must pass before continuing.

## Lifecycle

Same as skills: `draft → active → deprecated` (a `Status:` line in the file header), promotion to `active` requires at least one successful use with evidence.

## Workflows

| Workflow | Status | Use when |
|---|---|---|
| `feature-development.md` | active | building anything new, spec → contracts → commit |
| `bug-fixing.md` | active | fixing a defect — gates against symptom patches |
| `failure-handling.md` | active | a defect escaped a check, or a check lied |
| `new-game.md` | draft | starting a real game from a game idea on this base |

Active workflows were extracted from real practice (Constitution P6);
`new-game.md` awaits its first real use for promotion.
