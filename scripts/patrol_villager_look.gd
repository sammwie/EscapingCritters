class_name PatrolVillagerLook
extends NPCLook
## NPCLook for a PatrolGuard: the villager sprite turns with the guard's
## walking direction (where its vision cone points) instead of toward the player.

var _guard: PatrolGuard

func _ready() -> void:
	face_player = false
	super()
	_guard = get_parent() as PatrolGuard

func _process(_delta: float) -> void:
	if _guard == null:
		return
	var index := wrapi(roundi(_guard.facing.angle() / (PI / 4.0)), 0, 8)
	set_facing(DIRS[index])
