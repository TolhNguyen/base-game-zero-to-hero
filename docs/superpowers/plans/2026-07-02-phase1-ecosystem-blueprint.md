# Phase 1 — Ecosystem Blueprint Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce the complete agent-facing operating documentation (Constitution, AGENTS.md, role profiles, governance rules, templates) so a fresh agent session on any CLI can correctly state its role, permissions, and verification duties.

**Architecture:** Documentation-only phase. All artifacts are Markdown files in the repo root and `docs/`. No game code. Verification is (a) mechanical checks (word caps, link resolution) and (b) a live onboarding test with a fresh context-free subagent.

**Tech Stack:** Markdown, git. Source spec: `docs/superpowers/specs/2026-07-02-ai-native-godot-base-ecosystem-design.md`.

## Global Constraints

- All agent-facing docs are 100% English (owner decision 2026-07-02).
- Hard cap: total word count of `CONSTITUTION.md` + `AGENTS.md` + `docs/agents/` + `docs/governance/` + `docs/architecture/overview.md` must be **< 9,000 words** (≈ the "< 20 pages" gate in the spec).
- Governance has exactly **2 levels**: Normal and Core. No approval matrix, no extra levels.
- Human-first: docs must describe a standard Godot project a human dev can work in without reading agent docs.
- Commits go directly to `main`, one commit per task, message format: `type(scope): summary` + body listing evidence. Types: `feat|fix|docs|chore|refactor|test`.
- Nothing in this phase may contradict the spec's "Non-negotiable principles" (spec §2). When in doubt, the spec wins.
- Note for executors: `tools/check` does not exist yet (built in Phase 2). Docs must reference it as the verification command, with the note "(from Phase 2 onward)".

---

### Task 1: Directory scaffolding + root README

**Files:**
- Create: `docs/agents/.gitkeep`, `docs/governance/.gitkeep`, `docs/architecture/adr/.gitkeep`, `docs/memory/domains/.gitkeep`, `docs/memory/failures/.gitkeep`, `docs/skills/.gitkeep`, `docs/workflows/.gitkeep`
- Modify: `README.md` (currently a one-line stub)

**Interfaces:**
- Produces: the directory layout every later task writes into; README section "Repository map" that later docs may link to.

- [ ] **Step 1: Create directories**

```bash
mkdir -p docs/agents docs/governance docs/architecture/adr docs/memory/domains docs/memory/failures docs/skills docs/workflows
touch docs/agents/.gitkeep docs/governance/.gitkeep docs/architecture/adr/.gitkeep docs/memory/domains/.gitkeep docs/memory/failures/.gitkeep docs/skills/.gitkeep docs/workflows/.gitkeep
```

- [ ] **Step 2: Rewrite README.md**

Content requirements (write in full, ~1 page):
- Title: `base-game-zero-to-hero`.
- One-paragraph pitch: a genre-agnostic base codebase for Godot 4.x 2.5D games, co-developed by humans and AI agents; not a game itself.
- "For humans" section: open in Godot 4.x, press F5 (note: playable from Phase 3), standard Godot project, no agent tooling required to contribute.
- "For AI agents" section: single line — "Read `AGENTS.md` first. It is the entry point for every agent session."
- "Repository map" section: table of top-level paths (`game/` — Godot project (Phase 2+), `docs/` — constitution/governance/architecture/memory, `tools/` — local validators (Phase 2+), `AGENTS.md` — agent entry point).
- "Status" section: phase table with current phase marked (Phase 1 in progress).

- [ ] **Step 3: Verify**

Run: `ls docs/agents docs/governance docs/architecture/adr docs/memory/domains docs/memory/failures docs/skills docs/workflows`
Expected: all directories exist, no error.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(repo): scaffold docs directory layout and rewrite README"
```

---

### Task 2: CONSTITUTION.md

**Files:**
- Create: `CONSTITUTION.md`

**Interfaces:**
- Produces: the 8 principles (P1–P8) and the 2 governance levels that every other doc cites by name. Later docs must use the exact principle names below.

- [ ] **Step 1: Write CONSTITUTION.md**

Hard cap: 1,200 words. Required structure and content:

1. **Preamble** (3–4 sentences): purpose of the repo (genre-agnostic Godot 4.x 2.5D base + AI-agent operating system); this document is the highest law; it changes only via the Core-change process with owner approval.
2. **Roles**: Human Owner (final authority, approves Core changes, reviews commits on main); Super Agent (created the ecosystem; recalled only per §5); High/Mid-level agent sessions (design, plan, create task contracts, summon executors); Executor sessions (work one task contract at a time).
3. **Principles** — exactly these eight, with these exact names (one short paragraph each, adapted verbatim from spec §2):
   - P1 Human-First Codebase
   - P2 Genre-Agnostic Core
   - P3 Fail Small
   - P4 Verifiable Over Plausible
   - P5 Docs Versioned With Code
   - P6 No Over-Engineering (failure-driven governance)
   - P7 Stable IDs, Not Asset Paths
   - P8 One-Way Dependencies (`demo → modules → core`)
4. **Governance** (summary; details live in `docs/governance/change-rules.md`): two levels only. Normal — change, verify, commit to main, dev reviews commit log. Core — stop, warn the dev, explain, wait for approval, then change + ADR.
5. **Super Agent recall criteria**: changing this Constitution, changing the Protected Core boundary itself, changing the agent/permission model, replacing the engine, or an ecosystem-level incident agents cannot resolve.

- [ ] **Step 2: Verify word cap**

```bash
wc -w CONSTITUTION.md
```
Expected: < 1200.

- [ ] **Step 3: Commit**

```bash
git add CONSTITUTION.md
git commit -m "docs(governance): add project constitution"
```

---

### Task 3: Governance docs

**Files:**
- Create: `docs/governance/protected-core.md`
- Create: `docs/governance/change-rules.md`
- Create: `docs/governance/task-contract-template.md`

**Interfaces:**
- Consumes: principle names P1–P8 from Task 2.
- Produces: the exact Protected Core path list, the commit message format, and the task-contract YAML schema used by all later phases.

- [ ] **Step 1: Write protected-core.md**

Must contain this exact path list (verbatim — this list is what Phase 2 validators will read):

```text
PROTECTED CORE PATHS
- CONSTITUTION.md
- docs/governance/
- game/core/            (Phase 2+)
- tools/check*          (Phase 2+; the validator entry point and its scripts)
- game/core/save/       save schema and migration rules (called out explicitly)
- docs/architecture/adr/  (existing ADRs are immutable; adding new ones is Normal)
```

Plus: rationale (one line per path), and the Core-change procedure as a numbered list: (1) stop before editing; (2) tell the dev what and why; (3) wait for explicit approval; (4) make the change; (5) write an ADR recording the approval; (6) commit change + ADR together.

- [ ] **Step 2: Write change-rules.md**

Required content:
- The two-level table exactly as in spec §5 (Normal / Core: scope and process columns).
- Commit message format with a full example:

```text
docs(inventory): add stacking rules to domain doc

Task: TASK-2026-07-02-003
Evidence: tools/check PASS (all suites); manual review of doc links
```

- Evidence rules: every Normal commit body names its task ID (or `ad-hoc` for human commits) and its verification evidence. From Phase 2 onward, evidence = `tools/check` output summary.
- Rollback rule: one task = one commit; rollback = `git revert <sha>`; agents must never rewrite published history on `main`.
- What agents must NEVER do regardless of level: force-push `main`, delete ADRs, edit an existing ADR (supersede instead), commit secrets, add third-party dependencies/plugins without dev approval.

- [ ] **Step 3: Write task-contract-template.md**

Must contain this exact template (verbatim):

```yaml
# Task Contract — copy this file, fill every field. Executors: refuse tasks with empty fields.
task_id: TASK-YYYY-MM-DD-NNN
objective: >
  One sentence. What exists after this task that did not before.
context: >
  Why this task exists; links to spec/ADR/domain doc the executor must read.
inputs:
  - # files, data, or decisions the executor starts from
expected_outputs:
  - # exact files created/modified and observable behavior
allowed_paths:
  - # globs the executor may modify; anything else is forbidden
forbidden_actions:
  - editing files outside allowed_paths
  - changing public signatures of game/core/ (Core-level; escalate)
  - adding dependencies or plugins
expected_outputs_verification: >
  Exact commands to run and their expected results (tools/check from Phase 2 onward).
acceptance_criteria:
  - # checkable statements; each must be verifiable by command or inspection
required_evidence:
  - # command outputs / screenshots to paste into the task report
iteration_limit: 3   # attempts before mandatory escalation
escalation_conditions:
  - acceptance criteria unreachable within iteration_limit
  - task requires touching paths outside allowed_paths
  - task requires a Core-level change
report_format: >
  Reply with: status (done/blocked), what changed, evidence, deviations, follow-ups.
```

Plus one filled-in example contract (use a realistic Phase 3 example: "add stack size limit to inventory module", allowed_paths `game/modules/inventory/**`, `game/tests/inventory/**`).

- [ ] **Step 4: Verify internal consistency**

Check: path list in protected-core.md matches the Core row scope in change-rules.md; template field names match those referenced in change-rules.md evidence rules. Fix mismatches now.

- [ ] **Step 5: Commit**

```bash
git add docs/governance/
git commit -m "docs(governance): add protected core, change rules, task contract template"
```

---

### Task 4: Role profiles

**Files:**
- Create: `docs/agents/director.md`, `docs/agents/architect.md`, `docs/agents/producer.md`, `docs/agents/qa.md`

**Interfaces:**
- Consumes: governance vocabulary from Task 3 (task contract, Normal/Core, evidence).
- Produces: the four role names (Director, Architect, Producer, QA/Verifier) that AGENTS.md (Task 5) links to.

- [ ] **Step 1: Write the four profiles**

Each file follows this identical skeleton (≤ 500 words each), fully filled per role:

```markdown
# Role: <Name>
## Mission        (1-2 sentences)
## You decide     (decision authority — bullet list)
## You must not   (prohibited actions — bullet list)
## Context to load  (ordered reading list for a session wearing this hat)
## Inputs / Outputs (what you receive, what artifacts you produce)
## Escalation     (when to stop and ask the dev)
```

Role content requirements:
- **Director** (`director.md`): decides demo scope, UX intent, art direction, content priorities; produces short specs (≤ 1 page) in `docs/memory/domains/` or feature briefs; must not write game code or task contracts; loads CONSTITUTION → architecture/overview → current milestone.
- **Architect** (`architect.md`): decides module boundaries, public interfaces, core design; reviews architecture compliance of Normal changes when asked; produces technical notes and ADR drafts; must not approve Core changes (only the dev can) nor bypass `tools/check`; loads CONSTITUTION → architecture/overview → relevant ADRs → relevant domain docs.
- **Producer** (`producer.md`): decides task breakdown and ordering; produces task contracts from specs (using the Task 3 template) and tracks status in the milestone doc; must not change scope of a spec on its own nor execute its own contracts in the same session; loads CONSTITUTION → governance docs → the spec being planned.
- **QA/Verifier** (`qa.md`): decides whether acceptance criteria are met; produces verification reports and failure entries in `docs/memory/failures/`; must not fix code beyond trivial test harness issues (report instead); loads CONSTITUTION → change-rules → the task contract under review.

- [ ] **Step 2: Verify**

```bash
wc -w docs/agents/*.md
```
Expected: each file < 500 words; all four skeleton headings present in each file.

- [ ] **Step 3: Commit**

```bash
git add docs/agents/
git commit -m "docs(agents): add four role profiles"
```

---

### Task 5: AGENTS.md entry point + CLI pointers

**Files:**
- Create: `AGENTS.md`
- Create: `CLAUDE.md`
- Create: `GEMINI.md`

**Interfaces:**
- Consumes: everything from Tasks 2–4 (links to them).
- Produces: the single onboarding entry point tested in Task 7.

- [ ] **Step 1: Write AGENTS.md**

Hard cap: 900 words. This is the most-read doc in the repo; optimize for a cold-start session. Required sections:

1. **What this repo is** (2 sentences) + "You are an AI agent session. This file tells you how to work here."
2. **Read in this order** (numbered): 1. `CONSTITUTION.md` (always) 2. your role profile in `docs/agents/` (the human tells you your hat; if none given, you are an Executor) 3. `docs/governance/change-rules.md` 4. only the domain docs your task needs — do not read the whole repo.
3. **The two rules that matter most**: (a) Never touch Protected Core paths (list them inline, copied from Task 3) without stopping and asking the dev first. (b) Never claim work is done without evidence (`tools/check` from Phase 2 onward; until then, the exact commands in your task).
4. **How work flows**: human summons Director/Architect/Producer session → Producer writes task contracts (`docs/governance/task-contract-template.md`) → Executor sessions implement one contract each → QA verifies → commit to `main` with the standard message format → dev reviews commit log.
5. **If you are an Executor**: work only inside `allowed_paths`; obey `iteration_limit`; escalate per contract; report in `report_format`.
6. **When things fail**: record post-mortems in `docs/memory/failures/` (template there); a failure entry is closed only by a system action (new rule/test/skill fix).
7. **Language**: repo docs are English; converse with the owner in Vietnamese if the owner writes Vietnamese.

- [ ] **Step 2: Write CLAUDE.md and GEMINI.md**

Both files, exact content (identical apart from nothing — they are pure pointers):

```markdown
# Agent entry point

Read `AGENTS.md` first. It is the single source of truth for how agent
sessions work in this repository. Do not duplicate rules here.
```

- [ ] **Step 3: Verify links and cap**

```bash
wc -w AGENTS.md
```
Expected: < 900. Manually confirm every relative link in AGENTS.md resolves to a file created in Tasks 1–4.

- [ ] **Step 4: Commit**

```bash
git add AGENTS.md CLAUDE.md GEMINI.md
git commit -m "docs(agents): add AGENTS.md entry point and CLI pointer files"
```

---

### Task 6: Architecture overview + ADR system

**Files:**
- Create: `docs/architecture/overview.md`
- Create: `docs/architecture/adr/TEMPLATE.md`
- Create: `docs/architecture/adr/0001-ecosystem-architecture.md`

**Interfaces:**
- Consumes: spec §3 (three rings), P7/P8 from Task 2.
- Produces: ADR numbering convention (4-digit, immutable, superseded-not-edited) used by all future Core changes.

- [ ] **Step 1: Write overview.md**

Hard cap: 800 words. Required content: the three-rings diagram (copy the `game/` tree from spec §3 verbatim); the one-way dependency rule with the exact line `demo → modules → core` and the two corollaries (modules never import modules; core never imports anything above it); stable-ID rule with one concrete example (`item.healing_potion` referenced from a quest condition — renaming the asset file breaks nothing); save-versioning rule (every save file carries `schema_version`; loaders migrate forward, never backward); note that `game/` does not exist yet (Phase 2) and this doc is the contract it will be built against.

- [ ] **Step 2: Write adr/TEMPLATE.md**

Exact content:

```markdown
# ADR-NNNN: <Title>

- Date: YYYY-MM-DD
- Status: Accepted | Superseded by ADR-NNNN
- Approved by: <dev name> (required for Core-level changes)

## Context
<What forced a decision — 2-5 sentences.>

## Decision
<What we chose — 1-3 sentences, imperative.>

## Alternatives considered
<Bullet list, one line each, with the reason rejected.>

## Consequences
<What becomes easier, what becomes harder, what must be revisited when.>
```

Plus a header note in the file: ADRs are immutable once committed; to change a decision, write a new ADR that supersedes the old one and update the old ADR's Status line only.

- [ ] **Step 3: Write adr/0001-ecosystem-architecture.md**

Using the template. Context: greenfield repo, owner approved the ecosystem design 2026-07-02. Decision: adopt the design in `docs/superpowers/specs/2026-07-02-ai-native-godot-base-ecosystem-design.md` (three-ring architecture, 4 roles, 2-level governance, local-only verification, GDScript). Alternatives: list the rejected options from spec §11, one line each. Consequences: base is reusable per-game; governance may thicken only via failure entries; Phase 2 must build `tools/check` before any module code. Approved by: owner (chat, 2026-07-02).

- [ ] **Step 4: Commit**

```bash
git add docs/architecture/
git commit -m "docs(architecture): add overview, ADR template, and ADR-0001"
```

---

### Task 7: Memory, skills, workflows scaffolding

**Files:**
- Create: `docs/memory/README.md`, `docs/memory/failures/TEMPLATE.md`, `docs/memory/domains/README.md`
- Create: `docs/skills/README.md`
- Create: `docs/workflows/README.md`
- Delete: the `.gitkeep` files in these directories (now non-empty)

**Interfaces:**
- Consumes: failure-loop description from Task 5 §6.
- Produces: the failure template QA (Task 4) writes into; skill lifecycle states.

- [ ] **Step 1: Write memory/README.md**

Content: memory layout (domains/ = one file per game system, owned by Architect+Director; failures/ = post-mortems, owned by QA); freshness rule: every domain doc starts with a `Last verified: YYYY-MM-DD` line; a doc older than the code it describes is a bug — fix it or delete it. Do not store conversation transcripts here.

- [ ] **Step 2: Write failures/TEMPLATE.md**

Exact content:

```markdown
# FAIL-YYYY-MM-DD-NN: <symptom, one line>

- Status: Open | Closed
- Detected by: <tools/check | human | agent session>

## Symptom
## Root cause
## How it was detected (and why not earlier)
## System action  ← required to close: new rule / new test / skill fix (link the commit)
```

- [ ] **Step 3: Write domains/README.md**

Content: one file per system (`save-system.md`, `inventory.md`, ...) created when the system is first built (Phase 2+); required header (`Owner role`, `Last verified`); ≤ 1 page each; contains what code cannot say — intent, invariants, gotchas — never restates code.

- [ ] **Step 4: Write skills/README.md and workflows/README.md**

skills/README.md: a skill = a repeatable how-to for agents (one markdown file); lifecycle is exactly `draft → active → deprecated` (status line in file header); a skill may be promoted to `active` only after it has been used successfully at least once with evidence linked; created by any high/mid-level role; duplicates must be merged.
workflows/README.md: a workflow = an ordered checklist with gates (human approval or command-must-pass); same lifecycle as skills; the first real workflows will be extracted from Phase 3 practice, not invented up front (P6).

- [ ] **Step 5: Commit**

```bash
git add -A docs/memory docs/skills docs/workflows
git commit -m "docs(memory): add memory, skills, workflows scaffolding and templates"
```

---

### Task 8: Fresh-agent onboarding verification (phase gate)

**Files:**
- Create: `docs/memory/failures/` entries only if the test fails
- Modify: any doc from Tasks 2–7 that the test proves unclear

**Interfaces:**
- Consumes: everything.
- Produces: the Phase 1 completion evidence, recorded in the final commit message.

- [ ] **Step 1: Run the onboarding test**

Dispatch a fresh subagent (no conversation context) with exactly this prompt:

```text
You are a new agent session in the repository at <repo path>. Read AGENTS.md
and follow its reading order. Then answer, citing file paths:
1. What is this repository and what is it NOT?
2. You are asked to change game/core/save/. What must you do before editing?
3. You finished a task. What must your commit message contain?
4. What are the two governance levels and who approves each?
5. Your task's acceptance criteria seem unreachable after 3 attempts. What now?
6. Where do you record a post-mortem and what closes it?
```

- [ ] **Step 2: Grade the answers**

Pass = all 6 answers correct with correct file citations. Expected answers: (1) genre-agnostic Godot 2.5D base codebase, not a game; (2) stop, warn dev, wait for approval, then ADR — Core level; (3) type(scope): summary + task ID + evidence; (4) Normal = dev reviews commits, Core = dev pre-approves; (5) escalate per contract's escalation_conditions; (6) `docs/memory/failures/`, closed only by a system action.

- [ ] **Step 3: Fix any doc the test exposed, re-test that question**

If any answer is wrong, the doc is at fault, not the subagent: fix the doc, re-run only the failed questions with a fresh subagent.

- [ ] **Step 4: Final word-cap check**

```bash
wc -w CONSTITUTION.md AGENTS.md docs/agents/*.md docs/governance/*.md docs/architecture/overview.md
```
Expected: total < 9,000.

- [ ] **Step 5: Commit phase completion**

```bash
git add -A
git commit -m "docs(phase1): pass fresh-agent onboarding gate

Evidence: 6/6 onboarding questions answered correctly by context-free
subagent; total blueprint word count under cap."
```

---

## Out of scope for this plan

- `game/` Godot project, `tools/check`, tests — Phase 2 (separate plan, written after this one completes, because it consumes the conventions fixed here).
- `docs/art/asset-spec.md` — Phase 4.
- Any skill or workflow content beyond the READMEs — extracted from real Phase 3 usage per P6.
