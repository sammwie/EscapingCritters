extends Node
## Shared sound playback for gameplay and interface effects.

const SOUNDS := {
	"jump": "jump_sound.mp3",
	"dash": "horror_wind_scary_search_minigame.mp3",
	"outdoor_footsteps": "outdoor_footstep.mp3",
	"indoor_left_foot": "indoor_left_foot.mp3",
	"indoor_right_foot": "indoor_right_foot.mp3",
	"open_any_note": "open_any_note.mp3",
	"open_door": "open_door_entering_building.mp3",
	"pickup_note_L1": "pickup_note_L1.mp3",
	"item_pickup": "item_pickup_any_level.mp3",
	"egg_crack": "egg_crack_horror_egg_collection.mp3",
	"menu_select": "menu_select_item.mp3",
	"menu_cycle": "menu_cycle_buttons.mp3",
	"dialogue": "dialogue_text_blip.mp3",
	"dialogue_loop": "better_dialogue_text_blip_loop.mp3",
	"butcher_speaking": "butcher_when_talking.mp3",
	"butcher_death": "butcher_death_grunt.mp3",
	"cat_1": "cat_meow_1.mp3",
	"cat_2": "cat_meow_2.mp3",
	"chicken_coop": "chicken_coop.mp3",
	"pond_crossing": "crossing_pond_minigame.mp3",
	"pond_water": "flowing_water_near_pond.mp3",
	"fall_in_pond": "fall_in_pond.mp3",
	"walls": "walls_closing_in.mp3",
	"scary": "scary_sudden_sound.mp3",
	"scary_search": "scary_bg_ambience_during_search_minigame.mp3",
	"horror_wind": "horror_wind_scary_search_minigame.mp3",
	"horror_2": "horror_sfx_2.mp3",
	"glitch": "glitch_sfx.mp3",
	"egg_glitch": "glitch_when_egg_breaks.mp3",
	"butcher_charge": "fight_wind_charge_butcher.mp3",
	"butcher_hit": "fighting_butcher_hitting_him.mp3",
	"cozy_level_1": "cozy_background_lvl1_loop.mp3",
	"opening_music": "opening_screen_music.mp3",
	"night_ambience": "horro_ambience_2.mp3",
	"horror_ambience": "horro_ambience_2.mp3",
	"pond_night_ambience": "pond_ambience.mp3",
}

var _loops: Dictionary = {}
var _indoor_filter := AudioEffectLowPassFilter.new()
var _music_bus := -1
var _ambience_bus := -1
var _music_fraction := 1.0
var _ambience_fraction := 0.0
var _indoor_music := false

func _ready() -> void:
	_ambience_bus = _ensure_bus("Ambience")

func play(sound_name: String, loop := false, start_offset := 0.0) -> AudioStreamPlayer:
	if not SOUNDS.has(sound_name):
		return null
	if loop:
		var existing := _loops.get(sound_name) as AudioStreamPlayer
		if is_instance_valid(existing):
			return existing
	var stream := load("res://sfx/" + SOUNDS[sound_name]) as AudioStream
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Music" if sound_name in ["cozy_level_1", "opening_music"] else "Ambience" if _is_ambience(sound_name) else "SFX"
	if sound_name == "outdoor_footsteps":
		player.volume_db = -3.0
	elif sound_name == "opening_music":
		player.volume_db = 4.0
	elif sound_name in ["indoor_left_foot", "indoor_right_foot"]:
		player.volume_db = -1.0
	elif sound_name == "chicken_coop":
		player.volume_db = 5.0
	elif sound_name in ["butcher_charge", "butcher_hit", "butcher_speaking", "butcher_death"]:
		player.volume_db = 8.0
	elif sound_name == "horror_2":
		player.volume_db = -5.0
	elif sound_name == "horror_wind":
		player.volume_db = -10.0
	player.stream.loop = loop
	add_child(player)
	player.play(start_offset)
	if loop:
		_loops[sound_name] = player
	else:
		player.finished.connect(player.queue_free)
	return player

func play_limited(sound_name: String, duration: float) -> void:
	var player := play(sound_name)
	if player == null:
		return
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	)

func set_indoor_music(indoor: bool) -> void:
	_indoor_music = indoor
	_music_bus = AudioServer.get_bus_index("Music")
	if _music_bus == -1:
		return
	var has_filter := false
	for index in AudioServer.get_bus_effect_count(_music_bus):
		if AudioServer.get_bus_effect(_music_bus, index) is AudioEffectLowPassFilter:
			AudioServer.set_bus_effect_enabled(_music_bus, index, indoor)
			has_filter = true
	if not has_filter:
		_indoor_filter.cutoff_hz = 1800.0
		AudioServer.add_bus_effect(_music_bus, _indoor_filter)
		AudioServer.set_bus_effect_enabled(_music_bus, AudioServer.get_bus_effect_count(_music_bus) - 1, indoor)
	_update_mix_buses()

func set_level_mix(level: int, night := false) -> void:
	var music_fraction := 1.0 if level <= 1 else 0.5 if level == 2 else 0.15
	var ambience_fraction := 0.0 if level <= 1 else 0.5 if level == 2 else 0.85
	if night or level >= 4:
		music_fraction = 0.0
		ambience_fraction = 1.0
	if level >= 4:
		stop("cozy_level_1")
		stop("opening_music")
	if level <= 1:
		for sound_name in ["horror_ambience", "night_ambience", "scary_search", "horror_wind", "pond_night_ambience", "pond_water", "pond_crossing"]:
			stop(sound_name)
	_music_fraction = music_fraction
	_ambience_fraction = ambience_fraction
	_update_mix_buses()

func set_fight_mix() -> void:
	_music_fraction = 0.3
	_ambience_fraction = 0.7
	_update_mix_buses()

func set_sfx_volume() -> void:
	_update_mix_buses()

func _update_mix_buses() -> void:
	var music_level := float(GameSettings.get_value("music")) * _music_fraction
	var indoor_multiplier := 0.56 if _indoor_music else 1.0
	var music_index := _ensure_bus("Music")
	var music_volume := music_level * indoor_multiplier
	AudioServer.set_bus_volume_db(music_index, linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_mute(music_index, music_volume <= 0.001)
	var ambience_volume := float(GameSettings.get_value("sfx")) * _ambience_fraction
	var ambience_index := _ensure_bus("Ambience")
	AudioServer.set_bus_volume_db(ambience_index, linear_to_db(maxf(ambience_volume, 0.0001)))
	AudioServer.set_bus_mute(ambience_index, ambience_volume <= 0.001)

func _ensure_bus(bus_name: String) -> int:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		return bus_index
	AudioServer.add_bus()
	bus_index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")
	return bus_index

func _is_ambience(sound_name: String) -> bool:
	return sound_name in ["horror_ambience", "night_ambience", "pond_night_ambience", "scary_search", "horror_wind", "pond_water", "pond_crossing"]

func stop(sound_name: String) -> void:
	var player := _loops.get(sound_name) as AudioStreamPlayer
	if player:
		player.stop()
		player.queue_free()
	_loops.erase(sound_name)

func stop_all_loops() -> void:
	for sound_name in _loops.keys():
		stop(sound_name)
