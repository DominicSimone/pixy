class_name NEAT extends Node

const e: float = 2.71828183
static func sigmoid(x):
	return 2 / (1 + pow(e, -4.9 * x)) - 1

var pool: Pool
var response: NEATResponse

var label: Label
var label_enabled: bool = false
var last_frame_score: int = 0
var idle_counter: int = 0

var start_time: int = 0
var run_time: int = 0
var frame_time: int = 0
var prev_frame_time: int = 0

var paused: bool = false :
	set(p):
		paused = p
		Engine.time_scale = 0 if p else sim_speed

var sim_speed: int = 1 :
	set(speed):
		sim_speed = speed
		# Capped by max_fps (and by extension vsync)
		Engine.physics_ticks_per_second = 60*speed
		Engine.time_scale = speed
		Engine.max_fps = 60 * speed
		

# TODO load a saved pool / save/load the best genome in a pool
# Loading only works once..., then the resource will not be updated upon loading again
# Saving always seems to work correctly
# TODO better display of neural net

func connect_label(text_label):
	label = text_label
	label_enabled = true

func update_label():
	label_enabled = true

func save_pool():
	print("Saving pool...")
	paused = true
	var error = ResourceSaver.save(pool, "res://pool.tres")
	paused = false
	print(error)
	
func load_pool():
	print("Loading pool...")
	paused = true
	pool = ResourceLoader.load("res://pool.tres", "", ResourceLoader.CACHE_MODE_REPLACE)
	paused = false
	print(pool)

func prepare_inputs(inputs: Array[NNInput]):
	var flat = []
	for input in inputs:
		flat.append_array(input.flatten())
	flat.append(1)
	return flat

func register_game(inputs: Array[NNInput], num_outputs: int):
	var config = NEATConfig.new()
	config.inputs = inputs.reduce(func(acc, el): return acc + el.get_size(), 0) + 1
	config.outputs = num_outputs
	response = NEATResponse.new(num_outputs)
	print("Registered game with ", config.inputs, " inputs and ", config.outputs, " outputs.")
	pool = Pool.new(config)
	pool.startup()

func innovation() -> int:
	return pool.new_innovation()

# Called at the start of every game tick
func frame(current_score: int, inputs: Array[NNInput]) -> NEATResponse:
	if paused:
		return response
	# Time keeping
	if start_time == 0:
		start_time = Time.get_ticks_msec()
	frame_time = Time.get_ticks_msec() - prev_frame_time
	prev_frame_time = Time.get_ticks_msec()
	run_time = Time.get_ticks_msec() - start_time
	
	pool.current_frame += 1
	
	if response.reset_flag:
		response.reset_flag = false
	
	# This block directly leads to a 1mb/second memory leak, restricting updates for now
	if label_enabled:
		label_enabled = false
		label.text = "Runtime: %02d:%02d:%02d (%d ms/frame)\n" % \
			[(run_time / 1000 / 60 / 60), (run_time / 1000 / 60) % 60, (run_time / 1000) % 60, frame_time]
		label.text += pool.describe_string()
		label.text += "\nMax fitness/Current score: %d/%d" % [pool.max_fitness, current_score] 
		label.text += "\nOutput: " + response.describe_string() + "\n"
		label.text += "Inputs:\n"
		label.text += inputs[0].describe(true)
		label.text += inputs[1].describe(true)
		label.text += inputs[2].describe(true)
		label.text += "Genome: " + pool.species[pool.current_species].genomes[pool.current_genome].genome_string()
	
	# run the network and getting outputs, quick restart if idle
	if pool.current_frame % 5 == 0:
		response.outputs = pool.current_network.evaluate(prepare_inputs(inputs))
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
		
	return response
