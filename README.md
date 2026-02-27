# Godot 4 Strategy MVP

Data-driven Rome-era campaign prototype with strict rules/view separation.

## Implemented MVP pillars
- Square-grid 2D campaign map with click selection and highlighted tile
- `GameState` autoload rules engine with command API only:
  - `build_town`, `upgrade_town`, `construct_building`, `recruit`, `move_army`, `end_turn`, `save`, `load`
- Towns (level 1-5+) with per-turn gold/food income and JSON building modifiers
- Recruitment from JSON unit definitions into garrison or army token
- Army movement with movement points and Manhattan range checks
- End-turn resource, upkeep, and movement refresh loop
- Full GameState snapshot persistence to JSON (`user://savegame.json`)
- Ancient Relics POIs (data-driven permanent empire modifiers)

## Run locally (your machine)

### Prerequisites
- Install **Godot 4.2 or newer** (standard editor build).
- Confirm install:
  - macOS/Linux: `godot4 --version` (or `godot --version` depending on package name)
  - Windows (PowerShell): `& "C:\Path\To\Godot_v4.x-stable_win64.exe" --version`

### Open and run in editor
1. Clone this repo (or copy project files) to any local folder.
2. Open Godot and click **Import**.
3. Select the project folder and choose `project.godot`.
4. Open the project.
5. Press **F5** (or click the Play button).

The project is configured to start at `res://scenes/Main.tscn` via `run/main_scene` in `project.godot`.

### Run from command line (optional)
From the project root:
- macOS/Linux:
  - `godot4 --path .`
- Windows (PowerShell):
  - `& "C:\Path\To\Godot_v4.x-stable_win64.exe" --path .`

### Where save files are written
- In-game **Save** writes to `user://savegame.json`.
- `user://` resolves to Godot's app-data folder on your OS (not the repo directory).

## Quick smoke test checklist
1. Click a map tile and verify selected coordinates update.
2. Click **Build Town** on selected tile.
3. Click **End Turn** and verify gold/food values change.
4. Recruit units from the town panel buttons.
5. Move an army with movement buttons and verify move points decrease.
6. Click **Save**, perform actions, then **Load** and verify state restoration.

## Content files
- `res://data/unit_defs.json`
- `res://data/building_defs.json`
- `res://data/terrain_defs.json`
- `res://data/relic_defs.json`
- `res://data/example_savegame.json`

## Notes
- No combat, AI, fog-of-war, or art pipeline included (by MVP scope).
- GameState stores only primitive values/dictionaries and no Node references.
