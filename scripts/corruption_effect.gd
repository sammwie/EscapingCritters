extends CanvasLayer
## Instance once in a gameplay scene. Place HUD layers above this layer.

@onready var overlay: ColorRect = $Overlay


func _ready() -> void:
	GameState.corruption_changed.connect(_apply_stage)
	_apply_stage(GameState.corruption_stage)


func _apply_stage(stage: int) -> void:
	# Hide the pass entirely at stage 0 so the original colors are preserved.
	overlay.visible = stage >= 1
