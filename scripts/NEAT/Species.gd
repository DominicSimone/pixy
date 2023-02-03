class_name Species extends Resource
var parent_pool: Pool
var top_fitness = 0
var avg_fitness = 0
var staleness = 0
var genomes: Array[Genome]

func describe():
	print("Species (", genomes.size(), " genomes) ", self)
	print("\tTop/Avg/Staleness: ", top_fitness, "/", avg_fitness, "/", staleness)

func calc_avg_fitness_rank():
	var total: int = genomes.reduce(func(acc, el): return acc + el.global_rank, 0)
	avg_fitness = total / genomes.size()

func breed_child() -> Genome:
	var child: Genome
	
	if randf() < parent_pool.config.crossover_chance:
		child = Genome.crossover(genomes.pick_random(), genomes.pick_random())
	else:
		child = genomes.pick_random().copy()
	
	child.mutate()
	
	return child
