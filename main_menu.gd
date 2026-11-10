extends Control

@export var new_game_scene_path := "res://scenes/test_main.tscn"
@export var continue_scene_path := "res://scenes/test_main.tscn"

func _ready() -> void:
	# Apply saved volume / fullscreen / text-speed options as soon as the game starts.
	GameSettings.load_and_apply()
	SFX.set_level_mix(1)
	SFX.play("opening_music", true)

	$ButtonList/NewGameButton.pressed.connect(_on_new_game_pressed)
	$ButtonList/ContinueButton.pressed.connect(_on_continue_pressed)
	$ButtonList/SettingsButton.pressed.connect(_on_settings_pressed)
	$ButtonList/CreditsButton.pressed.connect(_on_credits_pressed)
	for button in $ButtonList.get_children():
		if button is Button:
			button.mouse_entered.connect(func() -> void: SFX.play("menu_cycle"))
			button.pressed.connect(func() -> void: SFX.play("menu_select"))

	# Disable Continue if there is no save yet.
	$ButtonList/ContinueButton.disabled = not FileAccess.file_exists("user://save.dat")

func _on_new_game_pressed() -> void:
	SFX.stop("opening_music")
	get_tree().change_scene_to_file(new_game_scene_path)

func _on_continue_pressed() -> void:
	SFX.stop("opening_music")
	get_tree().change_scene_to_file(continue_scene_path)

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://settings.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://credits.tscn")
