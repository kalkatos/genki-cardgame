@tool
@icon("uid://ba00b4aryg4g5")
class_name Grid
extends Zone

@export var distance: Vector2 = Vector2(3.0, 3.0)

var grid: Dictionary[Vector2i, Node]


func _organize ():
	for pos in grid:
		var target_position = Vector3(pos.x * distance.x, pos.y * distance.y, 0)
		if (
				grid[pos].position == target_position
				and grid[pos].rotation_degrees == Vector3.ZERO
		):
			continue
		var tween = grid[pos].create_tween()
		tween.tween_property(grid[pos], "position", target_position, 0.2)
		tween.parallel().tween_property(grid[pos], "rotation_degrees", Vector3.ZERO, 0.2)
		tween.parallel().tween_property(grid[pos], "scale", Vector3.ONE, 0.2)


func add_to_grid (node: Node, pos: Vector2i):
	if grid.has(pos) and grid[pos]:
		Debug.log_warning("When adding a new node, removed node %s at position %s" % [str(grid[pos]), str(pos)])
		remove_item(grid[pos])
	grid[pos] = node
	add_item(node)


func remove_from_grid (pos: Vector2i) -> Node:
	if not grid.has(pos):
		return null
	var node = grid[pos]
	grid.erase(pos)
	remove_item(node)
	return node
