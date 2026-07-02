# Phase 4 — Production Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans (inline) — same economy deviation as Phases 2–3.

**Goal:** Codify what Phases 2–3 proved by hand into registered skills and workflows, and stand up the art integration pipeline (spec → validate → pack → approve) for 100% AI-generated assets.

**Architecture:** Docs (`docs/skills/`, `docs/workflows/`, `docs/art/`) + art tooling as headless GDScript under `game/addons/art_tools/` (packing logic is a testable class; CLI wrappers are thin SceneTree scripts). Unapproved art stays OUTSIDE the game at `art_incoming/` (repo root, never imported); approved output lands in `game/assets/`.

**Tech Stack:** unchanged. No new dependencies (Image API does all pixel work).

## Global Constraints

- Skills/workflows extracted from REAL Phase 2–3 practice, registered `active` only with evidence links to existing commits (lifecycle rule in docs/skills/README.md). Nothing speculative (P6).
- Art tooling adds no third-party code; `art_incoming/` is gitignored except a README.
- `tools/check` PASS per commit, as always.

## Tasks

### T1 — Skills (4 files, status: active, evidence = Phase 2-3 commits)
- `docs/skills/add-gameplay-module.md` — the 101–105 recipe: contract → module dir → testable-pure-logic pattern → fixtures → check → commit format. Includes the GDScript gotchas that actually bit: `:=` from Variant is a parse error (warnings-as-errors), typed-array assignment, headless input limits.
- `docs/skills/add-content-definition.md` — hand-writing `.tres` Definitions, stable ID naming, fixture-vs-content placement, registry scan test.
- `docs/skills/verify-with-tools-check.md` — running/reading `tools/check`, `--fast`, PIPESTATUS trap, `--ignoreHeadlessMode`, evidence quoting rules.
- `docs/skills/change-protected-core.md` — the stop→warn→approve→ADR→commit-together procedure with ADR-0003/0004/0005 as worked examples.

### T2 — Workflows (2 files, status: active)
- `docs/workflows/feature-development.md` — spec → tech note → contracts → execute → verify → commit → dev reviews log (gates marked).
- `docs/workflows/failure-handling.md` — detect → FAIL entry → system action → close (FAIL-2026-07-02-01 as the worked example).

### T3 — Art spec + incoming area
- `docs/art/asset-spec.md` — THE brief handed to image AIs: character frames 64×64 PNG, alpha background, 4 directions (down/left/right/up), anims idle(4)/walk(6), naming `<set>_<anim>_<dir>_<NN>.png`, pivot bottom-center (32,56), tiles 32×32, plus a copy-paste prompt template.
- `art_incoming/README.md` + gitignore rule (files stay local until approved).

### T4 — Art tooling (testable)
- `game/addons/art_tools/sheet_packer.gd` — class `SheetPacker`: `validate_frames(paths) -> Array[String]` (uniform size, alpha, naming) and `pack(frames_by_anim, frame_size) -> {image, regions}` grid packing; `write_spriteframes(...)` emits sheet PNG + SpriteFrames `.tres` with atlas regions.
- `game/addons/art_tools/pack_cli.gd` — SceneTree wrapper: `godot --headless -s ... -- <set_name>` reads `art_incoming/<set_name>/`, writes `game/assets/sprites/<set_name>_sheet.png` + `<set_name>_frames.tres`.
- `tools/art_pack.sh` — bash wrapper.
- `game/tests/art/test_sheet_packer.gd` — generates synthetic frames via Image at runtime; asserts validation catches bad sizes/names; asserts pack geometry and SpriteFrames output loads.

### T5 — End-to-end demonstration + gate
Generate a synthetic 2-anim sample set into `art_incoming/sample/` (script), run `tools/art_pack.sh sample`, confirm `game/assets/sprites/sample_*` load in-engine; delete sample outputs or keep as reference set (keep: proves pipeline to future agents). README status; `tools/check` PASS; phase gate commit.
