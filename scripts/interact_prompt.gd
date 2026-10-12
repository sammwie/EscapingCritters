extends CanvasLayer
## Scene: CanvasLayer > Label (named "PromptLabel", "Access as Unique Name" on).
## Shows "Press E: <prompt_text>" while an Interactable is in range.
## Hides itself while dialogue is open.

@onready var label: Label = %PromptLabel

var _interactor: Interactor = null

func _ready() -> void:
	label.hide()
	Dialogue.line_shown.connect(func(_s, _t): label.hide())
	# The Interactor joins the "interactor" group in its _ready().
	# Wait a frame so the Player is in the tree before we look for it.
	await get_tree().process_frame
	_interactor = get_tree().get_first_node_in_group("interactor") as Interactor
	if _interactor:
		_interactor.target_changed.connect(_on_target_changed)

func _on_target_changed(target: Interactable) -> void:
	if target == null or Dialogue.active:
		label.hide()
		return
	label.text = "Press E: %s" % target.prompt_text
	label.show()
