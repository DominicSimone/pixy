class_name NEATResponse extends Resource
var outputs: Array[bool] = []
var reset_flag: bool = false
	
func _init(num_outputs: int):
	outputs.resize(num_outputs)
	reset_outputs()
	
func reset_outputs():
	for i in outputs.size():
		outputs[i] = false
	
func describe_string() -> String:
	return outputs.reduce(func(acc, el): return acc + ("1 " if el else "0 "), "")
