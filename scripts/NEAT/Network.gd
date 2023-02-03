class_name Network extends Resource

var neurons: Dictionary = {}
var parent_pool: Pool
var num_inputs: int
var num_outputs: int

static func generate(genome: Genome):
	var network = Network.new()
	network.parent_pool = genome.parent_pool
	network.num_inputs = network.parent_pool.config.inputs
	network.num_outputs = network.parent_pool.config.outputs
	
	for i in network.num_inputs:
		network.neurons[i] = Neuron.new()
	
	for o in network.num_outputs:
		network.neurons[o+network.parent_pool.config.max_nodes] = Neuron.new()
	
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
		outputs.append(neurons[o + parent_pool.config.max_nodes].value > 0)
	
	return outputs


