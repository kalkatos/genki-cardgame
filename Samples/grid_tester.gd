class_name GridTester
extends Grid

var _prefab: Node
var _next_slot_position: Callable = _next_slot_position_with_negatives


func _ready () -> void:
	for card in get_children():
		var next = _next_slot()
		grid[next] = card
		card.on_clicked.connect(func(_pos): _handle_click(next.x, next.y))


func _input (event: InputEvent) -> void:
	if event is InputEventKey and not event.echo and event.pressed:
		if event.keycode == KEY_D:
			Debug.logm("Adding")
			if not _prefab:
				_prefab = get_last()
				if not _prefab:
					Debug.log_error("No card is child of GridTester.")
					return
			var new_card = _prefab.duplicate()
			var next = _next_slot()
			add_to_grid(new_card, next)
			new_card.on_clicked.connect(func(_pos): _handle_click(next.x, next.y))
			_organize()
		elif event.keycode == KEY_S:
			_organize()


func _handle_click (x, y):
	var pos = Vector2i(x, y)
	if grid.has(pos):
		var card = grid[pos]
		remove_from_grid(pos)
		card.queue_free()


func _next_slot (x: int = 0, y: int = 0, depth: int = 0) -> Vector2i:
	var next = Vector2i(x, y)
	if depth == 0:
		if !grid.has(next):
			return next
		depth = 1
		x = 1
		return _next_slot(1, 0, 1)
	while true:
		if not grid.has(next):
			return next
		next = _next_slot_position.call(next.x, next.y, depth)
		if abs(next.x) > depth or abs(next.y) > depth:
			break
	return _next_slot(next.x, next.y, depth + 1)


func _next_slot_position_no_negatives (x: int, y: int, depth: int) -> Vector2i:
	if x == depth:
		if y == depth:
			return Vector2i(x - 1, y)
		return Vector2i(x, y + 1)
	if x == 0:
		return Vector2i(depth + 1, 0)
	return Vector2i(x - 1, y)


func _next_slot_position_with_negatives (x: int, y: int, depth: int) -> Vector2i:
	if x == depth:
		if y == depth:
			return Vector2i(x - 1, y)
		if y == -depth:
			return Vector2i(x + 1, y)
		return Vector2i(x, y + 1)
	if x == -depth:
		if y == -depth:
			return Vector2i(x + 1, y)
		return Vector2i(x, y - 1)
	if y == depth:
		return Vector2i(x - 1, y)
	return Vector2i(x + 1, y)
