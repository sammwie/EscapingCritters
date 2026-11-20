extends Node2D
## Test scene for the Knows All fight. Make a new scene whose root is a Node2D
## with this script, drag your player scene into "Player Scene", press F6.

@export var player_scene: PackedScene
@export var arena_size := Vector2(360, 240)
@export var camera_zoom := 3.0
@export var give_sword := false


func _ready() -> void:
	if give_sword:
		GameState.add_item(&"sword")
	var rect := Rect2(-arena_size / 2.0, arena_size)
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.18, 0.14, 0.2)
	floor_rect.position = rect.position - Vector2(300, 300)
	floor_rect.size = arena_size + Vector2(600, 600)
	floor_rect.z_index = -10
	add_child(floor_rect)

	var player := player_scene.instantiate() as CharacterBody2D
	add_child(player)

	# a bare test scene has no level camera, so make sure the player has one
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		cam = Camera2D.new()
		cam.name = "Camera2D"
		player.add_child(cam)
	cam.enabled = true
	cam.zoom = Vector2.ONE * camera_zoom
	cam.limit_left = -10000000
	cam.limit_top = -10000000
	cam.limit_right = 10000000
	cam.limit_bottom = 10000000
	cam.make_current()

	var boss := KnowsAllBoss.new()
	boss.max_hp = 8
	add_child(boss)
	var arena := KnowsAllArena.new()
	add_child(arena)
	var box_scene := load("res://scenes/dialogue_box.tscn") as PackedScene
	if box_scene:
		add_child(box_scene.instantiate())
	arena.begin(player, boss, rect)
