class_name Neuron extends Resource

@export var incoming: Array[Gene]
@export var value = 0.0
var depth: int = -1

# Not used, but required for ResourceLoader
func _init(i: Array[Gene] = [], v = 0.0):
	incoming = i
	value = v
