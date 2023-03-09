@tool
class_name NetworkVisual extends Node2D

var current_network: Network

@onready var node_parent = $Nodes
@onready var line_parent = $Lines

@export var width: int
@export var height: int

#### DEBUG ####
@export var revisualize: bool :
	set(b):
		revisualize = b
		if b:
			load_network(file_name)
			visualize(current_network)

@export_file var file_name: String :
	set(path):
		file_name = path

func load_network(file):
	var genome = ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_REPLACE)
	var temp_config = NEATConfig.new()
	temp_config.inputs = 174
	temp_config.outputs = 3
	print(Genome.genome_string(genome))
	current_network = Network.generate(genome, temp_config)
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
var depth_nodes: Array = []

func visualize(network: Network):
	print("visualizing")
	line_index = 0
	node_index = 0
	current_network = network
	geneToNode = {}
	clear()
	
	# Output nodes have 0 depth, input nodes will have the max depth, others in between
	# Place nodes first, we already know their depth
	for i in network.neurons.keys():
		var neuron: Neuron = network.neurons[i]
		var node: Sprite2D = acq_node()
		geneToNode[i] = node
		if i < network.num_inputs:
			# Input node
			node.position.y = (i * 9) % height
			node.position.x = (i) % 100
			node.visible = true
		elif i >= network.max_nodes:
			# Output node
			node.position.y = 20 * (i - current_network.max_nodes)
			node.position.x = width + 50
			node.visible = true
		else:
			# In-between node
			var x_ratio = (neuron.depth as float) / (network.max_depth as float)
#			print(neuron.depth, "/", network.max_depth, " ", x_ratio)
			var y_ratio = randf()
			node.position.x = x_ratio * width
			node.position.y = y_ratio * height
			node.visible = true
			
	# Connect nodes according to incoming property
	for i in network.neurons.keys():
		var neuron: Neuron = network.neurons[i]
		for inc in neuron.incoming:
			var line: Line2D = acq_line()
			line.clear_points()
			line.add_point(geneToNode[i].position)
			line.add_point(geneToNode[inc.into].position)
			print(line.points)
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

func update():
	pass
