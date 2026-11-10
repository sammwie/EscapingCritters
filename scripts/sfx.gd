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
	"watering_plants": "watering_plants.mp3",
	"egg_crack": "egg_crack_horror_egg_collection.mp3",
	"menu_select": "menu_select_item.mp3",
	"menu_cycle": "menu_cycle_buttons.mp3",
	"menu_hover": "menu_cycle_buttons.mp3",
	"dialogue": "dialogue_text_blip.mp3",
	"dialogue_loop": "better_dialogue_text_blip_loop.mp3",
	"butcher_speaking": "butcher_when_talking.mp3",
	"butcher_death": "butcher_death_grunt.mp3",
	"fight_butcher": "fight_butcher.mp3",
	"cat_1": "cat_meow_1.mp3",
	"cat_2": "cat_meow_2.mp3",
	"chicken_coop": "chicken_coop.mp3",
	"chicken_coop_outside": "chicken_coop.mp3",
	"pond_crossing": "crossing_pond_minigame.mp3",
	"pond_water": "flowing_water_near_pond.mp3",
	"fall_in_pond": "fall_in_pond.mp3",
	"walls": "walls_closing_in.mp3",
	"village_chase": "village_chase.mp3",
	"level_2_done": "level_2_done.mp3",
	"level_3_done": "level_3_done.mp3",
	"scary": "scary_sudden_sound.mp3",
	"horror_wind": "horror_wind_scary_search_minigame.mp3",
	"horror_2": "horror_sfx_2.mp3",
	"glitch": "glitch_sfx.mp3",
	"egg_glitch": "glitch_when_egg_breaks.mp3",
	"butcher_charge": "fight_wind_charge_butcher.mp3",
	"butcher_hit": "fighting_butcher_hitting_him.mp3",
	"cozy_level_1": "cozy_background_lvl1_loop.mp3",
	"opening_music": "opening_screen_music.mp3",
	"night_ambience": "dark_horror_ambience.mp3",
	"day3_ambience": "scary_bg_ambience_during_search_minigame.mp3",
	"horror_ambience": "horro_ambience_2.mp3",
	"pond_ambience": "pond_ambience.mp3",
}

const STORY_AMBIENCE := ["horror_ambience", "day3_ambience", "night_ambience"]
const BUTCHER_AMBIENCE_FRACTION := 0.7

var _loops: Dictionary = {}
var _indoor_filter := AudioEffectLowPassFilter.new()
var _music_bus := -1
var _ambience_bus := -1
var _music_fraction := 1.0
var _ambience_fraction := 0.0
var _nightfall_gain := 1.0
var _quiet_night_sfx := false
var _indoor_music := false
var _wall_squeeze_active := false

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
		player.volume_db = -5.0
	elif sound_name == "opening_music":
		player.volume_db = 4.0
	elif sound_name == "menu_hover":
		player.volume_db = -10.0
	elif sound_name in ["indoor_left_foot", "indoor_right_foot"]:
		player.volume_db = -3.0
	elif sound_name in ["dialogue", "dialogue_loop"]:
		player.volume_db = -3.0
	elif sound_name == "open_any_note":
		player.volume_db = 12.0
	elif sound_name == "watering_plants":
		player.volume_db = -10.0
	elif sound_name == "walls":
		player.volume_db = -4.0
	elif sound_name == "fight_butcher":
		player.volume_db = -5.0
	elif sound_name == "day3_ambience":
		player.volume_db = -12.0
	elif sound_name in ["chicken_coop", "chicken_coop_outside"]:
		player.volume_db = -7.0 if GameState.current_level == 2 else 5.0
		if sound_name == "chicken_coop_outside":
			player.volume_db -= 16.0
	elif sound_name in ["butcher_charge", "butcher_hit", "butcher_speaking", "butcher_death"]:
		player.volume_db = 8.0
	elif sound_name == "horror_2":
		player.volume_db = -5.0
	elif sound_name == "horror_wind":
		player.volume_db = -24.0
	if _quiet_night_sfx and sound_name in [
		"outdoor_footsteps", "indoor_left_foot", "indoor_right_foot", "dialogue", "dialogue_loop",
	]:
		player.volume_db -= 4.0
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

func set_level_mix(level: int, night := false, ambience_enabled := true) -> void:
	var music_fraction := 1.0 if level <= 1 else 0.5 if level == 2 else 0.12
	var ambience_fraction := 0.0 if level <= 1 else 0.35 if level == 2 else 0.85
	if night or level >= 4:
		music_fraction = 0.0
		ambience_fraction = 1.0
	if level >= 4:
		stop("cozy_level_1")
		stop("opening_music")
	if level >= 2 and Level2Quest.stage >= Level2Quest.Stage.NOTE:
		music_fraction *= 0.1
	if level == 2 and Level2Quest.stage == Level2Quest.Stage.NOTE:
		ambience_fraction = BUTCHER_AMBIENCE_FRACTION
	_music_fraction = music_fraction
	_ambience_fraction = ambience_fraction if ambience_enabled else 0.0
	_nightfall_gain = 1.0
	_quiet_night_sfx = level == 3 and night
	_update_mix_buses()
	if _ambience_fraction > 0.0:
		var track := "night_ambience" if night else "day3_ambience" if level == 3 else "horror_ambience"
		for sound_name in STORY_AMBIENCE:
			if sound_name != track:
				stop(sound_name)
		play(track, true)
	else:
		for sound_name in _loops.keys():
			if _is_ambience(sound_name):
				stop(sound_name)

func set_wall_squeeze_active(active: bool) -> void:
	_wall_squeeze_active = active
	_update_mix_buses()

func set_nightfall_gain(gain: float) -> void:
	_nightfall_gain = gain
	_update_mix_buses()

func set_fight_mix() -> void:
	_music_fraction = 0.0
	_ambience_fraction = BUTCHER_AMBIENCE_FRACTION
	_update_mix_buses()

func set_sfx_volume() -> void:
	_update_mix_buses()

func _update_mix_buses() -> void:
	var music_level := float(GameSettings.get_value("music")) * _music_fraction
	var indoor_multiplier := 0.56 if _indoor_music else 1.0
	var music_index := _ensure_bus("Music")
	var music_volume := music_level * indoor_multiplier * _nightfall_gain
	if _wall_squeeze_active:
		music_volume *= 0.1
	AudioServer.set_bus_volume_db(music_index, linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_mute(music_index, music_volume <= 0.001)
	var ambience_volume := float(GameSettings.get_value("sfx")) * _ambience_fraction * _nightfall_gain
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
	return sound_name in STORY_AMBIENCE or sound_name in ["pond_ambience", "horror_wind", "pond_water", "pond_crossing"]

func stop(sound_name: String) -> void:
	var player := _loops.get(sound_name) as AudioStreamPlayer
	if player:
		player.stop()
		player.queue_free()
	_loops.erase(sound_name)

func stop_all_loops() -> void:
	for sound_name in _loops.keys():
		stop(sound_name)
