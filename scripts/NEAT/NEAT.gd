class_name NEAT extends Resource

const e: float = 2.71828183
static func sigmoid(x):
	return 2 / (1 + pow(e, -4.9 * x)) - 1

# TODO swap out Array for Dictionary?

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

	# TODO make this a MutationRates object?
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
	var config: NEATConfig
	
	func new_generation():
		# BOOK 777
		pass
	
	func add_to_species(child: Genome):
		for spec in species:
			if Genome.same_species(child, spec.genomes[0]):
				spec.genomes.append(child)
				return
		
		var child_species = Species.new()
		child_species.genomes.append(child)
		species.append(child_species)
	
	func remove_weak_species():
		var survived: Array[Species] = []
		
		var sum = total_avg_fitness()
		for spec in species:
			var breed = floor(spec.avg_fitness / sum * config.population)
			if breed >= 1:
				survived.append(spec)
		
		species = survived
	
	func remove_stale_species():
		var survived: Array[Species] = []
		
		for spec in species:
			
			spec.genomes.sort_custom(func(a,b): return a.fitness > b.fitness)
			
			if spec.genomes[0].fitness > spec.top_fitness:
				spec.top_fitness = spec.genomes[0].fitness
				spec.staleness = 0
			else:
				spec.staleness += 1
			
			if spec.staleness < config.stale_species or spec.top_fitness >= max_fitness:
				survived.append(spec)
		
		species = survived
	
	func cull_species(cut_to_one: bool):
		for spec in species:
			spec.genomes.sort_custom(func(a,b): a.fitness > b.fitness)
			
			var remaining = ceil(spec.genomes.size() / 2.0)
			if cut_to_one:
				remaining = 1
			
			spec.genomes.resize(remaining)
	
	func total_avg_fitness():
		return species.reduce(func(acc, s): acc + s.avg_fitness, 0.0)
	
	func rank_globally():
		var all_genomes = []
		for spec in species:
			for genome in spec.genomes:
				all_genomes.append(genome)
		
		all_genomes.sort_custom(func(a, b): return a.fitness < b.fitness)
		
		for rank in all_genomes.size():
			all_genomes[rank].global_rank = rank

	func new_innovation() -> int:
		innovations += 1
		return innovations

class Species extends Resource:
	var parent_pool: Pool
	var top_fitness = 0
	var avg_fitness = 0
	var staleness = 0
	var genomes: Array[Genome]
	
	func calc_avg_fitness_rank():
		var total = genomes.reduce(func(a,b): return a + b) as float
		avg_fitness = total / genomes.size()
	
	func breed_child():
		var child: Genome
		
		if randf() < parent_pool.config.crossover_chance:
			child = Genome.crossover(genomes.pick_random(), genomes.pick_random())
		else:
			child = genomes.pick_random().duplicate(true)
		
		child.mutate()
		
		return child

class Genome extends Resource:
	var parent_pool: Pool
	var genes = Array[Gene]
	var fitness = 0
	var adjusted_fitness = 0
	var network: Network
	var max_neuron = 0
	var global_rank = 0
	var mutation_rates: MutationRates 
	
	func mutate():
		
		for property in mutation_rates.get_property_list():
			var rate = mutation_rates._get(property.name)
			if randf() < 0.5:
				mutation_rates._set(property.name, rate * 0.95)
			else:
				mutation_rates._set(property.name, rate * 1.05263)
		
		if randf() < mutation_rates.connections:
			point_mutate()
		
		var p = mutation_rates.link
		while p > 0:
			if randf() < p:
				link_mutate(false)
			p -= 1
		
		p = mutation_rates.bias
		while p > 0:
			if randf() < p:
				link_mutate(true)
			p -= 1
		
		p = mutation_rates.node
		while p > 0:
			if randf() < p:
				node_mutate()
			p -= 1
		
		p = mutation_rates.enable
		while p > 0:
			if randf() < p:
				enable_disable_mutate(true)
			p -= 1
		
		p = mutation_rates.disable
		while p > 0:
			if randf() < p:
				enable_disable_mutate(false)
			p -= 1
	
	func enable_disable_mutate(toggle_value: bool):
		var candidates = []
		for gene in genes:
			if gene.enabled != toggle_value:
				candidates.append(gene)
		
		if candidates.is_empty():
			return
		
		candidates.pick_random().enabled = toggle_value 
	
	func node_mutate():
		if genes.is_empty():
			return
		
		max_neuron += 1
		
		var gene = genes.pick_random()
		if not gene.enabled:
			return
		
		gene.enabled = false
		
		var gene1 = gene.duplicate(true)
		gene1.out = max_neuron
		gene1.weight = 1.0
		gene1.innovation = parent_pool.new_innovation()
		gene1.enabled = true
		genes.append(gene1)
		
		var gene2 = gene.duplicate(true)
		gene2.into = max_neuron
		gene2.innovation = parent_pool.new_innovation()
		gene2.enabled = true
		genes.append(gene2)
	
	# Try to connect two nodes (cannot connect two input nodes together)
	# TODO this seems like it should be modifying the network as well, but it only modifies the genome
	func link_mutate(force_bias: bool):
		var neuron1 = random_neuron(false)
		var neuron2 = random_neuron(true)
		
		var new_link = Gene.new()
		if neuron1 <= network.num_inputs and neuron2 <= network.num_inputs:
			# Both input nodes
			return
		if neuron2 <= network.num_inputs:
			var temp = neuron1
			neuron1 = neuron2
			neuron2 = temp
		
		new_link.into = neuron1
		new_link.out = neuron2
		
		if force_bias:
			new_link.into = network.num_inputs
		
		if contains_link(new_link.into, new_link.out):
			return
		
		new_link.innovation = parent_pool.new_innovation()
		new_link.weight = randf() * 4 - 2
		
		genes.append(new_link)
	
	func point_mutate():
		var step = mutation_rates.step
		
		for gene in genes:
			if randf() < network.config.perturb_chance:
				gene.weight += randf() * step * 2 - step
			else:
				gene.weight = randf() * 4 - 2
	
	func contains_link(into, out) -> bool:
		for gene in genes:
			if gene.into == into and gene.out == out:
				return true
		return false
	
	# Pick a random neuron, with the option of ignoring input neurons
	# This seems like Lua made this a nightmare, can be simplified greatly
	func random_neuron(non_input: bool):
		var neurons = {}
		
		# This block seems like its filtering available neurons to choose?
		if not non_input:
			for i in network.num_inputs:
				neurons[i] = true
		for o in network.num_outputs:
			neurons[network.config.max_nodes + o] = true
		for i in genes.size():
			if not non_input or genes[i].into > network.num_inputs:
				neurons[genes[i].into] = true
			if not non_input or genes[i].out > network.num_inputs:
				neurons[genes[i].out] = true
		
		return randi_range(0, neurons.size() - 1)
	
	static func basic() -> Genome:
		var genome = Genome.new()
		# local innovation = 1
		# genome._neuron = Inputs
		genome.mutate()
		return genome
	
	static func same_species(first: Genome, second: Genome) -> bool:
		var dd = first.parent_pool.config.delta_disjoint * disjoint(first, second)
		var dw = first.parent_pool.config.delta_weights * weights(first, second)
		return (dd + dw) < first.parent_pool.config.delta_threshold
	
	static func weights(first: Genome, second: Genome):
		var second_genes = {}
		for gene in second.genes:
			second_genes[gene.innovation] = gene
			
		var sum = 0.0
		var coincident = 0.0
		
		for gene in first.genes:
			if second_genes.has(gene.innovation):
				sum += abs(gene.weight - second_genes[gene.innovation].weight)
				coincident += 1
		
		return sum / coincident
	
	static func disjoint(first: Genome, second: Genome) -> float:
		var first_genes = {}
		var second_genes = {}
		var disjoint_genes = 0.0
		
		for gene in first.genes:
			first_genes[gene.innovation] = true
		
		for gene in second.genes:
			second_genes[gene.innovation] = true
			if first_genes[gene.innovation] == false:
				disjoint_genes += 1
			
		for gene in first.genes:
			if second_genes[gene.innovation] == false:
				disjoint_genes += 1
		
		return disjoint_genes / max(first_genes.size(), second_genes.size())
	
	static func crossover(first: Genome, second: Genome) -> Genome:
		var child = Genome.new()
		
		# g1 should be the genome with higher fitness score
		var g1: Genome = second
		var g2: Genome = first
		if first.fitness > second.fitness:
			g1 = first
			g2 = second
		
		var innovations2 = {}
		for gene in g2.genes:
			innovations2[gene.innovation] = gene
		
		for gene in g1.genes:
			var gene2 = innovations2.get(gene.innovation)
			if gene2 == null and gene2.enabled and randi_range(1, 2) == 1:
				child.genes.append(gene2.duplicate(true))
			else:
				child.genes.append(gene.duplicate(true))
		
		child.max_neuron = max(g1.max_neuron, g2.max_neuron)
		child.mutation_rates = g1.mutation_rates.duplicate(true)
		
		return child

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
	var neurons: Array[Neuron] # Might need to be a Dictionary to cope with large max index and null values
	# could also move to using max_nodes and max_nodes_per_network so we can limit size of array
	var config: NEATConfig
	var num_inputs: int
	var num_outputs: int
	
	# TODO make sure number of nodes present in neurons reflects the +1 from the bias node input
	static func generate(genome: Genome, config: NEATConfig, num_inputs: int, num_outputs: int):
		var network = Network.new()
		network.config = config.duplicate(true)
		network.num_inputs = num_inputs
		network.num_outputs = num_outputs
		network.neurons.resize(num_outputs + config.max_nodes) # ~spooky~
		
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


