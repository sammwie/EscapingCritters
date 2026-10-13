extends AnimatedSprite2D
## Presentation child for the existing player. Movement stays in Coder 2's script.

const DIRECTIONS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
var facing := "south"


func _ready() -> void:
	sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")
	for direction: String in DIRECTIONS:
		var walk_name := "walk_" + direction
		var idle_name := "idle_" + direction
		sprite_frames.add_animation(walk_name)
		sprite_frames.set_animation_speed(walk_name, 8.0)
		for frame in 8:
			sprite_frames.add_frame(walk_name, load("res://art/critter/animations/Walking/%s/frame_%03d.png" % [direction, frame]))
		sprite_frames.add_animation(idle_name)
		sprite_frames.add_frame(idle_name, load("res://art/critter/rotations/%s.png" % direction))
	play("idle_south")


func _process(_delta: float) -> void:
	var actor := get_parent() as CharacterBody2D
	if actor == null:
		return
	if actor.velocity.length_squared() > 1.0:
		var direction_index := posmod(roundi(actor.velocity.angle() / (PI / 4.0)), DIRECTIONS.size())
		facing = DIRECTIONS[direction_index]
		play("walk_" + facing)
	else:
		play("idle_" + facing)
