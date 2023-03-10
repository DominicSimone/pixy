@tool
class_name NetworkVisual extends Node2D

var current_network: Network

@onready var node_parent = $Nodes
@onready var line_parent = $Lines

@export var width: int
@export var height: int

#### DEBUG ####
var config: NEATConfig = NEATConfig.new()
func _ready():
	config.inputs = 174
	config.outputs = 3

@export_category("Debug")
@export var revisualize: bool :
	set(b):
		revisualize = b
		if current_network:
			visualize(current_network)

@export_file var file_name: String :
	set(path):
		file_name = path
		if path != "":
			load_network(path)

func load_network(file):
	var genome = ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_REPLACE)
	print(Genome.genome_string(genome))
	current_network = Network.generate(genome, config)

@export_category("Live")
# Requires modifying Genome to not call to Neat but instead use its own innovation counter
var current_genome: Genome
@export var genome: bool: 
	set(i):
		genome = i
		if i:
			current_genome = Genome.basic(config)
			print(Genome.genome_string(current_genome))
			current_network = Network.generate(current_genome, config)
			visualize(current_network)
@export var mutate: bool:
	set(b):
		mutate = b
		if b:
			current_genome.mutate(config)
			print(Genome.genome_string(current_genome))
			current_network = Network.generate(current_genome, config)
			visualize(current_network)
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

func visualize(network: Network, inputs: Array[NNInput] = []):
	print("visualizing")
	line_index = 0
	node_index = 0
	current_network = network
	geneToNode = {}
	depth_nodes = {}
	clear()
	
	# Output nodes have 0 depth, input nodes will have the max depth, others in between
	# Place nodes first, we already know their depth
	for i in network.neurons.keys():
		var neuron: Neuron = network.neurons[i]
		var node: Sprite2D = acq_node()
#		node.rotation_degrees = i
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
			# In-between node, depth may be -1 if there is no path from this to an output
			# depth is distance from output nodes
			if neuron.depth in depth_nodes.keys():
				print("existing array at ", neuron.depth)
				depth_nodes[neuron.depth].append(node)
			else:
				print("new array at ", neuron.depth)
				depth_nodes[neuron.depth] = [node]
	
	for depth in depth_nodes:
		print(depth)
		var current: int = 0
		for node in depth_nodes[depth]:
			var x_ratio = 1 - abs(depth as float / network.max_depth as float)
			print(depth, "/", network.max_depth, " = ", x_ratio)
			node.position.x = x_ratio * width
			node.position.y = current * 13
			node.visible = true
			current += 1
	
	# Connect nodes according to incoming property
	for i in network.neurons.keys():
		var neuron: Neuron = network.neurons[i]
		for inc in neuron.incoming:
			var line: Line2D = acq_line()
			line.clear_points()
			line.add_point(geneToNode[i].position)
			line.add_point(geneToNode[inc.into].position)
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
