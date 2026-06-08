# アルデン家の年代記 — Chronicles of the Alden Clan

Godot 4 generational dynasty RPG. Players manage a family clan across multiple generations to build a legendary city.

## Core loop
Adventure → Record in chronicle → Inheritance selection → Next generation

## Project layout

```
scenes/          UI scenes (.tscn + .gd pairs)
  main/          World map, HUD, new-game flow
  character/     Active character stat panel
  chronicle/     Family chronicle viewer
  generation_end/  Inheritance selection screen
  gallery/       Ancestor portrait gallery
scripts/
  data/          Autoloads (GameData, SaveManager)
  models/        Plain GDScript classes (no Node)
resources/
  skills/        Future .tres Skill resources
  items/         Future .tres Item resources
```

## Autoloads
| Singleton   | Path                          | Purpose                     |
|-------------|-------------------------------|-----------------------------|
| GameData    | scripts/data/GameData.gd      | Central game state          |
| SaveManager | scripts/data/SaveManager.gd   | JSON save/load              |

## Key classes (class_name)
- `Generation` — one playable family member
- `Skill`       — skill with inheritance chain
- `Item`        — equippable/heirloom item
- `WorldChange` — a permanent map modification
- `WorldState`  — aggregated world/progress data

## Save file
`user://savegame.json` — written by `SaveManager.save_game()`.

## Goal
Build 20 structures (WorldChange type="build") → goal_progress reaches 1.0 → legendary city complete.

## Running
Open the project in Godot 4.2+ and press F5 (or run the editor).
The main scene is `res://scenes/main/Main.tscn`.
