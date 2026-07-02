# Workflow: feature-development

- Status: active
- Owner: Producer
- Evidence: Phase 3 end-to-end (plan eae7124 → contracts 101–106 → gate f291c5e)

Ordered checklist; **[GATE]** steps must pass before continuing.

1. **Spec** — Director writes ≤ 1 page: what the player experiences, why it belongs in scope. Stored in `docs/memory/domains/` or the phase plan.
2. **Tech note** — Architect: module boundaries, public API, EventBus topics, Definition schemas. Flags any Core-level need NOW (→ skill `change-protected-core`).
3. **Contracts** — Producer cuts the work into `docs/contracts/TASK-*.yaml`, each independently verifiable and revertable. [GATE] no empty fields; executors refuse otherwise.
4. **Execute** — one executor session per contract, inside `allowed_paths`, iteration limit respected. Skills: `add-gameplay-module`, `add-content-definition`.
5. **Verify** — [GATE] `bash tools/check.sh` PASS (skill `verify-with-tools-check`); for player-facing work also a real headless run of the game.
6. **Commit** — one task = one commit, task id + evidence in body, contract file committed with the work.
7. **Review** — dev reads the commit log (Normal level). Core-level went through its own gate in step 2.
8. **Learn** — anything that surprised you → `docs/memory/failures/` via workflow `failure-handling`; recipe improvements → update the relevant skill.
