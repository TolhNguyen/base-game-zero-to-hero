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

# --- class_name references across rings ----------------------------------------
# P8 coupling with no res:// string to catch: a script naming another ring's
# class_name directly. Module classes may be used only by their own module
# and by demo (Ring 3); demo classes may be used by nobody below demo.
check_class_use() {  # $1 = class, $2 = dir to search, $3 = violation message
	local hits
	hits="$(grep -rnw --include='*.gd' "$1" "$2" 2>/dev/null \
		| grep -vE ':[0-9]+:[[:space:]]*#' || true)"
	if [ -n "$hits" ]; then
		echo "P8 VIOLATION: $3"
		echo "$hits"
		FAIL=1
	fi
}

MOD_CLASS_PAIRS=""
if [ -d "$ROOT/game/modules" ]; then
	for moddir in "$ROOT"/game/modules/*/; do
		[ -d "$moddir" ] || continue
		mod="$(basename "$moddir")"
		for cls in $(grep -rh --include='*.gd' '^class_name ' "$moddir" | awk '{print $2}'); do
			MOD_CLASS_PAIRS="$MOD_CLASS_PAIRS$cls $mod"$'\n'
		done
	done
fi

while read -r cls mod; do
	[ -n "$cls" ] || continue
	[ -d "$ROOT/game/core" ] && \
		check_class_use "$cls" "$ROOT/game/core" \
			"game/core uses module class '$cls' (owned by module '$mod')"
	for other in "$ROOT"/game/modules/*/; do
		[ "$(basename "$other")" = "$mod" ] && continue
		check_class_use "$cls" "$other" \
			"module '$(basename "$other")' uses class '$cls' (owned by module '$mod')"
	done
done <<< "$MOD_CLASS_PAIRS"

if [ -d "$ROOT/game/demo" ]; then
	for cls in $(grep -rh --include='*.gd' '^class_name ' "$ROOT/game/demo" | awk '{print $2}'); do
		[ -d "$ROOT/game/core" ] && \
			check_class_use "$cls" "$ROOT/game/core" "game/core uses demo class '$cls'"
		[ -d "$ROOT/game/modules" ] && \
			check_class_use "$cls" "$ROOT/game/modules" "game/modules uses demo class '$cls'"
	done
fi

[ $FAIL -eq 0 ] && echo "validate_deps: OK"
exit $FAIL
