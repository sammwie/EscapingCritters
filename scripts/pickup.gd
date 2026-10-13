class_name Pickup
extends Interactable
## Something you can pick up (egg, seed, key...). Disappears when taken and
## emits picked_up so whatever owns the inventory can react.
## Scene: Area2D (this script) > Sprite2D + CollisionShape2D. Layer 2, mask empty.

signal picked_up(item_id: StringName)

@export var item_id: StringName = &""
@export var amount := 1

func _ready() -> void:
	prompt_text = "Pick up"

func _on_interact(_by: Node) -> void:
	enabled = false
	picked_up.emit(item_id)
	queue_free()
