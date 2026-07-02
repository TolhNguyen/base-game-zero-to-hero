#!/usr/bin/env bash
# tools/check — the single verification entry point (Constitution P4).
# Usage: bash tools/check.sh [--fast]
#   --fast  skip the full import step (pre-commit hook uses this)
# Exit code: 0 = PASS, nonzero = FAIL.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME="$ROOT/game"
FAST=0
[ "${1:-}" = "--fast" ] && FAST=1

fail() { echo "CHECK: FAIL — $1"; exit 1; }

# --- 1. Engine discovery -----------------------------------------------------
GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
	GODOT="$(ls "$ROOT"/tools/godot/Godot_v*.exe 2>/dev/null | grep -v console | head -1)"
fi
[ -n "$GODOT" ] && [ -f "$GODOT" ] || fail "Godot binary not found (see tools/godot/README.md, or set GODOT_BIN)"
echo "check: engine = $("$GODOT" --headless --version 2>/dev/null | tail -1)"

# --- 2. Headless import ------------------------------------------------------
if [ "$FAST" -eq 0 ]; then
	echo "check: importing project..."
	"$GODOT" --headless --path "$GAME" --import >/dev/null 2>&1
	[ $? -eq 0 ] || fail "headless import failed"
	echo "check: import OK"
fi

# --- 3. Validators (fast, deterministic) --------------------------------------
for v in "$ROOT"/tools/validate_*.sh; do
	[ -f "$v" ] || continue
	echo "check: running $(basename "$v")..."
	bash "$v" || fail "$(basename "$v") failed"
done

# --- 4. Headless tests ---------------------------------------------------------
echo "check: running gdUnit4 tests..."
TEST_OUT="$("$GODOT" --headless --path "$GAME" \
	-s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests -c --ignoreHeadlessMode 2>&1)"
TEST_EXIT=$?
echo "$TEST_OUT" | grep -E "Overall Summary|test cases" | tail -2
[ $TEST_EXIT -eq 0 ] || { echo "$TEST_OUT" | tail -30; fail "tests failed (exit $TEST_EXIT)"; }

# --- 5. Boot smoke (ADR-0005) ---------------------------------------------------
if [ "$FAST" -eq 0 ]; then
	echo "check: boot smoke..."
	BOOT_OUT="$("$GODOT" --headless --path "$GAME" --quit-after 30 2>&1)"
	BOOT_EXIT=$?
	if [ $BOOT_EXIT -ne 0 ]; then
		echo "$BOOT_OUT" | tail -10
		fail "boot smoke exited nonzero ($BOOT_EXIT)"
	fi
	if echo "$BOOT_OUT" | grep -qE "SCRIPT ERROR|Parse Error|Failed to instantiate an autoload"; then
		echo "$BOOT_OUT" | grep -E "SCRIPT ERROR|Parse Error|Failed to instantiate|at: " | head -10
		fail "boot smoke found script errors"
	fi
	# Positive markers: absence of errors is not evidence the boot ran (ADR-0008).
	echo "$BOOT_OUT" | grep -q "boot: ok" || fail "boot smoke missing 'boot: ok' marker"
	if [ -d "$GAME/content" ]; then
		echo "$BOOT_OUT" | grep -q "boot: content scanned" \
			|| fail "boot smoke missing 'boot: content scanned' marker (content scan failed?)"
	fi
	echo "check: boot smoke OK"
fi

echo "CHECK: PASS"
