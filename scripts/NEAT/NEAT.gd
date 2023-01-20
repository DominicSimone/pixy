class_name NEAT extends Resource

const e: float = 2.71828183
static func sigmoid(x):
	return 2 / (1 + pow(e, -4.9 * x)) - 1

class NEATConfig extends Resource:
	var timeout_constant = 20
	var max_nodes = 1000000

	var population = 300
	var stale_species = 15
	var delta_disjoint = 2.0
	var delta_weights = 0.4
	var delta_threshold = 1.0

	var perturb_chance = 0.90
	var crossover_chance = 0.75

	var step_size = 0.1
	var node_mutation_chance = 0.50
	var link_mutation_chance = 2.0
	var bias_mutation_chance = 0.40
	var mutate_connections_chance = 0.25
	var disable_mutation_chance = 0.4
	var enable_mutation_chance = 0.2

class Pool extends Resource:
	var innovations: int = 0 # Set to number of outputs initially?
	var species: Array[Species]
	var generation: int = 0
	var current_species: int = 0
	var current_genome: int = 0
	var max_fitness = 0

class Species extends Resource:
	var top_fitness = 0
	var avg_fitness = 0
	var staleness = 0
	var genomes: Array

class Genome extends Resource:
	var genes = Array[Gene]
	var fitness = 0
	var adjusted_fitness = 0
	var network: Network
	var max_neuron = 0
	var global_rank = 0
	var mutation_rates: MutationRates 
	
	func mutate():
		pass
	
	static func basic() -> Genome:
		var genome = Genome.new()
		# local innovation = 1
		# genome.max_neuron = Inputs
		genome.mutate()
		return genome
	
	static func crossover(g1: Genome, g2: Genome) -> Genome:
		var genome = Genome.new()
		
		# BOOKMARK TODO 385
		return genome

class MutationRates extends Resource:
	var connections
	var link
	var bias
	var node
	var enable
	var disable
	var step

class Gene extends Resource:
	var into = 0
	var out = 0
	var weight = 0.0
	var enabled: bool = true
	var innovation: int = 0

class Neuron extends Resource:
	var incoming: Array[Gene]
	var value = 0.0

class Network extends Resource:
	var neurons: Array[Neuron]
	var config: NEATConfig
	var num_inputs: int
	var num_outputs: int
	
	# TODO make sure number of nodes present in neurons reflects the +1 from the bias node input
	static func generate(genome: Genome, config: NEATConfig, num_inputs: int, num_outputs: int):
		var network = Network.new()
		network.config = config.duplicate()
		network.num_inputs = num_inputs
		network.num_outputs = num_outputs
		network.neurons.resize(num_outputs + config.max_nodes)
		
		for i in num_inputs:
			network.neurons[i] = Neuron.new()
		
		for o in num_outputs:
			network.neurons[o+config.max_nodes] = Neuron.new()
		
		genome.genes.sort(func(a, b): return a.out < b.out)
		
		for gene in genome.genes:
			if gene.enabled:
				if network.neurons[gene.out] == null:
					network.neurons[gene.out] = Neuron.new()
				
				network.neurons[gene.out].incoming.append(gene)
				
				if network.neurons[gene.into] == null:
					network.neurons[gene.into] = Neuron.new()
		
		return network
		
	# real inputs, flattened down to an array
	# TODO change output from mapping value -> bool to just returning slice of values corresponding
	# to output nodes
	func evaluate(inputs: Array) -> Array[bool]: 
		if inputs.size() != num_inputs:
			printerr("Bad input size: ", inputs.size(), ". Expecting ", num_inputs)
		inputs.append(1)
		
		for i in inputs.size():
			neurons[i].value = inputs[i]
		
		for neuron in neurons:
			var sum = 0
			
			for j in neuron.incoming.size():
				var incoming = neuron.incoming[j]
				var other = neurons[incoming.into]
				sum += incoming.weight * other.value
			
			if neuron.incoming.size() > 0:
				neuron.value = NEAT.sigmoid(sum)
		
		var outputs: Array[bool] = []
		for o in num_outputs:
			if neurons[o + config.max_nodes].value > 0:
				outputs[o] = true
			else:
				outputs[o] = false
		
		return outputs


