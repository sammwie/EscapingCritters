class_name Shop
extends Activity
## Shop logic only (no visuals): a price list and a gold counter.
## Sells from "count dictionaries" (item_id -> amount), like
## FarmManager.harvest_counts and Fishing.catch_counts.
## Put this as a child Node of a ShopCounter.
## Prices are placeholders until the designers set real ones.

signal sold(item_id: StringName, amount: int, earned: int)
signal gold_changed(new_gold: int)

@export var prices := {
	&"carrot": 5,
	&"minnow": 3,
	&"trout": 8,
	&"old_boot": 1,
}

var gold := 0

func _ready() -> void:
	if activity_id == &"":
		activity_id = &"shop"

func price_of(item_id: StringName) -> int:
	return prices.get(item_id, 0)

# Sells `amount` of one item. Returns the gold earned (0 if unsellable).
func sell(item_id: StringName, amount: int) -> int:
	if amount <= 0 or not prices.has(item_id):
		return 0
	var earned: int = prices[item_id] * amount
	gold += earned
	sold.emit(item_id, amount, earned)
	gold_changed.emit(gold)
	return earned

# Sells everything sellable in `counts` and zeroes those entries in place,
# so the farm/fishing tallies don't get sold twice. Returns total earned.
func sell_all(counts: Dictionary) -> int:
	var total := 0
	for id in counts.keys():
		var n: int = counts[id]
		if n > 0 and prices.has(id):
			total += sell(id, n)
			counts[id] = 0
	return total
