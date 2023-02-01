extends RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	Neat.connect_label(self)
