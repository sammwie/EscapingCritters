extends Node
## Run: godot --headless --path . res://tests/newgame_test.tscn
func _ready() -> void:
	get_parent().remove_child.call_deferred(self)
	get_tree().root.add_child.call_deferred(self)
	_run.call_deferred()
func _run() -> void:
	Level1Quest.stage = Level1Quest.Stage.DONE
	Level2Quest.stage = Level2Quest.Stage.DONE
	Level3Quest.stage = Level3Quest.Stage.SNEAK
	GameState.current_level = 3
	get_tree().root.set_meta("intro_played", true)
	get_tree().change_scene_to_file("res://main_menu.tscn")
	await get_tree().create_timer(0.5).timeout
	get_tree().current_scene._on_new_game_pressed()
	await get_tree().create_timer(1.0).timeout
	var ok := Level1Quest.stage == Level1Quest.Stage.TALK_BAKER and Level2Quest.stage == Level2Quest.Stage.INACTIVE and Level3Quest.stage == Level3Quest.Stage.INACTIVE and GameState.current_level == 1
	print(("PASS" if ok else "FAIL") + "  new game resets the story")
	get_tree().quit(0 if ok else 1)
