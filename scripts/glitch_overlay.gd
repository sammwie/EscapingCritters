class_name GlitchOverlay
extends CanvasLayer
## Full-screen glitch effect. Add this scene to a level, then control it from
## anywhere with:
##   get_tree().call_group("glitch_overlay", "turn_on")
##   get_tree().call_group("glitch_overlay", "turn_off")
##   get_tree().call_group("glitch_overlay", "flicker")
##   get_tree().call_group("glitch_overlay", "set_intensity", 0.5)

## If true, the effect is on as soon as the scene loads.
@export var start_on := false
## How strong the effect is when "on" (0.0 to 1.0).
@export_range(0.0, 1.0) var on_intensity := 1.0

var _rect: ColorRect
var _mat: ShaderMaterial
var _level := 0.0        # the resting intensity
var _tween: Tween

func _ready() -> void:
	add_to_group("glitch_overlay")
	for child in get_children():
		if child is ColorRect:
			_rect = child
			break
	if _rect == null or not (_rect.material is ShaderMaterial):
		push_warning("GlitchOverlay: needs a ColorRect child with a ShaderMaterial.")
		return
	_mat = _rect.material
	_apply(on_intensity if start_on else 0.0)

func turn_on(fade_time := 0.0) -> void:
	_go_to(on_intensity, fade_time)

func turn_off(fade_time := 0.0) -> void:
	_go_to(0.0, fade_time)

func set_intensity(value: float) -> void:
	_kill_tween()
	_apply(clampf(value, 0.0, 1.0))

## Short burst of glitching, then returns to whatever it was before.
func flicker(duration := 0.4, strength := 1.0) -> void:
	if _mat == null:
		return
	_kill_tween()
	_tween = create_tween()
	var steps := maxi(int(duration / 0.05), 1)
	for i in steps:
		_tween.tween_callback(_apply.bind(randf_range(0.3, 1.0) * strength, false))
		_tween.tween_interval(0.05)
	_tween.tween_callback(_apply.bind(_level))

func _go_to(target: float, fade_time: float) -> void:
	if _mat == null:
		return
	_kill_tween()
	if fade_time <= 0.0:
		_apply(target)
		return
	_rect.visible = true
	_tween = create_tween()
	_tween.tween_method(_apply.bind(false), _level, target, fade_time)
	_tween.tween_callback(_apply.bind(target))

## remember = true sets the resting level; false is just a temporary value.
func _apply(value: float, remember := true) -> void:
	if remember:
		_level = value
	_mat.set_shader_parameter("intensity", value)
	_rect.visible = value > 0.0

func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
