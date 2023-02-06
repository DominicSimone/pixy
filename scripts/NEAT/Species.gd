class_name Species extends Resource

@export var top_fitness = 0
@export var avg_fitness = 0
@export var staleness = 0
@export var genomes: Array[Genome]

# Not used, but required for ResourceLoader
func _init(tf = 0, af = 0, s = 0, g: Array[Genome] = []):
	top_fitness = tf
	avg_fitness = af
	staleness = s
	genomes = g

func calc_avg_fitness_rank():
	var total: int = genomes.reduce(func(acc, el): return acc + el.global_rank, 0)
	avg_fitness = total / genomes.size()

func breed_child(config: NEATConfig) -> Genome:
	var child: Genome
	
	if randf() < config.crossover_chance:
		child = Genome.crossover(genomes.pick_random(), genomes.pick_random())
	else:
		child = genomes.pick_random().copy()
	
	child.mutate(config)
	
	return child
