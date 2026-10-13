class_name TownSquare
extends Activity
## Town square logic only: a list of announcements, one per day, that the
## notice board reads out. Designers can edit the list in the Inspector.
## The GDD does not define the town square yet, so this is a placeholder.
## Put this as a child Node of a NoticeBoard.

@export var announcements: Array[String] = [
	"Welcome to town! Say hello to your neighbors.",
	"The bakery has fresh bread today.",
	"Fishing is good at the lake this week.",
]

func _ready() -> void:
	if activity_id == &"":
		activity_id = &"town_square"

# Day 1 gives the first announcement, day 2 the second, and so on (wraps).
func announcement_for_day(day: int) -> String:
	if announcements.is_empty():
		return "Nothing new today."
	return announcements[(maxi(day, 1) - 1) % announcements.size()]
