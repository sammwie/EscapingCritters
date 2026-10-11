class_name Interactor
extends Area2D
## Add as a child of the Player (with a CollisionShape2D).
## Needs an "interact" action in the Input Map.
## Interactables live on collision layer 2; this Area2D's mask = 2.
##
## Emits target_changed whenever the closest interactable in range changes,
## so UI (like the "Press E" prompt) can react without polling.

signal target_changed(target: Interactable)

var nearby: Array[Interactable] = []
var current_target: Interactable = null

func _ready() -> void:
	add_to_group("interactor")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area2D) -> void:
	if area is Interactable:
		nearby.append(area)

func _on_area_exited(area: Area2D) -> void:
	nearby.erase(area)

func _process(_delta: float) -> void:
	var best := _closest()
	if best != current_target:
		current_target = best
		target_changed.emit(current_target)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target:
		current_target.interact(get_parent())
		get_viewport().set_input_as_handled()

func _closest() -> Interactable:
	var best: Interactable = null
	var best_dist := INF
	for i in nearby:
		if not is_instance_valid(i) or not i.enabled:
			continue
		var d := global_position.distance_squared_to(i.global_position)
		if d < best_dist:
			best_dist = d
			best = i
	return best
