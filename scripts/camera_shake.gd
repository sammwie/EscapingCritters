class_name CameraShake
extends RefCounted
## One-liner screen shake: CameraShake.go(camera, strength, seconds).

static func go(camera: Camera2D, strength := 3.0, duration := 0.3) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var tween := camera.create_tween()
	var steps := maxi(int(duration / 0.03), 1)
	for i in steps:
		var falloff := 1.0 - float(i) / float(steps)
		var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * falloff
		tween.tween_property(camera, "offset", off, 0.03)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)
