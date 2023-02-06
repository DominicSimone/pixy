class_name MutationRates extends Resource

@export var step_size = 0.1
@export var node_mutation_chance = 0.50
@export var link_mutation_chance = 2.0
@export var bias_mutation_chance = 0.40
@export var mutate_connections_chance = 0.25
@export var disable_mutation_chance = 0.4
@export var enable_mutation_chance = 0.2

# Not used, but required for ResourceLoader
func _init(ss = 0.1, nmc = 0.5, lmc = 2.0, bmc = 0.4, mcc = 0.25, dmc = 0.4, emc = 0.2):
	step_size = ss
	node_mutation_chance = nmc
	link_mutation_chance = lmc
	bias_mutation_chance = bmc
	mutate_connections_chance = mcc
	disable_mutation_chance = dmc
	enable_mutation_chance = emc

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
