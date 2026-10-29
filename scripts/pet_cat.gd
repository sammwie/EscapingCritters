class_name PetCat
extends Interactable
## Mochi the cat. Swishes her tail, blinks, and shows hearts when petted.
## Scene: Area2D (this script) > CollisionShape2D. Layer 2, mask empty.
## Once the story flag "cat_dead" is set, she can no longer be petted and
## shows dead_texture (if the designers assign one).

const SHEET := preload("res://art/animals/cat.png")
const HEART := preload("res://art/animals/heart.png")

@export var dead_texture: Texture2D

var _sprite: Sprite2D
var _t := 0.0
var _blink := 0.0
var _dead := false

func _ready() -> void:
	prompt_text = "Pet Mochi"
	add_child(SoftShadow.make(Vector2(0, 7), Vector2(6, 2)))
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 3
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

func _unhandled_input(event: InputEvent) -> void:
	# Debug only: K toggles the cat_dead flag for testing the story chain.
	if OS.is_debug_build() and event is InputEventKey and event.pressed \
			and not event.echo and event.keycode == KEY_K:
		StoryInteractable.set_story_flag("cat_dead", not StoryInteractable.get_story_flag("cat_dead"))

func _process(delta: float) -> void:
	var dead_now := StoryInteractable.get_story_flag("cat_dead")
	if dead_now != _dead:
		_dead = dead_now
		_apply_dead_state()
	enabled = not _dead
	if _dead:
		return
	_t += delta
	if _blink > 0.0:
		_blink -= delta
		_sprite.frame = 2
	else:
		_sprite.frame = 1 if fmod(_t, 1.6) < 0.5 else 0
		if randf() < delta * 0.3:
			_blink = 0.15

func _apply_dead_state() -> void:
	if _dead and dead_texture != null:
		_sprite.texture = dead_texture
		_sprite.hframes = 1
		_sprite.frame = 0
	else:
		_sprite.texture = SHEET
		_sprite.hframes = 3

func _on_interact(_by: Node) -> void:
	_blink = 0.8
	for i in 3:
		var heart := Sprite2D.new()
		heart.texture = HEART
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.position = Vector2(randf_range(-6, 6), -10)
		heart.z_index = 5
		add_child(heart)
		var tween := create_tween()
		tween.tween_interval(i * 0.2)
		tween.tween_property(heart, "position:y", heart.position.y - 14, 0.9)
		tween.parallel().tween_property(heart, "modulate:a", 0.0, 0.9)
		tween.tween_callback(heart.queue_free)
	Level1Quest.pet_cat()
