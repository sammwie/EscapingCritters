extends SceneTree
## Run with:  godot --headless --path <project> --script res://tools/build_levels.gd
## Reads res://levels_data.json (from ldtk_export.py) and writes Godot scenes
## to res://levels/. Needs the tileset PNGs in res://art/tilesets/ (imported).

const TILESET_PNGS := {
	0: "res://art/tilesets/hollowbrook_ldtk_tileset.png",
	1: "res://art/tilesets/house_tileset_32px.png",
	2: "res://art/tilesets/shops_tileset_32px.png",
}
const BUILDINGS_PNG := "res://art/tilesets/hollowbrook_buildings_tileset.png"
const BUILDING_SIZE := 80

func _init() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://levels_data.json"))
	var ts := _make_tileset()
	var err := ResourceSaver.save(ts, "res://levels/hollowbrook_tileset.tres")
	if err != OK:
		push_error("could not save tileset: %s" % err)
	ts = load("res://levels/hollowbrook_tileset.tres")
	for lv in data.levels:
		_build_level(lv, ts)
	quit()

func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	for id in TILESET_PNGS:
		var src := TileSetAtlasSource.new()
		var tex: Texture2D = load(TILESET_PNGS[id])
		src.texture = tex
		src.texture_region_size = Vector2i(16, 16)
		var cols := int(tex.get_width() / 16)
		var rows := int(tex.get_height() / 16)
		for y in rows:
			for x in cols:
				src.create_tile(Vector2i(x, y))
		ts.add_source(src, id)
	return ts

func _build_level(lv: Dictionary, ts: TileSet) -> void:
	var root := Node2D.new()
	root.name = lv.name
	for layer in lv.layers:
		if layer.has("tiles"):
			var tml := TileMapLayer.new()
			tml.name = layer.name
			tml.tile_set = ts
			tml.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			root.add_child(tml)
			tml.owner = root
			for t in layer.tiles:
				var alt := 0
				if int(t[4]) & 1:
					alt |= TileSetAtlasSource.TRANSFORM_FLIP_H
				if int(t[4]) & 2:
					alt |= TileSetAtlasSource.TRANSFORM_FLIP_V
				tml.set_cell(Vector2i(int(t[0]), int(t[1])), int(layer.source), Vector2i(int(t[2]), int(t[3])), alt)
		elif layer.has("entities"):
			var holder := Node2D.new()
			holder.name = "Buildings"
			root.add_child(holder)
			holder.owner = root
			for e in layer.entities:
				_add_building(root, holder, e)
	var ps := PackedScene.new()
	ps.pack(root)
	var path := "res://levels/%s.tscn" % String(lv.name).to_lower()
	var err := ResourceSaver.save(ps, path)
	print("saved ", path, " err=", err, " layers=", lv.layers.size())

func _add_building(root: Node, holder: Node, e: Dictionary) -> void:
	var idx := int(round(float(e.tile_x) / 240.0))
	var sprite := Sprite2D.new()
	sprite.name = "%s_building_%d" % [e.name, idx]
	var at := AtlasTexture.new()
	at.atlas = load(BUILDINGS_PNG)
	at.region = Rect2(idx * BUILDING_SIZE, 0, BUILDING_SIZE, BUILDING_SIZE)
	sprite.texture = at
	sprite.centered = false
	sprite.position = Vector2(e.x, e.y)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(sprite)
	sprite.owner = root
	# Placeholder collision: the whole 80x80 footprint, on layer 1 (world).
	var body := StaticBody2D.new()
	body.name = "Collision"
	body.collision_layer = 1
	body.collision_mask = 0
	sprite.add_child(body)
	body.owner = root
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(BUILDING_SIZE, BUILDING_SIZE)
	shape.name = "Shape"
	shape.shape = rect
	shape.position = Vector2(BUILDING_SIZE / 2.0, BUILDING_SIZE / 2.0)
	body.add_child(shape)
	shape.owner = root
