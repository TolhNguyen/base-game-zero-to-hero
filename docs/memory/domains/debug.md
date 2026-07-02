# Domain: Debug / logging

- Owner role: Architect
- Last verified: 2026-07-02

Structured logger (`core/debug/log.gd`, autoload `Log`).

**Invariants**
- `Log.debug/info/warn/error(msg, ctx)` — ctx is a Dictionary, serialized to the line.
- Ring buffer feeds a future debug overlay; file sink is `user://logs/session.log`.
- WARN+ goes to stderr; agents quote these lines as evidence.

**Gotchas**
- Detached instances (tests) skip file IO because `_ready` never runs — by design.
