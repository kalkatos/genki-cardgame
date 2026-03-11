class_name GridTester
## A sample script demonstrating how to use the Grid zone to manage cards in a grid layout.
extends Grid

var _prefab: Node
var _next_slot_position: Callable = _next_slot_position_with_negatives


## Initializes the grid by assigning child cards to available slots.
func _ready () -> void:
	for card in get_children():
		var next = _next_slot()
		grid[next] = card
		# Connect click signal to handle removal
		card.on_clicked.connect(func(_pos): _handle_click(next.x, next.y))


## Handles shortcut keys for debugging grid operations.
func _input (event: InputEvent) -> void:
	if event is InputEventKey and not event.echo and event.pressed:
		# Add a new card on 'D' key
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
		# Re-organize on 'S' key
		elif event.keycode == KEY_S:
			_organize()


## Handles card click events by removing the clicked card from the grid.
func _handle_click (x, y):
	var pos = Vector2i(x, y)
	# Check if slot is occupied before removing
	if grid.has(pos):
		var card = grid[pos]
		remove_from_grid(pos)
		card.queue_free()


## Searches for the next available slot in the grid using a spiral-like search.
func _next_slot (x: int = 0, y: int = 0, depth: int = 0) -> Vector2i:
	var next = Vector2i(x, y)
	# Root level check
	if depth == 0:
		if !grid.has(next):
			return next
		depth = 1
		x = 1
		return _next_slot(1, 0, 1)
	# Iterative search through current depth
	while true:
		if not grid.has(next):
			return next
		next = _next_slot_position.call(next.x, next.y, depth)
		if abs(next.x) > depth or abs(next.y) > depth:
			break
	# Recurse to next depth if nothing found
	return _next_slot(next.x, next.y, depth + 1)


## Calculates the next spiral position without using negative coordinates.
func _next_slot_position_no_negatives (x: int, y: int, depth: int) -> Vector2i:
	if x == depth:
		if y == depth:
			return Vector2i(x - 1, y)
		return Vector2i(x, y + 1)
	if x == 0:
		return Vector2i(depth + 1, 0)
	return Vector2i(x - 1, y)


## Calculates the next spiral position including negative coordinates.
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
