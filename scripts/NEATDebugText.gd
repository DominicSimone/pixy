extends Label

# Called when the node enters the scene tree for the first time.
func _ready():
	Neat.connect_label(self)

func _on_color_rect_2_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed == true:
			Neat.update_label()
