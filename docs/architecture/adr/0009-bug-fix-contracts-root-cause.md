# ADR-0009: Bug-fix contracts require root cause and a symptom-killing criterion

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner (chat 2026-07-02, "làm đi" on the anti-symptom-fix proposal)

## Context

An agent fixing a bug optimizes for "make the failing case pass" — the
failing case is the only spec it has. That makes the cheapest local patch
(raise a page size, widen a timeout, special-case an id) a *valid* fix
unless something upstream makes it fail. Owner raised this directly
(2026-07-02): agents patch where the bug is visible, not where it
originates.

## Decision

Bug-fix task contracts carry two extra obligations (recorded in
`task-contract-template.md`, section "Bug-fix contracts"):

1. A `root_cause` field naming the mechanism, filled by the executor
   before writing the fix and repeated as a `Root cause:` line in the
   commit body.
2. At least one acceptance criterion strictly more general than the
   failing instance, strong enough that the obvious symptom patch fails
   verification, with tuning constants pinned.

A new `docs/workflows/bug-fixing.md` (Status: active, evidence: the
2026-07-02 external-review remediation) gates the procedure: reproduce →
root-cause → generalize → RED test from the general criterion → fix →
check → record.

## Alternatives considered

- commit-msg hook enforcing a `Root cause:` line on `fix(...)` commits —
  deferred; adds machinery before the convention has mileage. Revisit with
  the commit-msg format hook already in the deferred backlog.
- Relying on the systematic-debugging skill in the agent tooling — helps,
  but lives outside the repo; contracts and workflows are what this
  repository can enforce and review.

## Consequences

Easier: symptom patches fail verification instead of relying on agent
judgment; the dev can audit `Root cause:` lines in the commit log at review
time. Harder: producers must think about the general property when cutting
bug contracts. Revisit when: contract-content linting exists (could then
machine-check the `root_cause` field's presence).
