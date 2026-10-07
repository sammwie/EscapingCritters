extends CanvasLayer
## Scene: CanvasLayer > PanelContainer > VBoxContainer > [Label "SpeakerLabel", Label "TextLabel"]
## Enable "Access as Unique Name" (right-click) on both labels.

@onready var panel: Control = $PanelContainer
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: Label = %TextLabel

func _ready() -> void:
	panel.hide()
	Dialogue.line_shown.connect(_on_line_shown)
	Dialogue.finished.connect(panel.hide)

func _on_line_shown(speaker: String, text: String) -> void:
	panel.show()
	speaker_label.text = speaker
	text_label.text = text
