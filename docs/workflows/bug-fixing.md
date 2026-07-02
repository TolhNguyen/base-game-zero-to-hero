# Workflow: bug-fixing

- Status: active
- Owner: QA
- Evidence: external-review remediation 2026-07-02 (commits f560666, 5080980,
  79ff989, 8e7274c — each fix root-caused against code first, regression
  tests written RED-first from the general property, not the bug instance)

Ordered checklist; **[GATE]** steps must pass before continuing. Rationale:
an agent left alone optimizes for "make the failing case pass" — these gates
make the symptom patch fail verification instead of relying on judgment.

1. **Reproduce** — trigger the defect deterministically (test, fixture, or
   command). Can't reproduce → gather more evidence; never fix on a guess.
2. **Root-cause** — [GATE] trace to the mechanism, not the symptom: where the
   wrong behavior *originates*, not where it becomes visible. Write it into
   the contract's `root_cause` field (template: "Bug-fix contracts" section)
   **before** writing the fix. The classic trap is fixing at the visibility
   point: search misses a product → the fix is server-side search, not a
   bigger page size.
3. **Generalize** — [GATE] the contract carries at least one acceptance
   criterion strictly more general than the failing instance, strong enough
   that the cheapest symptom patch fails it; pin any tuning constant the
   patch could hide in.
4. **Test first** — write the failing test from the general criterion, not
   from the bug instance; watch it fail for the expected reason (RED).
5. **Fix** — smallest change that addresses the recorded root cause. No
   drive-by refactoring; if the root cause turns out to be Core-level, stop
   and escalate (skill `change-protected-core`).
6. **Verify** — [GATE] `bash tools/check.sh` PASS: the new test passes and
   nothing else broke.
7. **Record** — commit per change-rules with a `Root cause:` line in the
   body. If the defect had escaped a check that should have caught it, also
   open workflow `failure-handling` — that gap is a separate finding.
