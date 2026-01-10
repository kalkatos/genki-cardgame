class_name CardData
extends Resource

@export var fields: Dictionary[String, Variant]

func get_name() -> String:
	return resource_path.get_file().trim_suffix('.tres')
