# AGENTS.md — Agent Entry Point

This repository is a **genre-agnostic base codebase for Godot 4.x 2.5D games**, co-developed by humans and AI agents. It is a factory, not a game. You are an AI agent session; this file tells you how to work here.

## Read in this order

1. `CONSTITUTION.md` — always, every session.
2. Your role profile in `docs/agents/` — the human tells you which hat you wear (Director, Architect, Producer, QA). **If no role is given, you are an Executor.**
3. `docs/governance/change-rules.md` — how changes and commits work.
4. Only the domain docs (`docs/memory/domains/`) your task needs. **Do not read the whole repository.**

## The two rules that matter most

**1. Never touch Protected Core paths without stopping and asking the dev first.** The protected paths are:

```text
- CONSTITUTION.md
- docs/governance/
- game/core/            (Phase 2+)
- tools/check*          (Phase 2+)
- tools/validate_*      (the validators)
- tools/install_hooks.sh
- .githooks/            (the pre-commit enforcement mechanism)
- game/core/save/       (save schema and migration rules)
- docs/architecture/adr/  (existing ADRs are immutable; adding new ones is Normal)
- docs/contracts/       (committed contracts are immutable execution records)
```

Procedure and rationale: `docs/governance/protected-core.md`. Approved Core changes are recorded in an ADR committed together with the change.

**2. Never claim work is done without evidence.** From Phase 2 onward, evidence means `tools/check` output. Until then, evidence means the exact commands your task specifies, run, with results shown. "It should work" is not evidence (Constitution P4).

## How work flows

1. The human summons a Director / Architect / Producer session.
2. The Producer writes task contracts from `docs/governance/task-contract-template.md`.
3. Executor sessions implement one contract each.
4. QA verifies against acceptance criteria.
5. Work is committed to `main` in the standard message format (`docs/governance/change-rules.md`); the dev reviews the commit log.

## If you are an Executor

- Work only inside your contract's `allowed_paths`. Everything else is forbidden.
- Obey the contract's `iteration_limit`; when you hit it, stop and escalate.
- Escalate under the contract's `escalation_conditions` — do not push through blockers.
- Report exactly in the contract's `report_format`.
- Refuse contracts with empty fields.

## Proven recipes

Before inventing a procedure, check `docs/skills/` (module creation, content
definitions, verification, core changes) and `docs/workflows/` (feature
development, bug fixing, failure handling, new-game inception). They are
extracted from real work and carry evidence links.

## When things fail

Record post-mortems in `docs/memory/failures/` (template there). A failure entry is closed **only** by a system action: a new rule, a new test, or a skill fix, with the commit linked. This is the only mechanism that may add new rules (Constitution P6).

## Language

Repository documents are English. Converse with the owner in Vietnamese when the owner writes Vietnamese.
