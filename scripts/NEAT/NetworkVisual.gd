class_name NetworkVisual extends Node2D

var current_network: Network

var node_scene: PackedScene = preload("res://node.tscn")

var line_index: int = 0
var lines: Array[Line2D]
var node_index: int = 0
var nodes: Array[Sprite2D]

# Dictionary from neuron -> node? will need to reference node positions when drawing
# connections between nodes

func visualize(network: Network):
	line_index = 0
	node_index = 0
	current_network = network
	clear()
	
	# Need to set up input and output positions first, so we can draw lines later
	
	
	# Output nodes have 0 depth, input nodes will have the max depth, others in between
	for i in network.neurons.keys():
		if i < network.num_inputs:
			# Input node
			pass
		if i >= network.max_nodes:
			# Output node
			pass
		# In-between node
	

func clear():
	for line in lines:
		line.visible = false
	for node in nodes:
		node.visible = false

func update():
	pass
