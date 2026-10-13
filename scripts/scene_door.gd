class_name SceneDoor
extends Door
## A Door that remembers where to put the player in the next scene.
## Set target_scene to the scene to load and spawn_at to the name of a
## Marker2D in that scene. The player script moves itself there on load.

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
	if target_scene != "":
		get_tree().root.set_meta("spawn_at", spawn_at)
		# Wait a frame so the Interactor finishes its input handling first.
		get_tree().change_scene_to_file.call_deferred(target_scene)
