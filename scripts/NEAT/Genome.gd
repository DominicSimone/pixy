class_name Genome extends Resource

@export var genes: Array[Gene] = []
@export var fitness = 0
@export var adjusted_fitness = 0
@export var max_neuron = 0
@export var global_rank = 0
@export var mutation_rates: MutationRates = null

# Not used, but required for ResourceLoader
func _init(g: Array[Gene] = [], f = 0, adjf = 0, mn = 0, gr = 0, mr = null):
	genes = g
	fitness = f
	adjusted_fitness = adjf
	max_neuron = mn
	global_rank = gr
	mutation_rates = mr

func genome_string():
	return genes.reduce(func(acc, g):
		if g.enabled:
			return acc + "%d-%d " % [g.out, g.into]
		else:
			return acc
		, "")
	
func copy() -> Genome:
	var copy = Genome.new()
	copy.genes = genes.duplicate(true)
	#copy.fitness = fitness
	#copy.adjusted_fitness = adjusted_fitness
	copy.max_neuron = max_neuron
	#copy.global_rank = global_rank
	copy.mutation_rates = mutation_rates.copy()
	return copy

func mutate(config: NEATConfig):
	for property in mutation_rates.get_property_list():
		if property.usage != PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		var rate = mutation_rates.get(property.name)
		if randf() < 0.5:
			mutation_rates.set(property.name, rate * 0.95)
		else:
			mutation_rates.set(property.name, rate * 1.05263)
	
	if randf() < mutation_rates.mutate_connections_chance:
		point_mutate(config)
	
	var p = mutation_rates.link_mutation_chance
	while p > 0:
		if randf() < p:
			link_mutate(false, config)
		p -= 1
	
	p = mutation_rates.bias_mutation_chance
	while p > 0:
		if randf() < p:
			link_mutate(true, config)
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
	gene1.innovation = Neat.innovation()
	gene1.enabled = true
	genes.append(gene1)
	
	var gene2 = gene.copy()
	gene2.into = max_neuron
	gene2.innovation = Neat.innovation()
	gene2.enabled = true
	genes.append(gene2)

# Try to connect two nodes (cannot connect two input nodes together)
func link_mutate(force_bias: bool, config: NEATConfig):
	var neuron1 = random_neuron(false, config)
	var neuron2 = random_neuron(true, config)
	var num_inputs = config.inputs
	
	var new_link = Gene.new()
	if neuron1 <= num_inputs and neuron2 <= num_inputs:
		# Both input nodes
		return
	if neuron2 <= num_inputs:
		var temp = neuron1
		neuron1 = neuron2
		neuron2 = temp
	
	new_link.into = neuron1
	new_link.out = neuron2
	
	if force_bias:
		new_link.into = num_inputs
	
	if contains_link(new_link.into, new_link.out):
		return
	
	new_link.innovation = Neat.innovation()
	new_link.weight = randf() * 4 - 2
	
	genes.append(new_link)

func point_mutate(config: NEATConfig):
	var step = mutation_rates.step_size
	
	for gene in genes:
		if randf() < config.perturb_chance:
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
func random_neuron(non_input: bool, config: NEATConfig):
	var neurons = {}
	var num_inputs = config.inputs
	var num_outputs = config.outputs
	
	# This block seems like its filtering available neurons to choose?
	if not non_input:
		for i in num_inputs:
			neurons[i] = true
	for o in num_outputs:
		neurons[config.max_nodes + o] = true
	for i in genes.size():
		if not non_input or genes[i].into > num_inputs:
			neurons[genes[i].into] = true
		if not non_input or genes[i].out > num_inputs:
			neurons[genes[i].out] = true
	
	var rand_index = randi_range(0, neurons.size() - 1)
	for key in neurons:
		rand_index -= 1
		if rand_index < 0:
			return key

static func basic(config: NEATConfig) -> Genome:
	var genome = Genome.new()
	genome.max_neuron = config.inputs
	genome.mutation_rates = config.mutation_rates.copy()
	genome.mutate(config)
	return genome

static func same_species(first: Genome, second: Genome, config: NEATConfig) -> bool:
	var dd = config.delta_disjoint * disjoint(first, second)
	var dw = config.delta_weights * weights(first, second)
	return (dd + dw) < config.delta_threshold

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
		if first_genes.has(gene.innovation):
			disjoint_genes += 1
		
	for gene in first.genes:
		if second_genes.has(gene.innovation):
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
		if gene2 != null and gene2.enabled and randi_range(1, 2) == 1:
			child.genes.append(gene2.copy())
		else:
			child.genes.append(gene.copy())
	
	child.max_neuron = max(g1.max_neuron, g2.max_neuron)
	child.mutation_rates = g1.mutation_rates.copy()
	
	return child
