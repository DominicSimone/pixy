class_name NNGrid extends NNInput

# Can represent channels with bit flags - up to 64 channels with one int
var channels: int
var size: Vector2i

var data: PackedInt64Array

func _init(_size: Vector2i, _channels: int):
	size = _size
	channels = _channels
	
	for row in size.x:
		for col in size.y:
			data.append(0)

func set_cell(row: int, col: int, _channels: Array):
	var index = row + col * size.x
	data[index] = NNGrid.bit_flags(_channels)

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

static func bit_flags(_channels: Array):
	var bitflags: int = 0
	for channel in _channels:
		bitflags |= 1 << channel
	return bitflags
