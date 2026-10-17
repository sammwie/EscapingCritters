# Art Style Guide

Keep new art consistent with existing art. Fill in the values marked **TODO** and keep this file up to date.

# JUST IGNORE THIS FILE, WE PROBABLY WON'T NEED TO USE IT

## Overview

- **Game:** Escaping Critters
- **Art style:** TODO (e.g. top-down pixel art, cozy, bright colors)
- **Mood / tone:** TODO (e.g. warm, playful, slightly spooky)

## Sizes

| Item | Size |
|---|---|
| Tile size | TODO (e.g. 16x16) |
| Character sprite canvas | TODO (e.g. 32x32) |
| Critter sprite canvas | TODO |
| Inventory item icons | TODO (e.g. 16x16) |
| UI icons | TODO |
| Max sprite sheet size | TODO |

## Colors

- **Palette file:** TODO (add a `.gpl` or `.png` swatch to `design/ui/` or here)
- **Max colors per sprite:** TODO
- **Transparent background:** always, for sprites and items
- **Don't** use pure black (#000000) for outlines unless noted: TODO

## Outlines and shading

- **Outline:** TODO (e.g. 1px dark colored outline, no outline on tiles)
- **Light direction:** TODO (e.g. top-left)
- **Shading:** TODO (e.g. 2 to 3 tones per color, no dithering)
- **Anti-aliasing:** TODO (pixel art: none)

## Characters

- **Facing directions:** TODO (e.g. 4-way: up, down, left, right)
- **Required animations:** idle, walk (add others as needed)
- **Frames per animation:** TODO (e.g. idle 4, walk 6)
- **Frame rate:** TODO (e.g. 8 fps)
- **Pivot / origin:** TODO (e.g. bottom center)

## Environment

- **Tilesets:** TODO (e.g. 16x16 tiles, autotile layout, spacing/margin)
- **Interiors:** TODO
- **Layers:** TODO (ground, objects, overhead)

## UI

- **Fonts:** see `ui/fonts/`
- **Buttons / panels:** TODO (9-slice margins, states: normal, hover, pressed, disabled)
- **Scaling:** TODO (e.g. design at 640x360, scaled up by integer multiples)

## Export rules

- **Format:** PNG, 32-bit with transparency
- **File names:** `snake_case`, no spaces, subject first (e.g. `baker_walk.png`)
- **Sprite sheets:** TODO (horizontal strip or grid? padding?)
- **Where exports go:** copy to the matching folder under `art/`
