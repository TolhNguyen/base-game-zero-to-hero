# Card War Presentation Pass Design

- Date: 2026-07-03
- Status: approved for planning by owner
- Scope: visual and UX presentation for the existing Card War tutorial slice
- Current implementation: `game/modules/card_war/ui/battle.tscn`,
  `game/modules/card_war/ui/battle.gd`,
  `game/modules/card_war/ui/cw_map_view.gd`

## Context

The current Card War screen proves the simulation loop, but it looks like a
debug board: flat square terrain colors, text-only vertical hand buttons, and
abstract circle/outline markers. The owner rejected this presentation because
the player cannot feel the cards in hand, the general, the army, the camp, or
the battlefield.

The owner requested:

- Use Vietnamese as the game-facing language.
- Add real aesthetic direction.
- Reference Sunderfolk's tabletop/tactical/card presentation without copying
  its assets, IP, setting, or exact UI.

Reference observations:

- Sunderfolk is presented publicly as a turn-based tactical RPG with tabletop
  "game night" framing and visible card/strategy interaction.
- For Card War, the relevant lesson is not hex conversion or fantasy tone. It is
  readable tactical staging: the player should see the board, units, choices,
  and hand of cards as parts of one polished command surface.

Reference URLs:

- Steam: https://store.steampowered.com/app/2414270/Sunderfolk/
- Dreamhaven: https://www.dreamhaven.com/games/sunderfolk

## Approved Direction

Use a **B+C hybrid** visual direction:

- **B: Sa ban quan lenh** as the foundation: parchment/war-table mood, command
  tokens, banners, city and camp markers, restrained military tone.
- **C: Dem trai tien tuyen** as the accent: warm firelight, darker campaign
  atmosphere, stronger drama around camps, reports, and active orders.

The implementation keeps the current **16x16 square-grid simulation**. It does
not convert Card War to true hex topology in this pass. The grid should feel
like a tactical war table, not a debug matrix.

## Goals

1. Make the tutorial screen visibly game-like and thematically aligned with a
   cold-weapon-era command card game.
2. Make the player's hand read as actual cards, not a list of buttons.
3. Make armies, generals, cities, camps, and convoys visually distinct.
4. Make all user-facing text on this screen Vietnamese.
5. Preserve existing Card War simulation behavior and tests.

## Non-Goals

- No true hex topology.
- No changes to `game/core/` or other Protected Core paths.
- No new third-party dependency, Godot plugin, or editor addon.
- No final production art asset pipeline.
- No new gameplay rules.
- No localization framework. This pass may use Vietnamese literals in the
  Card War UI/content because the slice itself is still game-specific module
  work.

## Layout

The screen should move from "map left, debug controls right" to a tactical
command surface:

```text
+------------------------------------------------------------+
| Luot | Quan lenh | Luong | Si khi                          |
+-----------------------------------------+------------------+
|                                         | Context panel    |
|           16x16 campaign war table      | - selected tile  |
|           rendered as a soft board      | - order preview  |
|                                         | - confirm/cancel |
+-----------------------------------------+------------------+
| Hand bar: Vietnamese command cards                         |
+------------------------------------------------------------+
```

### HUD

Use concise Vietnamese labels:

- `Lượt`
- `Quân lệnh`
- `Lương`
- `Sĩ khí`

The HUD should remain compact and readable. It should not compete with the map
or hand.

### Map

`CwMapView` remains a custom renderer, but it should stop drawing raw flat
rectangles as the primary visual language.

Required map presentation:

- Terrain tiles use a dark campaign palette with softened edges.
- The grid is visible enough for targeting but subdued during idle play.
- Rivers, forests, mountains, and plains are visually distinct at a glance.
- The highlighted tile uses a clear warm outline.
- A selected/preview path should read as an order route, using a dashed or
  glowing line rather than only colored squares.
- Player city, enemy city, camps, convoys, and armies draw above terrain with
  distinct silhouettes/tokens.

The map is still 16x16 and uses the current `CwMapGrid` coordinates.

### Entity Tokens

Entities need identity and role.

- **Army/general**: token with banner/crest feel, side color, short general
  label such as `Ấn` or `Asun`, troops, and optional status.
- **Player city**: fortified blue/gold city marker over its existing footprint.
- **Enemy city**: red fortified marker, clearly hostile.
- **Camp**: tent/banner marker with warm firelight accent.
- **Convoy**: food/cart-style token, visually different from combat armies.

Tokens should be readable at the current camera scale and should not require
external raster assets in this pass. Godot drawing primitives are acceptable if
they produce a polished command-token look.

### Hand Cards

The hand should be a horizontal card bar at the bottom.

Each card should show:

- Vietnamese display name.
- Energy cost as `N quân lệnh`.
- A short order description.
- Disabled state when unaffordable or unusable.
- Selected state when the player is choosing targets.

Initial Vietnamese names:

| Card ID | Vietnamese name |
|---|---|
| `card.march` | `Hành Quân` |
| `card.gather_food` | `Thu Lương` |
| `card.build_camp` | `Dựng Trại` |
| `card.transport` | `Vận Lương` |
| `card.assault` | `Công Thành` |
| `card.feast` | `Mừng Công` |

### Context Panel

The right panel should replace raw English status text with Vietnamese command
guidance.

Examples:

- Idle: `Chọn một lá bài hoặc một đơn vị.`
- March: `Hành Quân: chọn quân số, rồi chọn điểm đến.`
- Build camp: `Dựng Trại: chọn đạo quân đang giữ vị trí.`
- Transport: `Vận Lương: chọn lượng lương, rồi chọn trại hoặc đạo quân.`
- Assault: `Công Thành: chọn đạo quân, rồi chọn thành địch.`
- Feast: `Mừng Công: chọn đạo quân hoặc thành đủ điều kiện.`

Order preview should show concrete consequences:

- Troops
- Destination
- Turns to arrive
- Food budget
- Error/rejection reason in Vietnamese

Avoid generic messages like `err 31`.

### Report Panel

The turn report should become a short Vietnamese military report.

Examples:

- `Lượt 2 bắt đầu.`
- `Lệnh bắt đầu: Hành Quân.`
- `Đạo quân 1 tiến tới (8, 3).`
- `Doanh trại 2 được dựng tại (6, 9).`
- `Thành địch thất thủ.`
- `Chiến thắng.`

Important outcomes such as victory, defeat, starvation, city capture, and army
loss should stand out visually.

## Data and Text

Game-facing content names in `game/content/cards/*.tres` should move to
Vietnamese display names. UI text in `battle.gd` should also be Vietnamese.

Simulation IDs remain stable and unchanged:

- `card.march`, `card.gather_food`, etc.
- `city.home`, `city.enemy`
- `general.asun`

This preserves Constitution P7: stable IDs do not become localized labels.

## Architecture Boundaries

Allowed implementation areas for the later task contract:

- `game/modules/card_war/ui/`
- `game/content/cards/`
- `game/tests/card_war/`
- Optional module-specific docs/spec updates

Protected Core is out of scope.

The simulation layer under `game/modules/card_war/sim/` should not need changes
for the presentation pass unless a test-only helper is required. If a later
implementation discovers a sim change is necessary, it should be called out
before proceeding.

## Testing and Verification

Required verification for implementation:

1. `tools/check` output must pass because the repo is Phase 2+.
2. Existing Card War tests should still prove scene construction, order flow,
   end-turn report, and playthrough behavior.
3. UI tests should be updated to expect Vietnamese-facing labels where they
   assert text.
4. Manual screenshot/evidence should show:
   - Vietnamese HUD.
   - Visible hand cards at the bottom.
   - Distinct city, army/general, camp, and convoy tokens when present.
   - Non-debug map presentation.
   - No obvious text overflow at the current default window size.

## Acceptance Criteria

- The tutorial screen no longer reads as a raw debug grid.
- The hand is visibly a set of cards.
- The map shows the army/general, cities, and camps as distinct entities.
- Core player-facing text on the screen is Vietnamese.
- Order selection and confirmation remain playable.
- No Card War simulation behavior changes.
- `tools/check` passes.

## Implementation Plan Seed

Break implementation into small contracts:

1. Vietnamese content and UI text pass.
2. Layout pass: HUD, context panel, bottom hand bar.
3. Map renderer pass: terrain, tokens, selection, path preview.
4. Report and rejection-message polish.
5. Verification and screenshot evidence.
