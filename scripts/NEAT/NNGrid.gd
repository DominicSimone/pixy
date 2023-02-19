class_name NNGrid extends NNInput

var channels: int
var size: Vector2i

var data: PackedFloat32Array

func _init(_size: Vector2i, _channels: int):
	size = _size
	channels = _channels
	
	for row in size.x:
		for col in size.y:
			for c in channels:
				data.append(0)

func set_cell(row: int, col: int, channel: int, value: float):
	var index = row + col * size.x + size.x * size.y * channel
	data[index] = value

func describe(newline: bool):
	var string: String = ""
	for col in range(size.y - 1, -1, -1):
		for row in size.x:
			string += "%d" % data[row + col * size.x]
		string += "\n"
	if newline:
		string += "\n"
	return string

func flatten():
	return data

func get_size():
	return channels * size.x * size.y
