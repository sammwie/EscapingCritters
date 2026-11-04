class_name CorruptionScreen
extends CanvasLayer
## Full-screen pixelation and color shift for corrupted maps (GDD Level 2:
## "colors shift, the game appears to lose resolution", permanently).
## Level3Quest adds one to the day 3, night and pond maps. Raise it with
## step_to(); it never steps back down, since corruption is permanent.
##     CorruptionScreen.ensure(scene).step_to(6.0, 0.35)

const SHADER := preload("res://pixel_corrupt.gdshader")

var _mat: ShaderMaterial
var _pixel := 1.0
var _desat := 0.0

static func ensure(scene: Node) -> CorruptionScreen:
	var existing := scene.get_node_or_null("CorruptionScreen") as CorruptionScreen
	if existing:
		return existing
	var screen := CorruptionScreen.new()
	screen.name = "CorruptionScreen"
	scene.add_child(screen)
	return screen

func _init() -> void:
	layer = 1  # above the world (layer 0), below every UI layer
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	rect.material = _mat
	add_child(rect)
	_apply()

## Moves toward a stronger look over `time` seconds. Weaker values are ignored.
func step_to(pixel_size: float, desaturate: float, grade := Color(1, 1, 1), time := 0.0) -> void:
	var target_pixel := maxf(_pixel, pixel_size)
	var target_desat := maxf(_desat, desaturate)
	_mat.set_shader_parameter("grade", Vector3(grade.r, grade.g, grade.b))
	_mat.set_shader_parameter("color_levels", 24.0 if target_pixel > 1.0 else 256.0)
	if time <= 0.0 or not is_inside_tree():
		_pixel = target_pixel
		_desat = target_desat
		_apply()
		return
	var start_pixel := _pixel
	var start_desat := _desat
	var tw := create_tween()
	tw.tween_method(func(t: float) -> void:
		_pixel = lerpf(start_pixel, target_pixel, t)
		_desat = lerpf(start_desat, target_desat, t)
		_apply(), 0.0, 1.0, time)

func _apply() -> void:
	_mat.set_shader_parameter("pixel_size", _pixel)
	_mat.set_shader_parameter("desaturate", _desat)
