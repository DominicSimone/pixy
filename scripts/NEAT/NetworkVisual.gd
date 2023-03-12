@tool
class_name NetworkVisual extends Node2D

var current_network: Network

@onready var node_parent = $Nodes
@onready var line_parent = $Lines

@export var width: int
@export var height: int

@export var modulate_color: Color

# TODO place mid nodes better and maybe make smaller

#### DEBUG ####
var vision_grid = NNGrid.new(Vector2i(16, 10), 1)
var jump_meter = NNGrid.new(Vector2i(8, 1), 1)
var detail_ground = NNGrid.new(Vector2i(5, 1), 1)
var bias = NNValue.new(1)
var flat_data: Array[NNInput] = [vision_grid, jump_meter, detail_ground, bias]
var config: NEATConfig = NEATConfig.new()
func _ready():
	config.inputs = 174
	config.outputs = 3

@export_category("Debug")
@export var revisualize: bool :
	set(b):
		revisualize = b
		if current_network:
			visualize(current_network, flat_data)

@export_file var file_name: String :
	set(path):
		file_name = path
		if path != "":
			load_network(path)

func load_network(file):
	var genome = ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_REPLACE)
	print(Genome.genome_string(genome))
	current_network = Network.generate(genome, config)

#@export_category("Live")
## Requires modifying Genome to not call to Neat but instead use its own innovation counter
#var current_genome: Genome
#@export var genome: bool: 
#	set(i):
#		genome = i
#		if i:
#			current_genome = Genome.basic(config)
#			print(Genome.genome_string(current_genome))
#			current_network = Network.generate(current_genome, config)
#			visualize(current_network, flat_data)
#@export var mutate: bool:
#	set(b):
#		mutate = b
#		if b:
#			current_genome.mutate(config)
#			print(Genome.genome_string(current_genome))
#			current_network = Network.generate(current_genome, config)
#			visualize(current_network, flat_data)
#### END DEBUG ####

var node_scene: PackedScene = preload("res://node.tscn")
var line_scene: PackedScene = preload("res://line.tscn")

var line_index: int = 0
var lines: Array[Line2D]
var node_index: int = 0
var nodes: Array[Sprite2D]

# Dictionary from neuron -> node? will need to reference node positions when drawing
# connections between nodes
var geneToNode: Dictionary = {}

# TODO Store depth -> list of nodes to render? might look cleaner than random positions
var depth_nodes: Dictionary = {}

func visualize(network: Network, inputs: Array[NNInput]):
	print("visualizing")
	line_index = 0
	node_index = 0
	current_network = network
	geneToNode = {}
	depth_nodes = {}
	clear()

	# Put inputs on the left
	var input_index: int = 0
	var current_height: float = 0
	for nninput in inputs:
		var grid_width: int = 10
		if nninput is NNGrid:
			grid_width = nninput.size.x
		var scale_ratio: float = min(1.0, 10.0 / grid_width)
		var sub_input_index: int = 0
		var flat_inputs = nninput.flatten()
		for input in flat_inputs:
			var x: int = sub_input_index % grid_width
			if sub_input_index != 0 and x == 0:
				current_height += 1 * scale_ratio

			var node: Sprite2D = acq_node()
			geneToNode[input_index] = node
			var mod = (input * 0.7) + 0.3
			node.modulate = Color(mod, mod, mod)
			node.position.y = current_height * 10
			node.position.x = x * 10 * scale_ratio
			node.scale = Vector2(scale_ratio, scale_ratio)
			node.visible = true

			sub_input_index += 1
			input_index += 1
		current_height += 1.5 # New line and a bit of spacing for each input
	
	# Output nodes have 0 depth, input nodes will have the max depth, others in between
	# Place nodes first, we already know their depth
	for i in network.neurons.keys():
		var neuron: Neuron = network.neurons[i]
		# Input node, already placed
		if i < network.num_inputs:
			pass
		# Output node
		elif i >= network.max_nodes:
			var node: Sprite2D = acq_node()
			geneToNode[i] = node
			node.position.y = 15 * (i - current_network.max_nodes)
			node.position.x = width
			node.modulate = modulate_color if neuron.value <= 0 else Color(1, 1, 1)
			node.visible = true
		else:
			# In-between node, depth may be -1 if there is no path from this to an output
			# depth is distance from output nodes
			var node: Sprite2D = acq_node()
			geneToNode[i] = node
			node.modulate = lerp(modulate_color, Color(1, 1, 1), neuron.value)
			if neuron.depth in depth_nodes.keys():
				depth_nodes[neuron.depth].append(node)
			else:
				depth_nodes[neuron.depth] = [node]
	
	for depth in depth_nodes:
		var current: int = 0
		for node in depth_nodes[depth]:
			var x_ratio = 1 - abs(depth as float / network.max_depth as float)
			node.position.x = x_ratio * width
			node.position.y = current * 13
			node.visible = true
			current += 1
	
	# Connect nodes according to incoming property
	for i in network.neurons.keys():
		var neuron: Neuron = network.neurons[i]
		for inc in neuron.incoming:
			var incoming_value = network.neurons[inc.into].value * inc.weight
			var line: Line2D = acq_line()
			line.clear_points()
			line.material.set_shader_parameter("activity", incoming_value)
			line.material.set_shader_parameter("position_offset", randi() % 10000)
			line.add_point(geneToNode[inc.into].position)
			line.add_point(geneToNode[i].position)
			line.visible = true

func acq_node() -> Sprite2D:
	node_index += 1
	if node_index < nodes.size():
		return nodes[node_index - 1]
	else:
		var new_node = node_scene.instantiate()
		node_parent.add_child(new_node)
		nodes.append(new_node)
		return new_node

func acq_line() -> Line2D:
	line_index += 1
	if line_index < lines.size():
		return lines[line_index - 1]
	else:
		var new_line = line_scene.instantiate()
		line_parent.add_child(new_line)
		lines.append(new_line)
		return new_line

func clear():
	for line in lines:
		line.visible = false
	for node in nodes:
		node.visible = false
		node.scale = Vector2(1, 1)

func update():
	pass
