# Mythic Frontiers (Prototype)

A lightweight strategy prototype inspired by *Rome: Total War* with a mythical sci-fi theme:

- 3 alien races.
- 3 unit variants for each race.
- Simple dice-roll combat resolution.
- Flanking and rear attacks grant damage bonuses.
- City and land development unlock stronger units and empire-wide buffs.
- Veteran units gain mythic power and reputation.

## Quick Start (GUI)

```bash
python3 src/mythic_frontiers.py
```

This opens a launcher window. Select a race, then click **Launch Game Window**.
If no desktop display is available (like some servers/containers), it automatically falls back to CLI mode.

Inside the game window, you can:
1. Develop land for treasury.
2. Upgrade your city to unlock stronger units.
3. Choose a unit + attack angle and fight a battle.

## Optional CLI Mode

```bash
python3 -c "from src.mythic_frontiers import run_cli_game; run_cli_game()"
```

## Optional Combat Demo

```bash
python3 -c "from src.mythic_frontiers import run_demo; run_demo()"
```

## Project Layout

- `src/mythic_frontiers.py` – core game model, GUI launcher/window, CLI loop, and demo flow.
- `tests/test_mythic_frontiers.py` – mechanics tests.
- `game_design.md` – design outline, races, units, and progression loop.
