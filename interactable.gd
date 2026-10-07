class_name Interactable
extends Area2D
## Base class for anything the player can interact with:
## villagers, eggs, rocks, shop counters, etc. Extend and override _on_interact().

signal interacted(by: Node)

@export var prompt_text := "Interact"
@export var enabled := true

func interact(by: Node) -> void:
	if not enabled:
		return
	_on_interact(by)
	interacted.emit(by)

func _on_interact(_by: Node) -> void:
	pass # override in subclasses
