class_name NetworkVisual extends Node2D

var current_network: Network

@onready var node_parent = $Node2D/Nodes
@onready var line_parent = $Node2D/Lines

@export var width: int
@export var height: int

@export var modulate_color: Color

func _ready():
	Neat.network_visual = self
	
func _notification(what):
	pass

var node_scene: PackedScene = preload("res://node.tscn")
var line_scene: PackedScene = preload("res://line.tscn")

var line_index: int = 0
var lines: Array[Line2D]
var node_index: int = 0
var nodes: Array[Sprite2D]

# Dictionary from neuron -> node? will need to reference node positions when drawing
# connections between nodes
var geneToNode: Dictionary = {}
var geneToLines: Dictionary = {}
var depth_nodes: Dictionary = {}

func visualize(network: Network, inputs: Array[NNInput]):
	if current_network == network:
		# Use update instead.
		return
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
		var grid_height: int = 1
		if nninput is NNGrid:
			grid_width = nninput.size.x
			grid_height = nninput.size.y
		var scale_ratio: float = min(1.0, 10.0 / grid_width)
		var sub_input_index: int = 0
		var input_row: int = 0
		var flat_inputs = nninput.flatten()
		for input in flat_inputs:
			var x: int = sub_input_index % grid_width
			if sub_input_index != 0 and x == 0:
				input_row += 1

			var node: Sprite2D = acq_node()
			geneToNode[input_index] = node
			node.modulate = lerp(modulate_color, Color(1, 1, 1), input)
			node.position.y = (grid_height - input_row + current_height) * 10 * scale_ratio
			node.position.x = x * 10 * scale_ratio
			node.scale = Vector2(scale_ratio, scale_ratio)
			node.visible = true

			sub_input_index += 1
			input_index += 1
		current_height += input_row * scale_ratio + 1.5

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
			node.position.y = 15 * (i - current_network.max_nodes) + 9
			node.position.x = width
			node.modulate = modulate_color if neuron.value <= 0 else Color(1, 1, 1)
			node.visible = true
		else:
			# In-between node, depth may be -1 if there is no path from this to an output
			# depth is distance from output nodes
			var node: Sprite2D = acq_node()
			geneToNode[i] = node
			node.scale = Vector2(0.75, 0.75)
			node.modulate = lerp(modulate_color, Color(1, 1, 1), neuron.value)
			if neuron.depth in depth_nodes.keys():
				depth_nodes[neuron.depth].append(node)
			else:
				depth_nodes[neuron.depth] = [node]

	for depth in depth_nodes:
		var col_size: int = depth_nodes[depth].size()
		var current: int = (height / 2) - (col_size / 2) * 15
		for node in depth_nodes[depth]:
			var x_ratio = 1 - abs(depth as float / network.max_depth as float)
			node.position.x = max(110, x_ratio * (width * 0.75) + (width * 0.25))
			node.position.y = current
			node.visible = true
			current += 15

	# Connect nodes according to incoming property
	for i in network.neurons.keys():
		var neuron: Neuron = network.neurons[i]
		for inc in neuron.incoming:
			var incoming_value = network.neurons[inc.into].value * inc.weight
			var line: Line2D = acq_line()
			if i in geneToLines.keys():
				geneToLines[i][inc] = line
			else:
				geneToLines[i] = {inc: line}
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
	for i in current_network.neurons.keys():
		var neuron: Neuron = current_network.neurons[i]
		if i >= current_network.max_nodes:
			geneToNode[i].modulate = modulate_color if neuron.value <= 0 else Color(1, 1, 1)
		else:
			geneToNode[i].modulate = lerp(modulate_color, Color(1, 1, 1), neuron.value)
		for inc in neuron.incoming:
			var incoming_value = current_network.neurons[inc.into].value * inc.weight
			var line = geneToLines[i][inc]
			line.material.set_shader_parameter("activity", incoming_value)
