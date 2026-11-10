class_name SceneDoor
extends Door
## A Door that remembers where to put the player in the next scene.
## Set target_scene to the scene to load and spawn_at to the name of a
## Marker2D in that scene. The player script moves itself there on load.
## Doors that lead to the village are rerouted through StoryRouter, so they
## open onto the day 3 or night map once the story gets there.

@export var spawn_at := ""
@export var label := "Enter"

func _ready() -> void:
	super()
	prompt_text = label

func _on_interact(_by: Node) -> void:
	if locked:
		bumped_locked.emit()
		return
	opened.emit()
	SFX.play("open_door")
	if target_scene != "":
		var path := target_scene
		if StoryRouter.is_village(path):
			path = StoryRouter.village_path()
		# Wait a frame so the Interactor finishes its input handling first.
		GameState.change_scene.call_deferred(path, spawn_at)
