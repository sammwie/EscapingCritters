class_name CombatHUD
extends CanvasLayer
## Hearts for the player and a health bar for the boss, in the game's
## parchment / wood style. Used by the Butcher arena.

const HEART := preload("res://art/animals/heart.png")
const FONT_REG := preload("res://art/fonts/Silkscreen-Regular.ttf")
const FONT_BOLD := preload("res://art/fonts/Silkscreen-Bold.ttf")
const CREAM := Color(1, 0.972549, 0.9098039)
const WOOD := Color(0.6509804, 0.45490196, 0.28235295)
const WOOD_DARK := Color(0.47058824, 0.32156864, 0.20392157)
const INK := Color(0.22745098, 0.15686275, 0.11764706)

var _hearts: Array[TextureRect] = []
var _heart_box: HBoxContainer
var _boss_panel: PanelContainer
var _boss_bar: ProgressBar
var _boss_name: Label
var _message: Label
var _hint: Label
var _bar_tween: Tween

func _ready() -> void:
	layer = 45
	_build()

func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# player hearts, top centre
	_heart_box = HBoxContainer.new()
	_heart_box.add_theme_constant_override("separation", 10)
	_heart_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_heart_box.position.y = 28
	_heart_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_heart_box)

	# boss bar, bottom centre
	_boss_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(CREAM, 0.96)
	style.border_color = WOOD
	style.set_border_width_all(6)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	style.shadow_color = Color(INK, 0.4)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 4)
	_boss_panel.add_theme_stylebox_override("panel", style)
	_boss_panel.custom_minimum_size = Vector2(840, 0)
	_boss_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_panel.position.y = -120
	_boss_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_panel.visible = false
	root.add_child(_boss_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_boss_panel.add_child(box)
	_boss_name = Label.new()
	_boss_name.add_theme_font_override("font", FONT_BOLD)
	_boss_name.add_theme_font_size_override("font_size", 26)
	_boss_name.add_theme_color_override("font_color", WOOD_DARK)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_boss_name)

	_boss_bar = ProgressBar.new()
	_boss_bar.show_percentage = false
	_boss_bar.custom_minimum_size = Vector2(0, 28)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.85, 0.745, 0.576)
	bg.border_color = WOOD_DARK
	bg.set_border_width_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.74, 0.2, 0.2)
	fill.border_color = WOOD_DARK
	fill.set_border_width_all(4)
	_boss_bar.add_theme_stylebox_override("background", bg)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_boss_bar)

	# big centre message ("FIGHT!", "TRY AGAIN")
	_message = Label.new()
	_message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.add_theme_font_override("font", FONT_BOLD)
	_message.add_theme_font_size_override("font_size", 96)
	_message.add_theme_color_override("font_color", CREAM)
	_message.add_theme_color_override("font_shadow_color", INK)
	_message.add_theme_constant_override("shadow_offset_x", 6)
	_message.add_theme_constant_override("shadow_offset_y", 6)
	_message.modulate.a = 0.0
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_message)

	# controls hint
	_hint = Label.new()
	_hint.text = "SPACE: ATTACK     SHIFT: DODGE"
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.position.y = -190
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint.add_theme_font_override("font", FONT_REG)
	_hint.add_theme_font_size_override("font_size", 24)
	_hint.add_theme_color_override("font_color", CREAM)
	_hint.add_theme_color_override("font_shadow_color", INK)
	_hint.add_theme_constant_override("shadow_offset_x", 3)
	_hint.add_theme_constant_override("shadow_offset_y", 3)
	_hint.visible = false
	root.add_child(_hint)

func set_hearts(hearts: int, max_hearts: int) -> void:
	while _hearts.size() < max_hearts:
		var tex := TextureRect.new()
		tex.texture = HEART
		tex.custom_minimum_size = Vector2(56, 48)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_heart_box.add_child(tex)
		_hearts.append(tex)
	for i in _hearts.size():
		var full := i < hearts
		_hearts[i].modulate = Color.WHITE if full else Color(0.15, 0.1, 0.1, 0.55)
		if i == hearts and not full:
			# the heart that was just lost pops
			var pop := create_tween()
			_hearts[i].pivot_offset = _hearts[i].custom_minimum_size / 2.0
			_hearts[i].scale = Vector2(1.5, 1.5)
			pop.tween_property(_hearts[i], "scale", Vector2.ONE, 0.25)

func show_boss(display_name: String, hp: int, max_hp: int) -> void:
	_boss_name.text = display_name
	_boss_bar.max_value = max_hp
	_boss_bar.value = hp
	_boss_panel.visible = true
	_hint.visible = true
	await get_tree().create_timer(7.0).timeout
	if is_instance_valid(_hint):
		_hint.visible = false

func set_boss_hp(hp: int, max_hp: int) -> void:
	_boss_bar.max_value = max_hp
	if _bar_tween and _bar_tween.is_valid():
		_bar_tween.kill()
	_bar_tween = create_tween()
	_bar_tween.tween_property(_boss_bar, "value", float(hp), 0.18)

func flash_message(text: String, hold := 1.0) -> void:
	_message.text = text
	var tween := create_tween()
	tween.tween_property(_message, "modulate:a", 1.0, 0.15)
	tween.tween_interval(hold)
	tween.tween_property(_message, "modulate:a", 0.0, 0.4)

func hide_all() -> void:
	_boss_panel.visible = false
	_heart_box.visible = false
	_hint.visible = false
