class_name NNValue extends NNInput

var value

func _init(val):
	value = val

func flatten() -> Array:
	return [value]

func get_input_count():
	return 1
