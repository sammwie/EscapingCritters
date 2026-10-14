class_name CombatInput
extends RefCounted
## Makes sure the Level 2 controls exist without touching project.godot.
## attack = Space or J, dodge = Shift, notes = N.
## To rebind them later, add actions with these names in Project Settings >
## Input Map and this script will leave them alone.

static func ensure() -> void:
	_add("attack", [KEY_SPACE, KEY_J])
	_add("dodge", [KEY_SHIFT])
	_add("notes", [KEY_N])

static func _add(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
