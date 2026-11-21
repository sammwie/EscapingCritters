INTERACTION, DIALOGUE, ACTIVITIES, PUZZLES AND THE BOSS FIGHT (CODER 2)
=======================================================================

How to use the systems in res://scripts/. Interactables and activities are
placeholder-art (shapes drawn in code) until the designers deliver sprites.
Knows All uses the designers' sprites.


COLLISION LAYERS
----------------

  Layer 1 - World
  Layer 2 - Interactables (anything the player presses E on)
  Layer 3 - Player

Interactables: Layer 2 only, Mask empty. The player's Interactor has Mask 2.


INTERACTABLES
-------------

Interactable (an Area2D) is the base for anything you press E on.

- Exports: prompt_text (shown as "Press E: ...") and enabled.
- Override _on_interact(by) to do something.
- Changing prompt_text at runtime updates the prompt automatically.

Ready-made ones: Sign, Door, Pickup, NPC, FarmPlot, FishingSpot, ShopCounter,
TreehouseBed, NoticeBoard, Egg, Rock, Bed, PetCat, StoryInteractable,
PuzzleTrigger.

To make a new one: Area2D root + CollisionShape2D, script extends
Interactable, Layer 2, Mask empty.

A scene needs player.tscn and interact_prompt.tscn for the prompt to work.


StoryInteractable
-----------------

An Interactable that only works at the right moment in the story. Add it as a
child of an NPC or object.

Exports:
- dialogue: normal conversation.
- story_dialogue: played instead when required_flag is set and done_flag is
  not.
- use_parent_dialogue: use the parent NPC's dialogue as the normal
  conversation.
- active_flag: only enabled while this flag is on.
- required_flag, done_flag: when the story conversation is available and when
  it is finished.
- flicker_on_finish: flicker the glitch overlay when it ends.

Signal: story_beat_finished.

In test_main.tscn the Baker node has Enabled off and its child Baker2D handles
the confrontation (story dialogue baker_confrontation.tres, required flag
cat_dead, done flag baker_confronted, use_parent_dialogue on). Mochi's child
CatStory is only active while cat_dead is set.


Bed and PetCat
--------------

- Bed: press E, fade to black, runs Level1Quest.sleep_through_night() and
  Level2Quest.wake_up(), sets the slept flag and shows "Day N".
- PetCat (Mochi): hearts when petted. Petting is disabled while cat_dead is
  set and the sprite swaps to dead_texture.


DIALOGUE
--------

- DialogueData resource: npc_id, lines, repeat_lines.
- DialogueLine resource: speaker, text, min_corruption, glitch.
- First conversation uses lines; later ones use repeat_lines.
- Lines with min_corruption above GameState.corruption_stage are skipped.
- Glitch text applies when glitch is on or the stage is 3+. Letters are
  swapped for look-alike digits and the text always stays readable.
- Scenes that show dialogue need dialogue_box.tscn.

Making an NPC:
1. Instance npc.tscn.
2. Set its Dialogue to a DialogueData file (e.g. dialogues/baker.tres).
3. Give it a unique npc_id.

NPCs freeze (pause their animation) while talking. To freeze something else
mid-line, listen to Dialogue.line_started(npc_id) and
Dialogue.conversation_ended(npc_id).

Starting a conversation from code:
- Dialogue.start(data) begins it, and "await Dialogue.conversation_ended"
  waits for it to finish.
- Pressing E on the thing you are talking to advances it
  (Dialogue.request_advance()). A conversation with no NPC needs a script that
  calls request_advance() itself, as KnowsAllArena does.


PUZZLES
-------

Puzzle is the base class. Every puzzle has a puzzle_id and reports
GameState.mark_solved(puzzle_id) when solved.

- start(), reset(), complete(), fail().
- Signals: solved, failed.
- Override _on_start() and _on_reset().

Built:
- PuddlePuzzle (id puddle): test rocks, reach the goal. Story mode
  rigged_to_lose makes the player lose on purpose.
- HidingPuzzle (id hiding): sneak past patrol guards to the exit.
- WordPuzzle (id town_hall_word): unscramble a word (Level 1, optional).
- EggPuzzle (draft): take real eggs, fake ones fail it. Draft until the
  designers confirm the spec.

Test scenes: puddle_test.tscn, hiding_test.tscn, egg_test.tscn.


PuddlePuzzle story mode
-----------------------

With rigged_to_lose on, the player always loses and
GameState.finish_pond_loss(lose_scene_path, lose_level, lose_stage) runs. It
sets the pond_lost flag and moves the game to that level and corruption stage.


HidingPuzzle
------------

- Exports: guards_parent, exit_marker, start_marker, exit_radius, caught_text,
  caught_delay, fade_time, auto_start.
- Being seen fades out, shows a message and restarts the puzzle. Reaching the
  exit solves it and sets hid_from_villagers.
- Helpers: PatrolGuard (patrol_offset, speed, a vision cone, signal spotted)
  and HidingSpot (press E to hide or leave, is_hiding).


WordPuzzle (town hall)
----------------------

An optional side puzzle that never blocks the quest. The game pauses while it
is open and Esc closes it.

1. Add a WordPuzzle node to the scene.
2. Add a PuzzleTrigger (Area2D, Layer 2, Mask empty, with a collision shape).
3. Drag the puzzle into the trigger's Puzzle slot.
4. Fill in answer, clue, title_text, solved_message, wrong_message.

The trigger disables itself once the puzzle is solved. The Level 1 one is
WordBoard in townhall_interior.tscn.


ACTIVITIES
----------

Activity is the base for cozy activities: start(), finish(result), signals
started and finished.

  FarmManager + FarmPlot -> FarmPlot interactable. Plant, water, grow,
                            harvest. end_day() advances plots.
  Fishing                -> FishingSpot. Cast, wait, reel in on the bite.
  Shop                   -> ShopCounter. Sells farm harvests and fish for
                            gold.
  Treehouse              -> TreehouseBed. Sleep to end the day.
  TownSquare             -> NoticeBoard. Reads a daily announcement.

Pattern: the logic lives in a child Node (Fishing, Shop, Treehouse,
TownSquare) and the Interactable draws placeholder art and handles E.
The Interactable looks for the child by name, so don't rename it.

Wiring: ShopCounter has farm_manager_path and fishing_spot_path,
TreehouseBed has farm_manager_path. Set these in the scene they are used in.


COMBAT
------

PlayerCombat (a child of the Player): Space or J attacks, Shift dodges.

- Exports include max_hearts, attack_damage (default 1) and attack_reach.
- The player's attack hits anything in the group "enemy" that has
  take_hit(damage, from_pos) (and optionally hit_radius).
- Enemies hurt the player with
  player.get_node("PlayerCombat").take_damage(1, global_position).
- CombatHUD shows the hearts and the boss health bar.


KNOWS ALL (LEVEL 4 BOSS)
------------------------

Scripts:
- KnowsAllBoss: health, 3 phases, attack picking, intro and defeat.
- KnowsAllTentacle: one telegraphed strike, a slam on a circle or a bar
  across the arena.
- KnowsAllArena: fenced arena, fade, intro, HUD, try-again, ending
  transition.
- knows_all_test.gd: test driver for levels/knows_all_test.tscn.

Start the fight from a level script with one line:

    KnowsAllArena.start(self, player, Rect2(top_left, Vector2(360, 240)),
        "res://path/to/ending.tscn")

The rect is the arena's walkable area in world coordinates. The ending path
is optional. The arena emits won(at) when the boss dies and sets the
knows_all_defeated flag.

Flow: fade out, place the fighters, Knows All rises, the intro dialogue plays
(dialogues/knows_all_intro.tres, press E to advance), then "FIGHT!". If the
player dies: "TRY AGAIN" and the fight restarts. On defeat: death sequence,
then the ending scene.

Phases (24 health, max_hp export; they change at 66% and 33% health):
1. Single and double slams.
2. Triple slams and sweeping bars across the arena.
3. Fast slam chains, double bars and a shockwave ring (dodge-roll through it).

Every attack shows a purple warning on the floor first.

- Items: with GameState.has_item(&"sword") the player does 2 damage per hit
  and has a little more reach (sword_damage export on the arena).
- Art: art/knows_all/walk/<direction>/frame_000.png ... 8 directions (east,
  south-east, south, south-west, west, north-west, north, north-east). The
  boss faces the player. sprite_scale and walk_fps are exports on the boss.
  With no art there, a code-drawn placeholder is used.
- The level scene needs dialogue_box.tscn (the intro hangs without it), a
  Camera2D on the player and the player's facing property. If the player
  already has a PlayerCombat, the arena reuses it and refills its hearts.
- Testing: open levels/knows_all_test.tscn, set Player Scene to player.tscn,
  tick Give Sword to try the sword, press F6.


GAMESTATE HOOKS
---------------

  get_flag(name), set_flag(name, value)  - story flags
  mark_solved(id), is_solved(id)         - puzzle progress
  add_item(id), has_item(id)             - items (ids are StringName, e.g.
                                           &"sword")
  finish_pond_loss(path, level, stage)   - record the pond loss and change
                                           scene

Story flags: note_read, slept, cat_dead, baker_confronted, hid_from_villagers,
pond_lost. The Knows All fight also sets knows_all_defeated.


CONTROLS AND DEBUG KEYS
-----------------------

  E        - interact, advance dialogue
  Space/J  - attack (combat only)
  Shift    - dodge (combat only)

Debug keys (debug builds only):
  N  - farm_manager.gd: skip a day (clashes with the notes action, also N)
  K  - pet_cat.gd: toggle the cat_dead flag
  F3 - Level 3 quest script: skip Level 3


TROUBLESHOOTING
---------------

- The E prompt never shows: the Area2D is on Layer 1. Set Layer 2 only, Mask
  empty.
- Dialogue never appears or advances: no dialogue_box.tscn in the scene, or
  nothing calls Dialogue.request_advance().
- Member "hidden" redefined: don't name a variable hidden in an Area2D
  script. Use is_hiding.
- Boss fight shows a tiny corner of the arena: the scene has no active
  Camera2D on the player.
- Sword does the same damage: PlayerCombat has no attack_damage, or
  add_item(&"sword") was never called.


KNOWN GAPS
----------

- The treehouse and town square are placeholders: the GDD doesn't define
  them.
- Prices, fish and crops are placeholder values.
- The farm and treehouse bed use GameState.advance_day() and
  GameState.current_day. If those aren't on main yet, they quietly fall back
  to simpler behavior.
- The Knows All fight has no sound effects yet.
- Knows All has a walk animation only: no attack or hit animation yet.
- Only the sword has an effect in the boss fight. Other maze items need
  effects added.


TEST SCENES
-----------

test_main, egg_test, fishing_test, shop_test, square_test, puddle_test,
hiding_test, knows_all_test. Run the open scene with F6.
