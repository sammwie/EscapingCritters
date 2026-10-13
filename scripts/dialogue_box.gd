extends CanvasLayer
## Scene: CanvasLayer > PanelContainer > VBoxContainer > [Label "SpeakerLabel", Label "TextLabel"]
## "Access as Unique Name" must be on for both labels.
## Typewriter effect: the line types out; skipping reveals the full line.

@export var chars_per_second := 40.0

@onready var panel: Control = $PanelContainer
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: Label = %TextLabel

var _tween: Tween = null

func _ready() -> void:
	panel.hide()
	Dialogue.line_shown.connect(_on_line_shown)
	Dialogue.finished.connect(_on_finished)
	Dialogue.skip_typing.connect(_finish_typing)

func _on_line_shown(speaker: String, text: String) -> void:
	panel.show()
	speaker_label.text = speaker
	text_label.text = text
	text_label.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	var duration := maxf(text.length() / (chars_per_second * GameSettings.text_speed_multiplier()), 0.05)
	Dialogue.line_typing = true
	_tween = create_tween()
	_tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	_tween.finished.connect(_on_typing_done)

func _finish_typing() -> void:
	if _tween:
		_tween.kill()
	text_label.visible_ratio = 1.0
	_on_typing_done()

func _on_typing_done() -> void:
	Dialogue.line_typing = false

func _on_finished() -> void:
	if _tween:
		_tween.kill()
	Dialogue.line_typing = false
	panel.hide()
