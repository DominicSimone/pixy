extends Node

func _ready():
	get_tree().root.borderless = false

func _input(event):
	if event.is_action_pressed("escape"):
		get_tree().root.borderless = !get_tree().root.borderless

