"""Reads an .ldtk file and writes a simple JSON that build_levels.gd turns into Godot scenes."""
import json, sys
src, out = sys.argv[1], sys.argv[2]
d = json.load(open(src))
ts_by_uid = {t['uid']: t['identifier'] for t in d['defs']['tilesets']}
# LDtk tileset identifier -> (godot source id, png name). Anything not listed is skipped.
KNOWN = {
    'Hollowbrook_ldtk_tileset2': 0,
    'House_tileset_32px': 1,
    'Shops_tileset_32px': 2,
}
levels = []
for lv in d['levels']:
    layers = []
    entities = []
    for li in reversed(lv['layerInstances']):  # LDtk lists top layer first; Godot draws last on top
        if li['__type'] == 'Tiles' and li['gridTiles']:
            tsid = ts_by_uid.get(li['__tilesetDefUid'])
            if tsid not in KNOWN:
                print('skipping layer', lv['identifier'], li['__identifier'], 'tileset', tsid, '(not in the zip)')
                continue
            # LDtk can stack several tiles in one cell; a Godot TileMapLayer holds one
            # tile per cell, so stacked tiles go into extra layers (<name>_stack2, ...).
            stacks = []
            seen = {}
            for t in li['gridTiles']:
                cx, cy = t['px'][0] // 16, t['px'][1] // 16
                n = seen.get((cx, cy), 0)
                seen[(cx, cy)] = n + 1
                while len(stacks) <= n:
                    stacks.append([])
                stacks[n].append([cx, cy, t['src'][0] // 16, t['src'][1] // 16, t['f']])
            for n, tiles in enumerate(stacks):
                name = li['__identifier'] if n == 0 else '%s_stack%d' % (li['__identifier'], n + 1)
                layers.append({'name': name, 'source': KNOWN[tsid], 'tiles': tiles})
        elif li['__type'] == 'Entities' and li['entityInstances']:
            for e in li['entityInstances']:
                entities.append({'name': e['__identifier'], 'x': e['px'][0], 'y': e['px'][1],
                                 'tile_x': e['__tile']['x'], 'w': e['width'], 'h': e['height']})
            layers.append({'name': 'Entities', 'entities': entities})
    levels.append({'name': lv['identifier'], 'w': lv['pxWid'], 'h': lv['pxHei'],
                   'world_x': lv['worldX'], 'world_y': lv['worldY'], 'layers': layers})
json.dump({'levels': levels}, open(out, 'w'))
print('wrote', out, [(l['name'], len(l['layers'])) for l in levels])
