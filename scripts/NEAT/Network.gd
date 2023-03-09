class_name Network extends Resource

@export var neurons: Dictionary = {}
@export var num_inputs: int = 0
@export var num_outputs: int = 0
@export var max_nodes: int = 0
var max_depth: int = -1

# Not used, but required for ResourceLoader
func _init(n = {}, i = 0, o = 0, mn = 0):
	neurons = n
	num_inputs = i
	num_outputs = o
	max_nodes = mn

const e: float = 2.71828183
static func sigmoid(x):
	return 2 / (1 + pow(e, -4.9 * x)) - 1

static func generate(genome: Genome, config: NEATConfig):
	var network = Network.new()
	network.max_nodes = config.max_nodes
	network.num_inputs = config.inputs
	network.num_outputs = config.outputs
	
	for i in network.num_inputs:
		network.neurons[i] = Neuron.new()
	
	for o in network.num_outputs:
		network.neurons[o+config.max_nodes] = Neuron.new()
	
	genome.genes.sort_custom(func(a, b): return a.out < b.out)
	
	for gene in genome.genes:
		if gene.enabled:
			if not network.neurons.has(gene.out):
				network.neurons[gene.out] = Neuron.new()
			
			network.neurons[gene.out].incoming.append(gene)
			
			if not network.neurons.has(gene.into):
				network.neurons[gene.into] = Neuron.new()
	
	# Start from the outputs, work backwords with Neurons' `incoming` property to set depth
	var queue: Array[Neuron] = []
	for o in network.num_outputs:
		network.neurons[o+config.max_nodes].depth = 0
		queue.append(network.neurons[o + config.max_nodes])
	while not queue.is_empty():
		var current: Neuron = queue.pop_back()
		for gene in current.incoming:
			var neuron = network.neurons[gene.into]
			if neuron.depth == -1:
				neuron.depth = current.depth + 1
				if neuron.depth > network.max_depth:
					network.max_depth = neuron.depth
				queue.append(neuron)
	
	return network

# real inputs, flattened down to an array
func evaluate(inputs: Array) -> Array[bool]: 
	if inputs.size() != num_inputs:
		printerr("Bad input size: ", inputs.size(), ". Expecting ", num_inputs)
	
	for i in inputs.size():
		neurons[i].value = inputs[i]
	
	for key in neurons:
		var neuron = neurons[key]
		var sum = 0
		
		for j in neuron.incoming.size():
			var incoming = neuron.incoming[j]
			var other = neurons[incoming.into]
			sum += incoming.weight * other.value
		
		if neuron.incoming.size() > 0:
			neuron.value = Network.sigmoid(sum)
	
	var outputs: Array[bool] = []
	for o in num_outputs:
		outputs.append(neurons[o + max_nodes].value > 0)
	
	return outputs


