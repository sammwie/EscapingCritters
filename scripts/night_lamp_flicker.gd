extends Node2D

enum FlickerStage { WAITING, OFF_PULSE, ON_PULSE, LONG_OFF }

var _lights: Array[PointLight2D] = []
var _rngs: Array[RandomNumberGenerator] = []
var _base_energy: Array[float] = []
var _phase: Array[float] = []
var _stage: Array[int] = []
var _stage_timer: Array[float] = []
var _pulses_left: Array[int] = []
var _next_pattern: Array[float] = []
var _elapsed := 0.0

func _ready() -> void:
	for child in get_children():
		var light := child as PointLight2D
		if light == null:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = randi() ^ light.get_instance_id()
		_lights.append(light)
		_rngs.append(rng)
		_base_energy.append(light.energy)
		_phase.append(rng.randf_range(0.0, TAU))
		_stage.append(FlickerStage.WAITING)
		_stage_timer.append(0.0)
		_pulses_left.append(0)
		_next_pattern.append(rng.randf_range(0.5, 8.0))

func _process(delta: float) -> void:
	_elapsed += delta
	for index in _lights.size():
		var light := _lights[index]
		if not is_instance_valid(light):
			continue
		var rng := _rngs[index]
		if _stage[index] == FlickerStage.WAITING:
			_next_pattern[index] -= delta
			if _next_pattern[index] > 0.0:
				light.energy = _lit_energy(index)
				continue
			_pulses_left[index] = rng.randi_range(1, 4)
			_stage[index] = FlickerStage.OFF_PULSE
			_stage_timer[index] = rng.randf_range(0.04, 0.2)
			light.energy = 0.0
			continue

		_stage_timer[index] -= delta
		if _stage_timer[index] > 0.0:
			light.energy = _lit_energy(index) if _stage[index] == FlickerStage.ON_PULSE else 0.0
			continue

		match _stage[index]:
			FlickerStage.OFF_PULSE:
				_stage[index] = FlickerStage.ON_PULSE
				_stage_timer[index] = rng.randf_range(0.04, 0.24)
				light.energy = _lit_energy(index)
			FlickerStage.ON_PULSE:
				_pulses_left[index] -= 1
				if _pulses_left[index] > 0:
					_stage[index] = FlickerStage.OFF_PULSE
					_stage_timer[index] = rng.randf_range(0.04, 0.2)
				else:
					_stage[index] = FlickerStage.LONG_OFF
					_stage_timer[index] = rng.randf_range(0.3, 1.0)
				light.energy = 0.0
			FlickerStage.LONG_OFF:
				_stage[index] = FlickerStage.WAITING
				_next_pattern[index] = rng.randf_range(2.0, 9.0)
				light.energy = _lit_energy(index)

func _lit_energy(index: int) -> float:
	var phase := _phase[index]
	var flutter := 0.018 * sin(_elapsed * 2.3 + phase) \
			+ 0.008 * sin(_elapsed * 5.1 + phase * 1.7)
	return _base_energy[index] * (1.0 + flutter)
