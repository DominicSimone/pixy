class_name NNGrid extends NNInput

# Can represent channels with bit flags - up to 64 channels with one int
var channels: int
var size: Vector2i

var data: Array[PackedInt64Array]

func _init(_size, _channels):
	size = _size
	channels = _channels
	
	for row in size.x:
		data.append(PackedInt64Array())
		for col in size.y:
			data[row].append(0)

func set_cell(row: int, col: int, channels: Array):
	data[row][col] = bit_flags(channels)

func get_input_count():
	return channels * size.x * size.y

static func bit_flags(channels: Array):
	var bitflags: int = 0
	for channel in channels:
		bitflags = bitflags | (1 << channel)
	return bitflags
