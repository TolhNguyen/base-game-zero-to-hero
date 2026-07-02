# Asset Specification (v1)

The technical contract for ALL sprite art. Hand this file (or the prompt
template below) to whatever image AI generates the art. Art that violates
this spec is rejected mechanically by `tools/art_pack.sh` before a human
ever reviews it.

## Character sprites

| Property | Value |
|---|---|
| Frame size | **64×64 px**, PNG, transparent background (alpha) |
| Directions | 4: `down`, `left`, `right`, `up` |
| Animations | `idle` (4 frames), `walk` (6 frames) — per direction |
| Pivot | bottom-center at pixel (32, 56) — feet stand there |
| Content box | character fits within x 8..56, y 4..56 (margins for effects) |
| Naming | `<set>_<anim>_<dir>_<NN>.png`, `NN` zero-based two digits |

Example set `elder`: `elder_idle_down_00.png` … `elder_walk_up_05.png`
(4×4 + 4×6 = 40 files).

## Tiles / props

32×32 px PNG (props may use 32×64 for tall objects), transparent
background, pivot bottom-center.

## Style (placeholder until an Art Director session writes the style bible)

Clean 2D "hi-bit pixel art", readable silhouettes at 100% zoom, consistent
light from top-left, limited palette per set. Consistency within a set
beats beauty of a single frame.

## Prompt template (copy-paste to the image AI, fill <>)

```text
Create a sprite animation frame set for a 2.5D top-down game.
Subject: <description of the character/prop>.
Style: clean hi-bit pixel art, top-left lighting, limited palette,
readable silhouette, NO background (fully transparent PNG).
Frame: 64x64 pixels. The character's feet touch pixel row 56,
horizontally centered. Keep the whole body inside x 8..56, y 4..56.
Needed: <anim> animation facing <down|left|right|up>, <N> frames,
consistent proportions and palette across ALL frames.
Deliver each frame as a separate PNG named <set>_<anim>_<dir>_<NN>.png.
```

## Pipeline (states: incoming → validated → approved/integrated)

1. Drop generated PNGs into `art_incoming/<set>/` (repo root; gitignored — unapproved art never enters the game).
2. `bash tools/art_pack.sh <set>` — validates naming/size/alpha, packs a sprite sheet + SpriteFrames resource into `game/assets/sprites/`.
3. Human eyeballs the result in-editor (drop the `.tres` into an `AnimatedSprite2D`). Approval = committing the generated files.
4. Track provenance in the commit body: which tool/model generated it, who prompted.
