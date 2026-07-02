#!/usr/bin/env bash
# art_pack — validate + pack an art_incoming/<set> per docs/art/asset-spec.md
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ $# -ge 1 ] || { echo "usage: bash tools/art_pack.sh <set_name>"; exit 2; }

GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
	GODOT="$(ls "$ROOT"/tools/godot/Godot_v*.exe 2>/dev/null | grep -v console | head -1)"
fi
[ -n "$GODOT" ] && [ -f "$GODOT" ] || { echo "Godot binary not found"; exit 1; }

"$GODOT" --headless --path "$ROOT/game" -s res://addons/art_tools/pack_cli.gd -- "$1"
exit $?
