# design/

This folder is for **designers**. It holds the team's working art files: layered source files, exports, and reference images.

## For coders: you can ignore this folder

- **Don't load anything from here in the game.** This folder contains a `.gdignore` file, so Godot skips it completely. It won't show up in the FileSystem dock, and no `.import` files are created here.
- **Don't edit or reorganize files here.** designers own this folder. If you need a change to an asset, ask them.

Art the game actually uses lives in `art/`. That's where you should reference assets from (`res://art/...`).

## How art gets from here into the game

1. An designer finishes a file in `design/`.
2. The exported file (usually a PNG) is copied into the matching folder under `art/`. The folder structure is mirrored, so `design/characters/baker/` maps to `art/characters/baker/`.
3. Open the Godot editor so it imports the new or changed file. That creates the `.import` file in `art/`.
4. Commit the export and its `.import` file together.

If you need a new asset or a change to an existing one, ask the designer to export it rather than editing the file in `art/` yourself. Otherwise it gets out of sync with the source.

## Folder structure

```
design/
├── characters/      # player, NPCs, villagers, critters
├── environment/     # tilesets, interiors
├── items/           # inventory items
└── ui/              # fonts, branding (logo, splash), menus
```

## For designers

- Use `snake_case` for file and folder names, with no spaces (`baker_walk.aseprite`).
- Keep one folder per character containing all of their source files and exports.
- Don't put anything in `art/` yourself. Hand finished exports to a coder, or follow the export steps above.
- Never commit `.import` files or `.DS_Store` here.
- If you add a new top-level category, update this README.
