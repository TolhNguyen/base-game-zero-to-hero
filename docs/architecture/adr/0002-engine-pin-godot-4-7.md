# ADR-0002: Pin engine to Godot 4.7-stable

- Date: 2026-07-02
- Status: Accepted
- Approved by: Human Owner ("Tải Godot đi", chat 2026-07-02)

## Context

Phase 2 needs a concrete engine binary for headless import, tests, and validators. No Godot installation existed on the dev machine. The base must pin one version so agents, tests, and humans all run the same engine.

## Decision

Pin Godot **4.7-stable** (official build, win64 portable). The binary lives in `tools/godot/` (gitignored, per-machine download); `tools/check` finds it via glob `tools/godot/Godot_v*.exe`, overridable with `GODOT_BIN`.

## Alternatives considered

- 4.6.3-stable (older branch) — rejected: 4.7 is the current stable; a fresh base should not start one branch behind.
- Installing via Steam/system installer — rejected: portable zip is reproducible, frugal, and trivially replaceable.
- Committing the binary to git — rejected: 178 MB binary bloats the repo forever.

## Consequences

Easier: identical engine everywhere; upgrading = new ADR + swap binary + run `tools/check`. Harder: fresh clones must download the binary once (documented in `tools/godot/README.md`). Revisit when: a 4.7.x patch release fixes bugs we hit, or a future game needs features from a newer minor.
