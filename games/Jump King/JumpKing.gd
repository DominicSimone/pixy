class_name JumpKing extends Node

var frame_inputs: Dictionary = {
	"left": false,
	"right": false,
	"jump": false
}

@onready var player = $CharacterBody2D
@onready var tilemap = $TileMap

var vision_grid = NNGrid.new(Vector2i(16, 10), 1)
var jump_meter = NNGrid.new(Vector2i(8, 1), 1)
var detail_ground = NNGrid.new(Vector2i(5, 1), 1)

var flat_data: Array[NNInput] = [vision_grid, jump_meter, detail_ground]

func _ready():
	Neat.register_game(flat_data, 3)

func _physics_process(_delta):
	var response: NEATResponse = Neat.frame(get_score(), prepare_nn_input())
	if response.reset_flag:
		player.reset()
	frame_inputs.left = response.outputs[0] or Input.is_action_pressed("left")
	frame_inputs.jump = response.outputs[1] or Input.is_action_pressed("jump")
	frame_inputs.right = response.outputs[2] or Input.is_action_pressed("right")

func get_score() -> int:
	return (-1 * player.position.y) + 36

func prepare_nn_input() -> Array[NNInput]:
	# Vision grid 
	var horizontal_rad = vision_grid.size.x / 2.0
	var vertical_rad = vision_grid.size.y / 2.0
	for row in vision_grid.size.x:
		for col in vision_grid.size.y:
			# Not centered, prefers vision above the character
			var pos_x = -1 * (row - horizontal_rad + 0.5) * tilemap.tile_set.tile_size.x * 0.75
			var pos_y = (col - vertical_rad + 3.5) * tilemap.tile_set.tile_size.y * 0.75
			var pos = Vector2(pos_x, pos_y)
			var tile_coords = tilemap.local_to_map(tilemap.to_local(player.global_position - pos))
			if tilemap.get_cell_tile_data(0, tile_coords) != null:
				vision_grid.set_cell(row, col, 0, 1)
			else:
				vision_grid.set_cell(row, col, 0, 0)
	
	# Jump meter inputs
	for row in jump_meter.size.x:
		if player.current_jump_time / player.max_jump_time >= (row+1) / (jump_meter.size.x - 1.0):
			jump_meter.set_cell(row, 0, 0, 1)
		else:
			jump_meter.set_cell(row, 0, 0, 0)
	
	# Detail ground, sub pixels below character
	var center = detail_ground.size.x / 2.0
	var sub_pixel_size = (1.0 / detail_ground.size.x) * tilemap.tile_set.tile_size.x
	for x in detail_ground.size.x:
		var x_offset = -1 * (x - center) * sub_pixel_size
		var global_pos = Vector2(player.global_position.x - x_offset, player.global_position.y + 4)
		var tile_coords = tilemap.local_to_map(tilemap.to_local(global_pos))
		if tilemap.get_cell_tile_data(0, tile_coords) != null:
			detail_ground.set_cell(x, 0, 0, 1)
		else:
			detail_ground.set_cell(x, 0, 0, 0)
	
	return flat_data
