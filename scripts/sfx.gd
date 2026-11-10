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
var _ambience_boost_db := 0.0

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
	player.bus = "Music" if sound_name in ["cozy_level_1", "opening_music"] else "SFX"
	if sound_name == "outdoor_footsteps":
		player.volume_db = -2.0
	elif sound_name == "opening_music":
		player.volume_db = 4.0
	elif sound_name in ["indoor_left_foot", "indoor_right_foot"]:
		player.volume_db = 0.0
	elif sound_name == "chicken_coop":
		player.volume_db = 5.0
	elif sound_name in ["butcher_charge", "butcher_hit", "butcher_speaking", "butcher_death"]:
		player.volume_db = 8.0
	elif sound_name == "horror_2":
		player.volume_db = -5.0
	elif sound_name == "horror_wind":
		player.volume_db = -6.0
	elif sound_name in ["scary_search", "night_ambience", "pond_night_ambience", "pond_water", "pond_crossing", "chicken_coop"]:
		player.volume_db = _ambience_boost_db
		if sound_name == "pond_night_ambience":
			player.volume_db -= 8.0
		if sound_name == "pond_water":
			player.volume_db += 6.0
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
	var music_level := float(GameSettings.get_value("music"))
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(music_level, 0.0001)) + (-5.0 if indoor else 0.0))

func set_level_mix(level: int, night := false) -> void:
	_ambience_boost_db = -8.0 if level <= 1 else -3.0 if level == 2 else 4.0
	_music_bus = AudioServer.get_bus_index("Music")
	if _music_bus >= 0:
		var music_level := float(GameSettings.get_value("music"))
		var attenuation := 0.0 if level <= 1 else -6.0 if level == 2 else -18.0
		AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(music_level, 0.0001)) + attenuation)
	for sound_name in ["horror_ambience", "night_ambience", "pond_water"]:
		var ambient := _loops.get(sound_name) as AudioStreamPlayer
		if is_instance_valid(ambient):
			ambient.volume_db = _ambience_boost_db + (6.0 if sound_name == "pond_water" else 0.0)
	if night:
		stop("cozy_level_1")
		stop("opening_music")

func stop(sound_name: String) -> void:
	var player := _loops.get(sound_name) as AudioStreamPlayer
	if player:
		player.stop()
		player.queue_free()
	_loops.erase(sound_name)

func stop_all_loops() -> void:
	for sound_name in _loops.keys():
		stop(sound_name)
