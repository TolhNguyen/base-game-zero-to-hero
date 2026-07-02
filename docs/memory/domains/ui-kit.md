# Domain: UI kit

- Owner role: Director (look) + Architect (structure)
- Last verified: 2026-07-02

Base theme, `FocusHelper`, pause menu, settings menu (`core/ui_kit/`).

**Invariants**
- Every screen must have a focused control when shown (controller navigation) — use `FocusHelper.grab_first`.
- Pause menu pauses the whole tree and runs with `PROCESS_MODE_ALWAYS`; it emits intents (`quit_requested` etc.) — the game decides what they do.
- Screens must be operable with `ui_*` actions only (no mouse required).

**Gotchas**
- Theme is a placeholder; real art direction arrives in Phase 4+.
