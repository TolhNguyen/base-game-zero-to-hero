# art_incoming

Drop AI-generated PNG sets here as `art_incoming/<set>/<set>_<anim>_<dir>_<NN>.png`
(spec: `docs/art/asset-spec.md`), then run `bash tools/art_pack.sh <set>`.

Everything here except this README is **gitignored**: unapproved art never
enters version control or the game. Approval = the packed output in
`game/assets/sprites/` getting committed.
