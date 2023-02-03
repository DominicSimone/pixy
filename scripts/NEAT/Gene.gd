class_name Gene extends Resource
var into = 0
var out = 0
var weight = 0.0
var enabled: bool = true
var innovation: int = 0

func copy() -> Gene:
	var copy = Gene.new()
	copy.into = into
	copy.out = out
	copy.weight = weight
	copy.enabled = enabled
	copy.innovation = innovation
	return copy
