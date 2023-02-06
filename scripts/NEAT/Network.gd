class_name Network extends Resource

@export var neurons: Dictionary = {}
@export var num_inputs: int = 0
@export var num_outputs: int = 0
@export var max_nodes: int = 0

# Not used, but required for ResourceLoader
func _init(n = {}, i = 0, o = 0, mn = 0):
	neurons = n
	num_inputs = i
	num_outputs = o
	max_nodes = mn

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
			neuron.value = NEAT.sigmoid(sum)
	
	var outputs: Array[bool] = []
	for o in num_outputs:
		outputs.append(neurons[o + max_nodes].value > 0)
	
	return outputs


