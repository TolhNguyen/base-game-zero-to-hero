# Skill: verify-with-tools-check

- Status: active
- Owner: QA
- Evidence: every Phase 2–3 commit body; boot-smoke addition in 4857679

## When to use

Before EVERY commit claim (P4: verifiable over plausible).

## Steps

1. Run `bash tools/check.sh` from the repo root. Steps executed: engine discovery → headless import → `tools/validate_*.sh` → gdUnit4 tests → boot smoke (runs the real game 30 frames).
2. `--fast` skips import + boot smoke — the pre-commit hook uses it; full check is what you quote as evidence.
3. Quote the result in the commit body: `Evidence: tools/check PASS — NN/NN test cases (...)`. "Evidence: none" is invalid (change-rules).

## Reading failures

- `CHECK: FAIL — tests failed (exit 100)` → a test failed; scroll to the first `FAILED` block.
- Exit 105 → a test SCRIPT failed to parse; fix the first `SCRIPT ERROR` line, the summary is meaningless.
- `P8 VIOLATION` → you referenced an upper ring; restructure via EventBus, don't silence the validator.
- `PROTECTED CORE` at commit time → you touched protected paths; use skill `change-protected-core`.
- Boot smoke failure → the game itself doesn't parse/boot; tests alone cannot see this class (see FAIL-2026-07-02-01).

## Gotchas

- In scripts, a pipe eats Godot's exit code — use `${PIPESTATUS[0]}` (check.sh already does).
- gdUnit4 headless needs `--ignoreHeadlessMode` (already wired).
- `push_error` in production code does NOT fail a test — assert on return values.
