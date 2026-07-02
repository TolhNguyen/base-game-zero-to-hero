# Skill: add-gameplay-module

- Status: active
- Owner: Architect
- Evidence: commits 5d1b6cc, c295e18, 425a269, 1ffa27d, ec7e6ec (all five Phase-3 modules built with this recipe)

## When to use

Adding a new ring-2 gameplay module to `game/modules/`.

## Steps

1. **Contract first.** Producer fills `docs/governance/task-contract-template.md` → `docs/contracts/TASK-YYYY-MM-DD-NNN.yaml`. `allowed_paths` = the new module dir + `game/tests/**`.
2. **Design for headless testability.** All logic lives in pure methods or injectable-dependency nodes (`var registry: Node`, `var bus: Node` — autoload defaults resolved in `_ready`, tests inject fresh instances). `_physics_process`/`_unhandled_input` are thin wrappers only — headless tests cannot simulate real InputEvents.
3. **Data as Definitions.** Any data concept extends `Definition` with a namespaced stable id (`item.*`, `quest.*`). Test fixtures go in `game/tests/fixtures/<module>/`, real content in `game/content/` (separate task).
4. **Cross-module effects via EventBus topics only.** Dot-namespaced, documented in the module's domain doc. Never `preload` another module (P8 — `tools/validate_deps.sh` will fail the commit).
5. **Write tests with the suite pattern:** `_fresh()`/`_wired()` builders + `auto_free`. Cover: happy path, unknown-id error, wrong-type error, event publication, save round-trip if the module has state.
6. **Verify + commit:** `bash tools/check.sh` → PASS quoted in commit body with the task id.
7. **Domain doc:** add/update `docs/memory/domains/<module>.md` (invariants + gotchas, ≤ 1 page).

## GDScript gotchas that actually bit us (warnings are errors here)

- `var x := call_returning_variant()` → PARSE ERROR. Type it: `var x: Node = auto_free(...)`, `var err: int = svc.save_game(1)`.
- Assigning `[...]` literal to an `Array[Callable]`-typed property fails; build a typed local first (`var migs: Array[Callable] = [...]`).
- JSON round-trips ints as floats — compare against `5.0` or cast.
- Test scripts with parse errors abort the WHOLE run (exit 105) — read the first `SCRIPT ERROR`, not the summary.
