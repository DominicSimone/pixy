extends Node

var mouse_move_delta: Vector2i = Vector2i.ZERO
var mouse_position: Vector2i = Vector2i.ZERO
var window_id: int

func _ready():
	get_tree().root.borderless = false
	window_id = DisplayServer.get_window_list()[0]

func _input(event):
	if event.is_action_pressed("escape"):
		get_tree().root.borderless = !get_tree().root.borderless
	
	# Move window when click and dragging anywhere
#	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
#		if mouse_position != Vector2i.ZERO:
#			mouse_move_delta += DisplayServer.mouse_get_position() - mouse_position
#		mouse_position = DisplayServer.mouse_get_position()
#		var current_pos = DisplayServer.window_get_position(window_id)
#		DisplayServer.window_set_position(current_pos + mouse_move_delta, window_id)
#		mouse_move_delta = Vector2i.ZERO
#	else:
#		mouse_position = Vector2i.ZERO

