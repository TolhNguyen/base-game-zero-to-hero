#!/usr/bin/env bash
# validate_protected — enforces the Protected Core rules on STAGED changes
# (docs/governance/protected-core.md). Run by the pre-commit hook.
#   1. A commit touching protected paths must also add a new ADR
#      (the ADR records the dev's approval).
#   2. Existing ADRs are immutable except their "- Status:" line.
# Human dev escape hatch (agents must never use it): ALLOW_CORE=1 git commit ...
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STAGED="$(git diff --cached --name-only 2>/dev/null || true)"
[ -z "$STAGED" ] && { echo "validate_protected: OK (nothing staged)"; exit 0; }

is_protected() {
	case "$1" in
		CONSTITUTION.md|docs/governance/*|game/core/*|tools/check*|tools/validate_*) return 0 ;;
		*) return 1 ;;
	esac
}

TOUCHED_PROTECTED=""
while IFS= read -r f; do
	if is_protected "$f"; then
		TOUCHED_PROTECTED="$TOUCHED_PROTECTED$f"$'\n'
	fi
done <<< "$STAGED"

if [ -n "$TOUCHED_PROTECTED" ]; then
	NEW_ADR="$(git diff --cached --name-status | awk '$1=="A" && $2 ~ /^docs\/architecture\/adr\/[0-9]/ {print $2}')"
	if [ -z "$NEW_ADR" ] && [ "${ALLOW_CORE:-0}" != "1" ]; then
		echo "PROTECTED CORE: this commit touches protected paths:"
		printf '%s' "$TOUCHED_PROTECTED" | sed 's/^/  - /'
		echo "It must include a NEW ADR in docs/architecture/adr/ recording dev approval."
		echo "(Procedure: docs/governance/protected-core.md. Human devs only: ALLOW_CORE=1 to bypass.)"
		exit 1
	fi
fi

# --- ADR immutability (only the Status line may change) -------------------------
MODIFIED_ADRS="$(git diff --cached --name-status | awk '$1=="M" && $2 ~ /^docs\/architecture\/adr\/[0-9]/ {print $2}')"
for adr in $MODIFIED_ADRS; do
	ILLEGAL="$(git diff --cached -U0 -- "$adr" | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | grep -vE '^[+-]- Status:' || true)"
	if [ -n "$ILLEGAL" ]; then
		echo "ADR IMMUTABILITY: $adr may only change its '- Status:' line (supersede instead):"
		echo "$ILLEGAL"
		exit 1
	fi
done

DELETED_ADRS="$(git diff --cached --name-status | awk '$1=="D" && $2 ~ /^docs\/architecture\/adr\/[0-9]/ {print $2}')"
if [ -n "$DELETED_ADRS" ]; then
	echo "ADR IMMUTABILITY: ADRs must never be deleted:"
	echo "$DELETED_ADRS" | sed 's/^/  - /'
	exit 1
fi

echo "validate_protected: OK"
exit 0
