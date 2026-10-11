class_name LyingObject
extends Interactable
## "Objects that lie about themselves": cracked eggs, tricked rocks, etc.
## Looks ordinary until interacted with; then reveals its true nature.

@export var is_safe := true
@export var reveal_text := ""

signal revealed(safe: bool)

func _on_interact(_by: Node) -> void:
	revealed.emit(is_safe)
	_play_reveal()

func _play_reveal() -> void:
	pass # override: crack the egg, sink the rock, play SFX, etc.
