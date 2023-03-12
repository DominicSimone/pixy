class_name NEAT extends Node

enum Mode {
	PLAYER,
	GENOME,
	POOL
}

var pool: Pool
var genome_network: Network
var response: NEATResponse
var config: NEATConfig
var network_visual: NetworkVisual

var last_frame_score: int = 0
var idle_counter: int = 0

var genome_frame_counter: int = 0

var current_mode: Mode = Mode.PLAYER

var paused: bool = false :
	set(p):
		paused = p
		Engine.time_scale = 0 if p else sim_speed

var sim_speed: int = 1 :
	set(speed):
		sim_speed = speed
		# Capped by max_fps (and by extension vsync)
		Engine.physics_ticks_per_second = max(60, 60*speed)
		Engine.time_scale = speed
		Engine.max_fps = max(60, 60 * speed)

# TODO add game name/id to save (some variety of metadata that describes
# compatability with what the current game is sending NEAT
func save_best_genome():
	paused = true
	pool.rank_globally()
	var genome: Genome = pool.best_genome
	var path = "res://saved_genomes/genome-%df-%s.res" % [genome.fitness, genome.genome_hash()]
	print("Saving best genome to ", path)
	print(ResourceSaver.save(pool.best_genome, path))
	paused = false

func load_genome(file_path):
	print("Loading genome from ", file_path)
	paused = true
	var genome = ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	genome_network = Network.generate(genome, config)
	paused = false
	print(genome)

func save_pool():
	paused = true
	var path = "res://saved_pools/pool-%dg-%dmf.res" % [pool.generation, pool.max_fitness]
	print("Saving pool to ", path)
	print(ResourceSaver.save(pool, path))
	paused = false

func load_pool(file_path):
	print("Loading pool from ", file_path)
	paused = true
	pool = ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	paused = false
	print(pool)

func prepare_inputs(inputs: Array[NNInput]):
	var flat = []
	for input in inputs:
		flat.append_array(input.flatten())
	return flat

# TODO add game name in register, include name when saving/loading genomes
func register_game(inputs: Array[NNInput], num_outputs: int):
	config = NEATConfig.new()
	config.inputs = inputs.reduce(func(acc, el): return acc + el.get_size(), 0)
	config.outputs = num_outputs
	response = NEATResponse.new(num_outputs)
	print("Registered game with ", config.inputs, " inputs and ", config.outputs, " outputs.")
	pool = Pool.new(config)
	pool.startup()

# Called at the start of every game tick
func frame(current_score: int, inputs: Array[NNInput]) -> NEATResponse:
	if paused or sim_speed == 0:
		return response

	match current_mode:
		Mode.POOL:
			pool_frame(current_score, inputs)
		Mode.GENOME:
			genome_frame(inputs)
		Mode.PLAYER:
			return NEATResponse.new(response.outputs.size())
	
	return response


func genome_frame(inputs: Array[NNInput]):
	genome_frame_counter += 1
	if genome_network != null and genome_frame_counter % 5 == 0:
		network_visual.visualize(genome_network, inputs)
		response.outputs = genome_network.evaluate(prepare_inputs(inputs))
		network_visual.update()

func pool_frame(current_score: int, inputs: Array[NNInput]):
	pool.current_frame += 1
	
	if response.reset_flag:
		response.reset_flag = false

	# run the network and getting outputs, quick restart if idle
	if pool.current_frame % 5 == 0:
		network_visual.visualize(pool.current_network, inputs)
		response.outputs = pool.current_network.evaluate(prepare_inputs(inputs))
		network_visual.update()
		# Quick restart if the NN isn't doing anything for two evaluations in a row, and score is unchanging
		if not response.outputs.any(func(a): return a):
			if current_score == last_frame_score:
				idle_counter += 1
			if idle_counter > 5:
				pool.timeout = 0
			last_frame_score = current_score
		else:
			idle_counter = 0
	
	# reset timeout timer if score has gone up
	if current_score > pool.current_high_score:
		pool.current_high_score = current_score
		pool.timeout = pool.config.timeout_constant

	pool.timeout -= 1

	if pool.timeout + pool.config.timeout_bonus_ratio * pool.current_frame <= 0:
		var fitness = pool.current_high_score #- pool.current_frame / 2
		if fitness == 0:
			fitness = -1
		pool.species[pool.current_species].genomes[pool.current_genome].fitness = fitness
		
		if fitness > pool.max_fitness:
			pool.max_fitness = fitness
		
		pool.current_species = 0
		pool.current_genome = 0
		while pool.fitness_already_measured():
			pool.next_genome()
		pool.initialize_run()
		response.reset_flag = true
		idle_counter = 0
		response.reset_outputs()

func innovation() -> int:
	return pool.new_innovation()
