class_name NotesLog
extends RefCounted
## Every note the player has found. Lives for the whole play session.
## Press N in game to read them all again (see Level2Quest / NoteViewer).

static var entries: Array[Dictionary] = []

static func add(id: String, title: String, body: String) -> void:
	for entry in entries:
		if entry["id"] == id:
			return
	entries.append({"id": id, "title": title, "body": body, "day": GameState.current_day})

static func has_note(id: String) -> bool:
	for entry in entries:
		if entry["id"] == id:
			return true
	return false

static func reset() -> void:
	entries.clear()
