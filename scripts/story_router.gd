class_name StoryRouter
extends RefCounted
## Decides which version of the village the player should be in right now.
## SceneDoor asks this whenever a door leads to the village, so every
## interior exit (house, bakery, butcher, town hall) lands on the right map
## without each door needing its own logic.
##
## Swap the paths below when the designers deliver the real day and night maps.

const VILLAGE := "res://scenes/test_main.tscn"
const VILLAGE_DAY3 := "res://scenes/maps/village_day3.tscn"   # the changed day-time map
const VILLAGE_NIGHT := "res://scenes/maps/village_night.tscn" # the night-time map (hiding puzzle)
const POND := "res://levels/puddle_level.tscn"
const KNOWS_ALL := "res://scenes/maps/knows_all.tscn"

## True for any path that means "the village", so doors can be rerouted.
static func is_village(path: String) -> bool:
	return path in [VILLAGE, VILLAGE_DAY3, VILLAGE_NIGHT]

## The village scene that matches the current point in the story.
static func village_path() -> String:
	if GameState.current_level >= 3:
		if Level3Quest.stage >= Level3Quest.Stage.SNEAK:
			return VILLAGE_NIGHT
		if Level3Quest.stage >= Level3Quest.Stage.ASK_BAKER:
			return VILLAGE_DAY3
	return VILLAGE
