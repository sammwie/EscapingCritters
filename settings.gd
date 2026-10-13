extends Control
## Settings page. Every control writes straight into GameSettings (which applies
## and saves it), so there is no separate "Apply" step.

const MENU_SCENE := "res://main_menu.tscn"

@onready var sliders := {
	"master": %MasterSlider,
	"music": %MusicSlider,
	"sfx": %SfxSlider,
}
@onready var value_labels := {
	"master": %MasterValue,
	"music": %MusicValue,
	"sfx": %SfxValue,
}
@onready var speed_buttons: Array[Button] = [%SlowButton, %NormalButton, %FastButton]

func _ready() -> void:
	for key in sliders:
		var slider: HSlider = sliders[key]
		slider.value_changed.connect(_on_slider_changed.bind(key))
		slider.drag_ended.connect(func(_changed: bool) -> void: GameSettings.save())
	%FullscreenButton.toggled.connect(_on_fullscreen_toggled)
	for i in speed_buttons.size():
		speed_buttons[i].pressed.connect(_on_speed_pressed.bind(i))
	%BackButton.pressed.connect(_on_back_pressed)
	%ResetButton.pressed.connect(_on_reset_pressed)
	_load_into_controls()
	%BackButton.grab_focus()

# Pull the current values into the controls without triggering saves.
func _load_into_controls() -> void:
	for key in sliders:
		var slider: HSlider = sliders[key]
		slider.set_value_no_signal(float(GameSettings.get_value(key)))
		_update_value_label(key)
	%FullscreenButton.set_pressed_no_signal(bool(GameSettings.get_value("fullscreen")))
	_update_fullscreen_text()
	speed_buttons[clampi(int(GameSettings.get_value("text_speed")), 0, 2)].set_pressed_no_signal(true)
	_play_preview()

func _on_slider_changed(value: float, key: String) -> void:
	GameSettings.set_value(key, value)
	_update_value_label(key)

func _update_value_label(key: String) -> void:
	var slider: HSlider = sliders[key]
	var label: Label = value_labels[key]
	label.text = "%d%%" % roundi(slider.value * 100.0)

func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.set_value("fullscreen", pressed)
	GameSettings.save()
	_update_fullscreen_text()

func _update_fullscreen_text() -> void:
	%FullscreenButton.text = "ON" if %FullscreenButton.button_pressed else "OFF"

func _on_speed_pressed(index: int) -> void:
	GameSettings.set_value("text_speed", index)
	GameSettings.save()
	_play_preview()

# Types the sample line at the chosen speed so the player can feel the difference.
func _play_preview() -> void:
	var label: Label = %Preview
	label.visible_ratio = 0.0
	var duration := label.text.length() / (40.0 * GameSettings.text_speed_multiplier())
	var tween := create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, duration)

func _on_reset_pressed() -> void:
	GameSettings.reset_to_defaults()
	_load_into_controls()

func _on_back_pressed() -> void:
	GameSettings.save()
	get_tree().change_scene_to_file(MENU_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
