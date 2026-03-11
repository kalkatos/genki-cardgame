class_name CardData
## Resource data class containing a dictionary of fields that define a card's unique properties.
extends Resource

@export var fields: Dictionary[String, Variant]

## Returns the name of the card derived from its resource filename.
func get_name () -> String:
	return resource_path.get_file().trim_suffix('.tres')
