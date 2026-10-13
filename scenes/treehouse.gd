class_name Treehouse
extends Activity
## Treehouse logic only: the player's retreat. For now its one job is
## resting, which ends the day. Emits `slept` so the day cycle can react.
## The GDD does not define the treehouse yet, so this is a placeholder.
## Put this as a child Node of a TreehouseBed.

signal slept

func _ready() -> void:
	if activity_id == &"":
		activity_id = &"treehouse"

func rest() -> void:
	if running:
		return
	start()
	slept.emit()
	finish({"rested": true})
