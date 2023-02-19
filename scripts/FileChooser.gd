class_name FileChooser extends MenuButton

signal path_chosen(file_path: String)

@export var base_path = "res://saved_pools"

var file_to_path: Dictionary = {}

func _ready():
	get_popup().connect("index_pressed", index_pressed)

func index_pressed(index):
	var path = file_to_path.get(get_popup().get_item_text(index))
	var full_path = "%s/%s" % [base_path, path]
	path_chosen.emit(full_path)

func _on_about_to_popup():
	populate_paths()
	get_popup().clear()
	for file in file_to_path:
		get_popup().add_item(file)

func populate_paths():
	var dir = DirAccess.open(base_path)
	file_to_path = {}
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				file_to_path[file_name] = "%s/%s" % [base_path, file_name]
				file_name = dir.get_next()
	else:
		printerr("An error occurred when trying to access the path.")
