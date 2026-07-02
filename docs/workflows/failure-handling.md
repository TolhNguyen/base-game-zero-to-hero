# Workflow: failure-handling

- Status: active
- Owner: QA
- Evidence: FAIL-2026-07-02-01 → ADR-0005 → boot-smoke step (commit 4857679), first full loop

Ordered checklist; **[GATE]** steps must pass before continuing.

1. **Capture** — the moment a defect escapes past a check (or a check itself lies), create `docs/memory/failures/FAIL-YYYY-MM-DD-NN.md` from `TEMPLATE.md`, Status: Open. Facts only: symptom, detection.
2. **Root-cause** — answer "why did no mechanism catch this earlier?" — that answer, not the bug, is the real finding.
3. **System action** — [GATE] pick exactly one to start: new validator/check step, new test, new rule line, or a skill fix. A failure entry cannot close on "we'll be careful next time" (P6: this is the ONLY path by which governance may thicken).
4. **Implement** — if the action touches `tools/check*` or other protected paths, it needs an ADR (skill `change-protected-core`) — enforcement changes are core changes.
5. **Prove** — [GATE] re-create the original failure; the new mechanism must catch it mechanically.
6. **Close** — Status: Closed, link the commit. Update the relevant domain doc/skill gotchas so the lesson is findable where people work.
