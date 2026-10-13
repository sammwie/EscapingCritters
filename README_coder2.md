# Interaction, Dialogue, Activities and Puzzles (Coder 2)

How to use the systems in `res://scripts/`. Everything here is placeholder-art
(shapes drawn in code) until the designers deliver sprites.

## Collision layers

| Layer | Used for |
| --- | --- |
| 1 | World |
| 2 | Interactables (anything the player presses E on) |
| 3 | Player |

Interactables: **Layer 2 only, Mask empty.** The player's Interactor has Mask 2.

## Interactables

`Interactable` (an Area2D) is the base for anything you press E on.

- Exports: `prompt_text` (shown as "Press E: ...") and `enabled`.
- Override `_on_interact(by)` to do something.
- Changing `prompt_text` at runtime updates the prompt automatically.

Ready-made ones: `Sign`, `Door`, `Pickup`, `NPC`, `FarmPlot`, `FishingSpot`,
`ShopCounter`, `TreehouseBed`, `NoticeBoard`, `Egg`, `Rock`.

To make a new one: Area2D root + CollisionShape2D, script extends
`Interactable`, Layer 2, Mask empty.

A scene needs `player.tscn` and `interact_prompt.tscn` for the prompt to work.

## Dialogue

- `DialogueData` resource: `npc_id`, `lines`, `repeat_lines`.
- `DialogueLine` resource: `speaker`, `text`, `min_corruption`, `glitch`.
- First conversation uses `lines`; later ones use `repeat_lines`.
- Lines with `min_corruption` above `GameState.corruption_stage` are skipped.
- Glitch text applies when `glitch` is on or the stage is 3+.
- Scenes that show dialogue need `dialogue_box.tscn`.

### Making an NPC
1. Instance `npc.tscn`.
2. Set its **Dialogue** to a `DialogueData` file (e.g. `dialogues/baker.tres`).
3. Give it a unique `npc_id`.

NPCs freeze (pause their animation) while talking. To freeze something else
mid-line, listen to `Dialogue.line_started(npc_id)` and
`Dialogue.conversation_ended(npc_id)`.

## Puzzles

`Puzzle` is the base class. Every puzzle has a `puzzle_id` and reports
`WorldState.mark_solved(puzzle_id)` when solved (skipped quietly until
WorldState exists).

- `start()`, `reset()`, `complete()`, `fail()`.
- Signals: `solved`, `failed`.
- Override `_on_start()` and `_on_reset()`.

Built: `PuddlePuzzle` (test rocks, reach the goal) and `EggPuzzle` (draft:
take real eggs, fake ones fail it). Test scenes: `puddle_test.tscn`,
`egg_test.tscn`. The egg puzzle is a draft until the designers confirm the spec.

## Activities

`Activity` is the base for cozy activities: `start()`, `finish(result)`,
signals `started` and `finished`.

| Activity | Interactable | What it does |
| --- | --- | --- |
| `FarmManager` + `FarmPlot` | `FarmPlot` | Plant, water, grow, harvest. `end_day()` advances plots |
| `Fishing` | `FishingSpot` | Cast, wait, reel in on the bite |
| `Shop` | `ShopCounter` | Sells farm harvests and fish for gold |
| `Treehouse` | `TreehouseBed` | Sleep to end the day |
| `TownSquare` | `NoticeBoard` | Reads a daily announcement |

Pattern: the logic lives in a child **Node** (`Fishing`, `Shop`, `Treehouse`,
`TownSquare`) and the Interactable draws placeholder art and handles E.
The Interactable looks for the child by name, so don't rename it.

Wiring: `ShopCounter` has `farm_manager_path` and `fishing_spot_path`,
`TreehouseBed` has `farm_manager_path`. Set these in the **scene they are used in**.

## Known gaps

- The treehouse and town square are placeholders: the GDD doesn't define them.
- Prices, fish and crops are placeholder values.
- `FarmManager`'s day and `GameState.current_day` are not linked yet (Coder 3).
- `farm_manager.gd` still has a debug key (N) to skip a day.

## Test scenes

`test_main`, `egg_test`, `fishing_test`, `shop_test`, `square_test`,
`puddle_test`. Run the open scene with F6.
