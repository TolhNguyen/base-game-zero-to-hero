# Domain: EventBus

- Owner role: Architect
- Last verified: 2026-07-02

Topic-based pub/sub (`core/events/event_bus.gd`, autoload `EventBus`). The ONLY sanctioned channel for module-to-module communication (P8).

**Invariants**
- Callbacks take exactly one `Dictionary` payload.
- Topic names are dot-namespaced StringNames owned by the publisher (e.g. `&"scene.changed"`).
- Publishing to a topic with no subscribers is a silent no-op by design.
- Dead callables are pruned on publish; subscribing twice delivers once.

**Gotchas**
- Delivery is synchronous and in subscription order — do not rely on order between modules.
- Subscribers may (un)subscribe during delivery (iteration works on a copy).
