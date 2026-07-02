# Workflow: new-game

- Status: draft
- Owner: Director
- Evidence: none yet — promote to active after the first real game ships its
  vertical slice through this checklist

From "I have a game idea" to a playable vertical slice on top of this base.
Ordered checklist; **[GATE]** steps must pass before continuing.

1. **Vision** — Director session, ≤ 1 page, before touching any code:
   genre, player fantasy, the one core loop sentence ("the player does X to
   get Y so they can X better"), and two lists: what this base already gives
   the idea, what is missing. If the missing list dwarfs the given list,
   reconsider whether this base is the right starting point — that is a
   valid outcome.
2. **Fork the factory** — copy the repo to a new repository (never build a
   game inside the base itself). Mechanical steps per
   `docs/architecture/overview.md` "Starting a new game": delete
   `game/demo/` and demo data in `game/content/`, remove the `DemoState`
   autoload and repoint `app/start_scene_id`, keep `core/`, `docs/`,
   `tools/` as-is. `CONSTITUTION.md` and governance carry over; ADR and
   contract numbering starts fresh in the new repo (the base's records stay
   in the base).
3. **Clean-slate check** — [GATE] `bash tools/install_hooks.sh` then
   `bash tools/check.sh` → CHECK: PASS on the fresh copy *before any game
   code exists*. A red baseline poisons every later verification.
4. **Module audit** — Architect: walk `game/modules/` against the vision;
   keep, delete, or list-as-new each module. For every new module: name,
   EventBus topics (owner + payload), Definition schemas. This is the tech
   note that feature contracts will cite.
5. **Content model** — define the game's stable-ID prefixes (`item.`,
   `scene.`, `card.`, ...) and Definition types; record them in
   `docs/memory/domains/registry.md` of the new repo. IDs are the identity
   of everything (P7) — settle the naming before content exists, renaming
   ids later touches every save and reference.
6. **Vertical slice spec** — Director cuts the smallest playable loop that
   proves the fantasy: one scene, one mechanic, win/lose visible. Nothing
   speculative (P6) — the slice's job is to answer "is this fun?", not to
   scaffold the full game.
7. **Build the slice** — hand off to workflow `feature-development`
   (spec → tech note → contracts → execute → verify → commit). Bugs found
   on the way follow `bug-fixing`.
8. **Play gate** — [GATE] a human plays the slice and decides: continue
   (vision holds), adjust (rewrite step-1 page, re-cut the slice), or stop.
   An agent cannot pass this gate; "it runs" is not "it's fun".
9. **Rhythm** — from here development is the normal loop: features via
   `feature-development`, defects via `bug-fixing`, escaped defects via
   `failure-handling`. Update this workflow with what the first real run
   teaches, then promote it to active.
