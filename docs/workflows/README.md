# Workflows

A workflow is an ordered checklist with gates — steps where either a human must approve or a command must pass before continuing.

## Lifecycle

Same as skills: `draft → active → deprecated` (a `Status:` line in the file header), promotion to `active` requires at least one successful use with evidence.

## Active workflows

| Workflow | Use when |
|---|---|
| `feature-development.md` | building anything new, spec → contracts → commit |
| `bug-fixing.md` | fixing a defect — gates against symptom patches |
| `failure-handling.md` | a defect escaped a check, or a check lied |

All were extracted from real practice, not invented up front (Constitution P6).
