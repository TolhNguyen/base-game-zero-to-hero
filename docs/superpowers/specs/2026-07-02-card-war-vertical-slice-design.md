# Card War — Vertical Slice Design (Tutorial Mission 1)

- Date: 2026-07-02
- Status: approved by owner (this session)
- Source of truth for the full game vision: `docs/superpowers/specs/2026-07-02-card-war-gameplay-spec-v1.vi.md`
  (owner's original Vietnamese gameplay spec, preserved verbatim)

## Context and process decisions (owner-approved)

- **Game**: turn-based tactical card game set in cold-weapon-era warfare. Cards are
  military orders, not spells. The player is the supreme commander.
- **Repo strategy exception**: workflow `docs/workflows/new-game.md` step 2 says
  fork the factory into a new repository. The owner explicitly chose to build this
  game **on branch `game/Game_card` of the base repo** instead. This is a recorded
  owner decision; the workflow stays as written for future games.
- **Slice scope**: Tutorial Mission 1 ("Quân khởi binh") only — the smallest
  playable loop that proves "cards are orders" is fun.

## What the player experiences

The player opens the game onto a 16x16 grid map. Their home city (2x2 tiles) sits
at the bottom; a small enemy city (1 tile, static garrison, **no AI**) sits to the
north. Each turn (= 3 campaign days) runs the four phases from the spec: issue
orders → commit turn → resolution → campaign report.

- **Win**: capture the small enemy city.
- **Lose**: the main field army disbands (morale 0), all troops are lost, or the
  30-turn scenario limit expires (soft fail — restart).
- **Cards available (6)**: March (Hành quân), Gather Food (Thu lương), Build Camp
  (Dựng trại), Transport Food (Vận lương), Assault (Công thành), Victory Feast
  (Mừng công).
- **General (1)**: Asun (Warrior class), passive "Iron Discipline" — reduces troop
  losses in combat. His three personal cards are out of scope.

### In the slice

- Turn = 3 days; multi-turn orders; a general on a mission is locked until done.
- Energy limits orders per turn; hand/draw/deck cycle.
- Food in thạch units, the locked formula: `food per turn = troops / 100 × 3`.
  Food exists per location (city stock, camp stock, army carry, convoy); the HUD
  shows the faction total.
- Morale per entity (army, city, camp) + faction average on the HUD. Morale 0 =
  disband/surrender.
- Real general positions: the next order starts from where the general actually is.
- Camp footprint by troop count (~2,000 troops per tile).
- March orders auto-budget food for go + hold + return legs (spec §13.4); Build
  Camp cancels the return leg and converts remaining carried food into camp stock.

### Explicitly out of the slice (later iterations)

Scouting, mobile scouts, ambush, siege (encircle), feint, the three visibility
levels (everything is visible in the slice), weather, recruiting, enemy AI,
10-general draft, general personal cards, third-party cities.

## Provisional numbers (data, not code — all live in Definitions)

| Parameter | Provisional value |
|---|---|
| Energy | start 3, +1 per turn, cap 10 |
| Deck | 3 copies × 6 cards = 18; opening hand 5; draw 2/turn; hand cap 10; reshuffle discard when deck empty |
| Energy costs | March 2, Gather Food 1, Build Camp 1, Transport 1, Assault 3, Feast 1 |
| Home city | 5,000 troops, 2,000 thạch stock, produces 40 thạch/day |
| Enemy small city | 1,000 garrison, wall defense factor ×1.5 |
| March speed | 3 tiles/turn on plains, 2 in forest; rivers/mountains impassable in the slice map |
| Convoy speed | 3 tiles/turn |
| Gather Food | +(city daily production × 3) to city stock, instantly |
| Victory Feast | target army/city +30 morale (cap 100); costs 1 day's rations of the target |
| Morale | start 80; −10/turn while starving; +20 on battle victory; 0 = disband/surrender |
| Combat (provisional) | side power = troops × (morale/100) × general factor × fortification factor; victory margin sets both sides' losses and morale swing |

## Architecture

One gameplay module, sim separated from UI (Constitution P2/P8 compliant —
module depends only on core, nothing card-war-specific enters `game/core/`).

```text
game/modules/card_war/
  sim/          # pure-logic GDScript (RefCounted): no scenes, no autoload access
                # GameState, MapGrid, Army, City, Camp, Convoy, Order,
                # TurnResolver, SupplySystem, MoraleSystem, CombatResolver,
                # Deck/Hand/Energy
  ui/           # map grid view (placeholder tiles), hand bar, HUD,
                # order targeting flow, end-turn, campaign report panel
  card_war.gd   # module entry: wires sim to EventBus / scene_flow
game/content/
  cards/        card.march.tres, card.gather_food.tres, ...
  generals/     general.asun.tres
  terrains/     terrain.plains.tres, terrain.forest.tres, terrain.river.tres, terrain.mountain.tres
  maps/         map.tutorial_01.tres        # 16x16 layout + starting setup
  scenarios/    scenario.tutorial_01.tres   # win/lose conditions, turn limit
game/tests/card_war/   # headless gdUnit4 tests against sim/ only
```

**Sim contract**: deterministic and seedable. `TurnResolver.resolve()` consumes the
committed orders and returns an ordered list of event records; the UI renders them
and builds the campaign report from them. Resolution order is fixed:

1. new orders start → 2. movement progresses (marches, convoys) →
3. combat/assault resolves → 4. food production → 5. food consumption →
6. morale update → 7. win/lose check.

**New stable-ID prefixes** (register in `docs/memory/domains/registry.md` before
any content exists, per P7): `card.`, `general.`, `terrain.`, `map.`, `scenario.`.

**Definition schemas** (all extend the core `Definition` resource):
`CardDefinition` (energy cost, order type, targeting requirements),
`GeneralDefinition` (class, passive parameters), `TerrainDefinition` (move cost,
passable flag), `MapDefinition` (grid size, tile layout, starting entities),
`ScenarioDefinition` (win/lose rules, turn limit, deck composition, provisional
tuning values).

## Order targeting flow (UI)

Select card → select subject (army/city per card requirements) → set parameters
(troops, destination, ...) → preview computed time + food cost → confirm. The game
computes path, duration, and food from data; the player never types turn counts
(spec §7.1, §13.4). If the source lacks food, the order cannot be confirmed.

## Error handling

- Orders validate at confirm time (enough troops, food, energy; reachable target);
  invalid orders are rejected with a reason, never partially applied.
- Sim state mutates only inside `TurnResolver.resolve()`; a failed validation
  leaves state untouched (matches ADR-0007 no-partial-state precedent).

## Testing

Headless gdUnit4 suites over `sim/` only: march duration/path math, food
production/consumption and the thạch formula, starvation → morale decay →
disband, combat resolution incl. wall factor and Asun's passive, Build Camp food
conversion and footprint, win/lose detection, deck/draw/energy cycle, and a full
scripted playthrough of the mission (order sequence → win in N turns).

## Process

Implementation follows workflow `feature-development`: tech note → task contracts
(`docs/contracts/TASK-*.yaml`) → executor sessions → `bash tools/check.sh` PASS as
evidence → one task = one commit on `game/Game_card`. Balance numbers stay in
content Definitions so tuning never requires code changes.
