class_name GameSettings
extends RefCounted
## Player options, saved to user://settings.cfg.
## Static helper (no autoload needed): call GameSettings.load_and_apply() once at
## start-up (main_menu.gd does this) and the Settings page edits it.
##
## Music and SFX get their own audio buses ("Music", "SFX"), created on demand.
## When you add sounds later, set their Bus to "Music" or "SFX" so the sliders work.

const PATH := "user://settings.cfg"
const TEXT_SPEEDS := [0.6, 1.0, 1.8]  # Slow, Normal, Fast (multiplies typing speed)

const DEFAULTS := {
	"master": 0.8,
	"music": 0.7,
	"sfx": 0.8,
	"fullscreen": false,
	"text_speed": 1,
}

static var values: Dictionary = DEFAULTS.duplicate()
static var _loaded := false

static func load_and_apply() -> void:
	values = DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for key in DEFAULTS:
			if cfg.has_section_key("settings", key):
				values[key] = cfg.get_value("settings", key)
	_loaded = true
	apply_all()

static func save() -> void:
	var cfg := ConfigFile.new()
	for key in values:
		cfg.set_value("settings", key, values[key])
	cfg.save(PATH)

static func get_value(key: String) -> Variant:
	if not _loaded:
		load_and_apply()
	return values.get(key, DEFAULTS[key])

static func set_value(key: String, value: Variant) -> void:
	values[key] = value
	apply(key)

static func reset_to_defaults() -> void:
	values = DEFAULTS.duplicate()
	apply_all()
	save()

static func apply_all() -> void:
	for key in DEFAULTS:
		apply(key)

static func apply(key: String) -> void:
	match key:
		"master":
			_set_bus_volume("Master", float(values["master"]))
		"music":
			_set_bus_volume("Music", float(values["music"]))
		"sfx":
			_set_bus_volume("SFX", float(values["sfx"]))
		"fullscreen":
			var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
			DisplayServer.window_set_mode(mode)

# How much faster/slower dialogue text types out. Used by dialogue_box.gd.
static func text_speed_multiplier() -> float:
	var index := clampi(int(get_value("text_speed")), 0, TEXT_SPEEDS.size() - 1)
	return TEXT_SPEEDS[index]

static func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.001)
