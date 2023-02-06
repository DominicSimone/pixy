class_name NEATConfig extends Resource

@export var timeout_constant = 150
@export var timeout_bonus_ratio = 0.0
@export var max_nodes = 1000000

@export var population = 300
@export var stale_species = 15
@export var delta_disjoint = 2.0
@export var delta_weights = 0.4
@export var delta_threshold = 1.0

@export var perturb_chance = 0.90
@export var crossover_chance = 0.75

@export var inputs: int # remember to include the bias input
@export var outputs: int

@export var mutation_rates: MutationRates = MutationRates.new()

# Not used, but required for ResourceLoader
func _init(tc = 150, tbr = 0.0, mn = 100000, p = 300, ss = 15, dd = 2.0, dw = 0.4, dt = 1.0, pc = 0.9, cc = 0.75, i = 0, o = 0, mr = MutationRates.new()):
	timeout_constant = tc
	timeout_bonus_ratio = tbr
	max_nodes = mn
	population = p
	stale_species = ss
	delta_disjoint = dd
	delta_weights = dw
	delta_threshold = dt
	perturb_chance = pc
	crossover_chance = cc
	inputs = i
	outputs = o
	mutation_rates = mr

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
