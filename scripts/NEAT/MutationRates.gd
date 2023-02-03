class_name MutationRates extends Resource
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
