# Domain: Input

- Owner role: Architect
- Last verified: 2026-07-02

Default actions in `project.godot` (`move_*`, `interact`, `pause` — keyboard AND gamepad from day 1) + `InputRemap` static helpers.

**Invariants**
- Actions use physical keycodes (layout-independent).
- `ui_*` actions belong to the engine: never serialized, never bulk-rebound.
- Rebinds persist via Settings key `input.bindings` holding `InputRemap.serialize()` output (var_to_str event strings).

**Gotchas**
- Headless tests cannot simulate real input events reliably — test InputMap state, not event delivery.
