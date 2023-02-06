class_name Gene extends Resource

@export var into = 0
@export var out = 0
@export var weight = 0.0
@export var enabled: bool = true
@export var innovation: int = 0

# Not used, but required for ResourceLoader
func _init(i = 0, o = 0, w = 0.0, e = true, inn = 0):
	into = i
	out = o
	weight = w
	enabled = e
	innovation = inn

func copy() -> Gene:
	var copy = Gene.new()
	copy.into = into
	copy.out = out
	copy.weight = weight
	copy.enabled = enabled
	copy.innovation = innovation
	return copy
