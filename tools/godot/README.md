# Godot binary location

The engine binary lives here but is NOT committed (see root `.gitignore`).

- Pinned version: **Godot 4.7-stable** (see ADR-0002).
- Download: https://github.com/godotengine/godot-builds/releases/tag/4.7-stable → `Godot_v4.7-stable_win64.exe.zip`, unzip into this directory.
- `tools/check` discovers the binary by globbing `tools/godot/Godot_v*.exe`; override with the `GODOT_BIN` environment variable.
