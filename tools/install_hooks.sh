#!/usr/bin/env bash
# One-time setup per clone: activates the repo's git hooks.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
git -C "$ROOT" config core.hooksPath .githooks
echo "hooks installed: core.hooksPath -> .githooks"
