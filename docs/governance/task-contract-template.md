# Task Contract Template

Every executor session works from exactly one task contract. Producers copy the template below and fill **every** field. Executors: refuse a contract with empty fields.

## Template

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

## Filled example

```yaml
task_id: TASK-2026-09-15-001
objective: >
  Inventory module enforces a per-item stack size limit defined in item data.
context: >
  Spec: docs/memory/domains/inventory.md ("stacking" section). Items define
  max_stack in their content resource; the bag must refuse overflow.
inputs:
  - game/modules/inventory/bag.gd (current add_item implementation)
  - game/content/items/ (item resources with max_stack field)
expected_outputs:
  - game/modules/inventory/bag.gd rejects adds beyond max_stack and returns the remainder
  - game/tests/inventory/test_stacking.gd covering limit, overflow remainder, max_stack=1
allowed_paths:
  - game/modules/inventory/**
  - game/tests/inventory/**
forbidden_actions:
  - editing files outside allowed_paths
  - changing public signatures of game/core/ (Core-level; escalate)
  - adding dependencies or plugins
expected_outputs_verification: >
  Run tools/check. Expected: PASS, including new tests in game/tests/inventory/.
acceptance_criteria:
  - adding 5 to a stack of max 3 stores 3 and returns remainder 2
  - items with max_stack 1 never stack
  - existing inventory tests still pass
required_evidence:
  - tools/check output summary pasted in the task report
iteration_limit: 3
escalation_conditions:
  - acceptance criteria unreachable within iteration_limit
  - task requires touching paths outside allowed_paths
  - task requires a Core-level change
report_format: >
  Reply with: status (done/blocked), what changed, evidence, deviations, follow-ups.
```
