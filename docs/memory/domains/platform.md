# Domain: Platform abstraction

- Owner role: Architect
- Last verified: 2026-07-02

`PlatformService` base + standalone implementation (autoload `Platform`). The ONLY seam where Steam (or any store) may ever plug in.

**Invariants**
- Gameplay code never imports a store SDK; it calls the `Platform` autoload.
- Achievement ids are stable IDs (`achievement.*`).
- Standalone must behave sanely forever: features return false, achievements remembered in-session.

**Gotchas**
- Steam impl is deliberately absent; adding it = subclass + swap autoload + per-game ADR.
