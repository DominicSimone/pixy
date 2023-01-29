class_name NEAT extends Node

const e: float = 2.71828183
static func sigmoid(x):
	return 2 / (1 + pow(e, -4.9 * x)) - 1

var pool: Pool
var response: NEATResponse = NEATResponse.new()

func flatten_inputs(inputs: Array[NNInput]) -> Array:
	return inputs

func register_game(inputs: Array[NNInput], num_outputs: int):
	var config = NEATConfig.new()
	config.inputs = flatten_inputs(inputs).size() + 1
	config.outputs = num_outputs
	pool = Pool.new(config)

# Called at the start of every game tick
func frame(current_score: int, inputs: Array[NNInput]) -> NEATResponse:
	pool.current_frame += 1
	
	# frequency of running the network and getting outputs
	if pool.current_frame % 5 == 0:
		response.outputs = pool.current_network.evaluate(flatten_inputs(inputs))
	
	# reset timeout timer if score has gone up
	if current_score > pool.current_high_score:
		pool.current_high_score = current_score
		pool.timeout = pool.config.timeout_constant

	pool.timeout -= 1

	var timeout_bonus = pool.current_frame / 4
	if pool.timeout + timeout_bonus <= 0:
		# this network has timed out, close it out
		# TODO
		pass

	return response


class NEATResponse:
	var outputs: Array[bool] = [false]
	var reset_flag: bool = false

class NEATConfig:
	var timeout_constant = 20
	var max_nodes = 1000000

	var population = 300
	var stale_species = 15
	var delta_disjoint = 2.0
	var delta_weights = 0.4
	var delta_threshold = 1.0

	var perturb_chance = 0.90
	var crossover_chance = 0.75

	var inputs: int # remember to include the bias input
	var outputs: int
	
	var mutation_rates: MutationRates = MutationRates.new()
	
	func copy() -> NEATConfig:
		var copy = NEATConfig.new()
		copy.timeout_constant  = copy.timeout_constant
		copy.max_nodes  = copy.max_nodes
		copy.population  = copy.population
		copy.stale_species  = copy.stale_species
		copy.delta_disjoint = copy.delta_disjoint
		copy.delta_weights = copy.delta_weights
		copy.delta_threshold = copy.delta_threshold
		copy.perturb_chance = copy.perturb_chance
		copy.crossover_chance = copy.crossover_chance
		copy.inputs = copy.inputs
		copy.outputs = copy.outputs
		copy.mutation_rates = copy.mutation_rates.copy()
		return copy

class Pool:
	var innovations: int
	var species: Array[Species]
	var generation: int = 0
	var current_species: int = 0
	var current_genome: int = 0
	var current_network: Network
	var current_frame: int = 0
	var current_high_score: int = 0
	var timeout: int = 0
	var max_fitness = 0
	var config: NEATConfig
	
	func _init(_config: NEATConfig):
		config = _config
		innovations = config.outputs
		
		for i in config.population:
			add_to_species(Genome.basic(config.inputs, self))
		
		initialize_run()
	
	func next_genome():
		current_genome += 1
		if current_genome > species[current_species].genomes.size():
			current_genome = 0
			current_species += 1
			if current_species > species.size():
				new_generation()
				current_species = 1
	
	func initialize_run():
		print("Pool initialize run")
		current_frame = 0
		current_high_score = 0
		timeout = config.timeout_constant
		var genome = species[current_species].genomes[current_genome]
		current_network = Network.generate(genome, config)
	
	func new_generation():
		cull_species(false)
		rank_globally()
		remove_stale_species()
		rank_globally()
		
		for spec in species:
			spec.calc_avg_fitness_rank()
		
		remove_weak_species()
		
		var sum = total_avg_fitness()
		var children: Array[Genome] = []
		for spec in species:
			var breed = floor(spec.avg_fitness / sum * config.population) - 1
			for i in breed:
				children.append(spec.breed_child())
	
		cull_species(true)
		
		while children.size() + species.size() < config.population:
			children.append(species.pick_random().breed_child())
		
		for child in children:
			add_to_species(child)
		
		generation += 1
		
		# TODO write file? Return something?
		
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

class Species:
	var parent_pool: Pool
	var top_fitness = 0
	var avg_fitness = 0
	var staleness = 0
	var genomes: Array[Genome]
	
	func calc_avg_fitness_rank():
		var total = genomes.reduce(func(a,b): return a + b) as float
		avg_fitness = total / genomes.size()
	
	func breed_child() -> Genome:
		var child: Genome
		
		if randf() < parent_pool.config.crossover_chance:
			child = Genome.crossover(genomes.pick_random(), genomes.pick_random())
		else:
			child = genomes.pick_random().copy()
		
		child.mutate()
		
		return child

class Genome:
	var parent_pool: Pool
	var genes: Array[Gene]
	var fitness = 0
	var adjusted_fitness = 0
	var network: Network = Network.new()
	var max_neuron = 0
	var global_rank = 0
	var mutation_rates: MutationRates 
	
	func copy() -> Genome:
		var copy = Genome.new()
		copy.parent_pool = parent_pool
		copy.genes = genes.duplicate(true)
		#copy.fitness = fitness
		#copy.adjusted_fitness = adjusted_fitness
		#copy.network = network
		copy.max_neuron = max_neuron
		#copy.global_rank = global_rank
		copy.mutation_rates = mutation_rates.copy()
		return copy
	
	func mutate():
		for property in mutation_rates.get_property_list():
			if property.usage != PROPERTY_USAGE_SCRIPT_VARIABLE:
				continue
			var rate = mutation_rates.get(property.name)
			if randf() < 0.5:
				mutation_rates.set(property.name, rate * 0.95)
			else:
				mutation_rates.set(property.name, rate * 1.05263)
		
		if randf() < mutation_rates.mutate_connections_chance:
			point_mutate()
		
		var p = mutation_rates.link_mutation_chance
		while p > 0:
			if randf() < p:
				link_mutate(false)
			p -= 1
		
		p = mutation_rates.bias_mutation_chance
		while p > 0:
			if randf() < p:
				link_mutate(true)
			p -= 1
		
		p = mutation_rates.node_mutation_chance
		while p > 0:
			if randf() < p:
				node_mutate()
			p -= 1
		
		p = mutation_rates.enable_mutation_chance
		while p > 0:
			if randf() < p:
				enable_disable_mutate(true)
			p -= 1
		
		p = mutation_rates.disable_mutation_chance
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
		
		var gene1 = gene.copy()
		gene1.out = max_neuron
		gene1.weight = 1.0
		gene1.innovation = parent_pool.new_innovation()
		gene1.enabled = true
		genes.append(gene1)
		
		var gene2 = gene.copy()
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
		var step = mutation_rates.step_size
		
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
	
	static func basic(input_size: int, pool: Pool) -> Genome:
		var genome = Genome.new()
		genome.max_neuron = input_size
		genome.parent_pool = pool
		genome.mutation_rates = pool.config.mutation_rates.copy()
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
				child.genes.append(gene2.copy())
			else:
				child.genes.append(gene.copy())
		
		child.max_neuron = max(g1.max_neuron, g2.max_neuron)
		child.mutation_rates = g1.mutation_rates.copy()
		
		return child

class MutationRates:
	var step_size = 0.1
	var node_mutation_chance = 0.50
	var link_mutation_chance = 2.0
	var bias_mutation_chance = 0.40
	var mutate_connections_chance = 0.25
	var disable_mutation_chance = 0.4
	var enable_mutation_chance = 0.2
	
	func copy() -> MutationRates:
		var copy = MutationRates.new()
		copy.step_size = step_size
		copy.node_mutation_chance = node_mutation_chance
		copy.link_mutation_chance = link_mutation_chance
		copy.bias_mutation_chance = bias_mutation_chance
		copy.mutate_connections_chance = mutate_connections_chance
		copy.disable_mutation_chance = disable_mutation_chance
		copy.enable_mutation_chance = enable_mutation_chance
		return copy

class Gene:
	var into = 0
	var out = 0
	var weight = 0.0
	var enabled: bool = true
	var innovation: int = 0
	
	func copy() -> Gene:
		var copy = Gene.new()
		copy.into = into
		copy.out = out
		copy.weight = weight
		copy.enabled = enabled
		copy.innovation = innovation
		return copy

class Neuron:
	var incoming: Array[Gene]
	var value = 0.0

class Network:
	var neurons: Dictionary = {}
	var config: NEATConfig
	var num_inputs: int
	var num_outputs: int
	
	static func generate(genome: Genome, config: NEATConfig):
		var network = Network.new()
		network.config = config.copy()
		network.num_inputs = config.inputs
		network.num_outputs = config.outputs
		
		for i in network.num_inputs:
			network.neurons[i] = Neuron.new()
		
		for o in network.num_outputs:
			network.neurons[o+config.max_nodes] = Neuron.new()
		
		genome.genes.sort_custom(func(a, b): return a.out < b.out)
		
		for gene in genome.genes:
			if gene.enabled:
				if network.neurons[gene.out] == null:
					network.neurons[gene.out] = Neuron.new()
				
				network.neurons[gene.out].incoming.append(gene)
				
				if network.neurons[gene.into] == null:
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
			outputs.append(neurons[o + config.max_nodes].value > 0)
		
		return outputs


