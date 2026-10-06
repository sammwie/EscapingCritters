class_name Interactor
extends Area2D
## Add as a child of the Player (with a CollisionShape2D).
## Needs an "interact" action in Project Settings > Input Map.
## Set Interactable collision layer = 2, and this Area2D's mask = 2.

var nearby: Array[Interactable] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		nearby.append(area)

func _on_area_exited(area: Area2D) -> void:
	nearby.erase(area)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target := _closest()
		if target:
			target.interact(get_parent())
			get_viewport().set_input_as_handled()

func _closest() -> Interactable:
	var best: Interactable = null
	var best_dist := INF
	for i in nearby:
		if not i.enabled:
			continue
		var d := global_position.distance_squared_to(i.global_position)
		if d < best_dist:
			best_dist = d
			best = i
	return best
