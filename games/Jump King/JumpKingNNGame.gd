class_name JumpKingNNGame extends NNGame

const input_map: Dictionary = {
	"left": "←",
	"right": "→",
	"jump": "↑"
}

var data_map: Dictionary = {
	"screen": NNGrid.new(Vector2i(9, 9), 1),
	"score": NNValue.new(),
	"jump_charge": NNGrid.new(Vector2i(1, 8), 1)
}

var frame_inputs: Dictionary = {
	"left": false,
	"right": false,
	"jump": false
}

func _physics_process(delta):
	frame_inputs.jump = Input.is_action_pressed("jump")
	frame_inputs.left = Input.is_action_pressed("left")
	frame_inputs.right = Input.is_action_pressed("right")

func get_frame_output():
	pass

func submit_inputs():
	pass
