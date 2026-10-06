class_name DialogueLine
extends Resource

@export var speaker := ""
@export_multiline var text := ""
@export var min_corruption := 0  # only used at or above this stage
@export var glitch := false      # force glitch effect on this line
