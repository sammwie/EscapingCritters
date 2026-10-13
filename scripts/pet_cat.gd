class_name PetCat
extends Interactable
## Mochi the cat. Swishes her tail, blinks, and shows hearts when petted.
## Scene: Area2D (this script) > CollisionShape2D. Layer 2, mask empty.

const SHEET := preload("res://art/animals/cat.png")
const HEART := preload("res://art/animals/heart.png")

var _sprite: Sprite2D
var _t := 0.0
var _blink := 0.0

func _ready() -> void:
	prompt_text = "Pet Mochi"
	add_child(SoftShadow.make(Vector2(0, 7), Vector2(6, 2)))
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET
	_sprite.hframes = 3
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)

func _process(delta: float) -> void:
	_t += delta
	if _blink > 0.0:
		_blink -= delta
		_sprite.frame = 2
	else:
		_sprite.frame = 1 if fmod(_t, 1.6) < 0.5 else 0
		if randf() < delta * 0.3:
			_blink = 0.15

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
