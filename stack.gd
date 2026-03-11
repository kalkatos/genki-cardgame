@tool
@icon("uid://djlh8cto0xekt")
class_name Stack
## A zone type that organizes its children in a simple linear stack or line (e.g., a deck or discard pile).
extends Zone

@export var direction: Vector3 = Vector3.UP
@export var distance: float


## Organizes all nodes in a linear stack based on the defined direction and distance.
func _organize ():
	var i = 0
	# Iterate through children and offset them by current index
	for child in get_children():
		child.global_position = global_position + distance * i * direction
		child.scale = Vector3.ONE
		child.rotation = Quaternion.IDENTITY
		i += 1
