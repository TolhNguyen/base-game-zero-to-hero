# Phase 5 — Handover Implementation Plan

**Goal:** The ecosystem runs without the Super Agent: a maintainer guide for the human dev, agent entry docs finalized, and a final audit proving the handover criteria.

## Tasks

### T1 — Maintainer guide
`docs/MAINTAINER.md`: daily loop (summon role session → work → review commit log), new-machine setup, verification commands, disaster recovery (revert, hooks, engine re-download, save-data notes), starting a real game from the base, Super Agent recall criteria (link Constitution §5).

### T2 — Entry-doc touch-up
`AGENTS.md`: add pointer to registered skills/workflows (they did not exist in Phase 1). Normal-level change.

### T3 — Final audit (gate)
1. Full `tools/check` PASS.
2. Fresh context-free subagent onboarding quiz — original 6 questions + 2 new (skills lookup, art pipeline). Pass = 8/8.
3. Handover criteria sweep against spec §1 definition-of-done, recorded in the gate commit.
4. README: all phases complete; project memory updated.
