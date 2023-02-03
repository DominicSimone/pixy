class_name Pool extends Resource
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

func describe_string():
	return "Pool (%d species)\nTimeout: %d\nCurrent generation/species/genome: %d.%d.%d" % \
	[species.size(), timeout, generation, current_species, current_genome]

func describe():
	print(describe_string())

func _init(_config: NEATConfig):
	config = _config
	innovations = config.outputs
	
	for i in config.population:
		add_to_species(Genome.basic(config.inputs, self))
	
	initialize_run()

func fitness_already_measured():
	return species[current_species].genomes[current_genome].fitness != 0

func next_genome():
	current_genome += 1
	if current_genome >= species[current_species].genomes.size():
		current_genome = 0
		current_species += 1
		if current_species >= species.size():
			new_generation()
			current_species = 1

func initialize_run():
	current_frame = 0
	current_high_score = 0
	timeout = config.timeout_constant
	var genome = species[current_species].genomes[current_genome]
	current_network = Network.generate(genome)

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
	child_species.parent_pool = self
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
		spec.genomes.sort_custom(func(a,b): return a.fitness > b.fitness)
		
		var remaining = ceil(spec.genomes.size() / 2.0)
		if cut_to_one:
			remaining = 1
		
		spec.genomes.resize(remaining)

func total_avg_fitness():
	return species.reduce(func(acc, s): return acc + s.avg_fitness, 0.0)

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
