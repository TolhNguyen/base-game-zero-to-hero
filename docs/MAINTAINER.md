# Maintainer Guide

For the human developer(s) running this repository. Agents have their own
entry point (`AGENTS.md`); this is yours.

## Daily loop

1. Summon an agent session (Claude Code / Codex / Gemini) and tell it which
   hat it wears: Director, Architect, Producer, or QA (`docs/agents/`).
   No hat named = it acts as an Executor and expects a task contract.
2. Let it work. Governance is mechanical: `tools/check` + the pre-commit
   hook block ring violations and unapproved core edits.
3. Review `git log` when convenient. Every commit carries a task id and
   evidence. `git revert <sha>` undoes any single task.

## New machine setup

```bash
git clone <repo> && cd base-game-zero-to-hero
# 1. engine (not in git): follow tools/godot/README.md
# 2. governance hooks:
bash tools/install_hooks.sh
# 3. verify everything:
bash tools/check.sh        # expect: CHECK: PASS
```

Open `game/project.godot` in Godot 4.7 and press F5 for the Demo Sandbox.

## Verification commands

| Command | What it proves |
|---|---|
| `bash tools/check.sh` | import + validators + all tests + boot smoke |
| `bash tools/check.sh --fast` | validators + tests only (hook subset) |
| `bash tools/art_pack.sh <set>` | validates + packs `art_incoming/<set>` |

## Disaster recovery

- **Bad commit landed:** `git revert <sha>` (one task = one commit). Never rewrite `main` history.
- **Hooks not firing:** `bash tools/install_hooks.sh` (per-clone setting; check `git config core.hooksPath` → `.githooks`).
- **Engine broken/missing:** re-download per `tools/godot/README.md` (pinned: ADR-0002).
- **`tools/check` itself broken:** it is Protected Core — fix commits need an ADR; in an emergency you (human only) may commit with `ALLOW_CORE=1`, then write the ADR after.
- **Player save data:** never fixed by hand-editing schema; write a migration (see `docs/memory/domains/save-system.md`).

## Starting a real game from this base

Follow "Starting a new game" in `docs/architecture/overview.md`. Short
form: copy repo → delete `game/demo/` + demo `game/content/` → remove the
`DemoState` autoload + `app/start_scene_id` lines → `tools/check` still
passes → build your game in `modules/` + `content/` using the skills in
`docs/skills/`.

## When to recall the Super Agent

Only for the five cases in `CONSTITUTION.md` §5 (constitution changes,
protected-core boundary changes, agent/permission model changes, engine
replacement, unresolvable ecosystem incident). Everything else is normal
work for role sessions. Recap of what exists so you can judge: 9 core
services, 5 modules, demo, `tools/check` + hooks, 5 ADRs, 4 skills,
2 workflows, art pipeline — all evidenced in the commit log.
