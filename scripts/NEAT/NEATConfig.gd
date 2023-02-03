class_name NEATConfig extends Resource
var timeout_constant = 150
var timeout_bonus_ratio = 0.0
var max_nodes = 1000000

var population = 50 #300
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
