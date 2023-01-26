class_name NNValue extends NNInput

var value

func flatten() -> Array:
	return [value]

func get_input_count():
	return 1
