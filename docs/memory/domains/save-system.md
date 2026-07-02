# Domain: Save system

- Owner role: Architect
- Last verified: 2026-07-02

Versioned JSON saves (`core/save/save_service.gd`, autoload `SaveService`). **Schema changes are Core-level.**

**Invariants**
- Every file carries `schema_version`. Loaders migrate forward one version at a time; NEVER backward; files newer than `SCHEMA_VERSION` are refused.
- Systems own their data via providers (`capture()`/`restore()`); the service never inspects provider payloads (P2).
- Changing `SCHEMA_VERSION` requires: bump + migration Callable + test with a fixture file of the old version + ADR.

**Gotchas**
- JSON round-trips numbers as floats — providers must tolerate `5.0` for `5`.
- Provider keys are part of the save format: renaming one is a schema change.
