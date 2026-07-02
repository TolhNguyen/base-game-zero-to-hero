#!/usr/bin/env bash
# validate_deps — enforces Constitution P8 (one-way dependencies).
#   Ring 1: game/core/    may not reference res://modules or res://demo
#   Ring 2: game/modules/X may not reference res://modules/Y (Y != X)
# Exit: 0 = OK, 1 = violation.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

# --- core must not look upward -------------------------------------------------
if [ -d "$ROOT/game/core" ]; then
	HITS="$(grep -rn --include='*.gd' --include='*.tscn' --include='*.tres' \
		-e 'res://modules' -e 'res://demo' "$ROOT/game/core" || true)"
	if [ -n "$HITS" ]; then
		echo "P8 VIOLATION: game/core references upper rings:"
		echo "$HITS"
		FAIL=1
	fi
fi

# --- modules must not reference sibling modules --------------------------------
if [ -d "$ROOT/game/modules" ]; then
	for moddir in "$ROOT"/game/modules/*/; do
		[ -d "$moddir" ] || continue
		mod="$(basename "$moddir")"
		HITS="$(grep -rn --include='*.gd' --include='*.tscn' --include='*.tres' \
			-e 'res://modules/' "$moddir" | grep -v "res://modules/$mod" || true)"
		if [ -n "$HITS" ]; then
			echo "P8 VIOLATION: module '$mod' references sibling modules:"
			echo "$HITS"
			FAIL=1
		fi
	done
	# modules must not reference demo either
	HITS="$(grep -rn --include='*.gd' --include='*.tscn' --include='*.tres' \
		-e 'res://demo' "$ROOT/game/modules" || true)"
	if [ -n "$HITS" ]; then
		echo "P8 VIOLATION: game/modules references demo ring:"
		echo "$HITS"
		FAIL=1
	fi
fi

[ $FAIL -eq 0 ] && echo "validate_deps: OK"
exit $FAIL
