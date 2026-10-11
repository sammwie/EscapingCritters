extends CharacterBody2D
## Placeholder top-down player. Freezes while dialogue is open.

@export var speed := 120.0

func _physics_process(_delta: float) -> void:
	if Dialogue.active:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()
