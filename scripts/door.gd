class_name Door
extends Interactable
## A door that can be locked. Emits signals so levels decide what happens.
## Optionally changes scene when opened (set target_scene to a .tscn path).
## Scene: Area2D (this script) > Sprite2D + CollisionShape2D. Layer 2, mask empty.

signal opened
signal bumped_locked

@export var locked := false
@export_file("*.tscn") var target_scene := ""
@export var locked_message := "It's locked."

func _ready() -> void:
	prompt_text = "Open"

func _on_interact(_by: Node) -> void:
	if locked:
		bumped_locked.emit()
		return
	opened.emit()
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)

func unlock() -> void:
	locked = false

func lock() -> void:
	locked = true
