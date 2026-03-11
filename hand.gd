@tool
@icon("uid://6k7urmibyeb8")
class_name Hand
## A zone type that organizes its children in a fan-like or hand-like layout. 
## Supports bending, angled cards, and repositioning during drag.
extends Zone

@export var bend: Curve
@export var bend_height: float = 1.0
@export var distance: float = 3.0
@export var max_angle: float = 15.0
@export var max_width: float = 15.0
@export var count_reference: int = 5
@export var allow_repositioning_on_drag: bool = true

# Tracks input for each card in the hand to handle hover and drag events
var _input_monitor: Dictionary[Card, CardInputTracker] = {}


## Internal implementation of organization logic for the hand.
func _organize ():
	_organize_option(false)


## Organizes the hand while ignoring a specific card (usually the one being dragged).
func _organize_ignore (ignore_card: Card):
	_organize_option(false, 0, ignore_card)


## Organizes the cards in the active area, calculating their target positions and tweening them.
## [param snap]: Whether to snap the cards instantly to their positions.
## [param sorting_base]: Base sorting index for the cards.
## [param ignore_card]: A card to ignore during organization (e.g., if it's currently being dragged).
func _organize_option (snap: bool, sorting_base: int = 0, ignore_card: Card = null) -> void:
	var count = get_child_count()
	if count == 0:
		return
	# Calculate layout parameters based on card count
	var used_distance = distance
	var used_height = lerp(0.0, bend_height, min(1.0, float(count - 1) / count_reference))
	var used_angle = lerp(0.0, max_angle, min(1.0, float(count - 1) / count_reference))
	var total_width = (count - 1) * distance
	# Clamp width to max_width
	if total_width > max_width:
		total_width = max_width
		used_distance = max_width / (count - 1)
	var start_x = -total_width / 2
	# Update each child's position and rotation
	for i in range(count):
		var child = get_child(i)
		if child is Card:
			if child == ignore_card:
				continue
			_add_input_tracker(child)
			child.set_sorting(sorting_base + i)
		var t = float(i) / max(1, count - 1)
		var pos_x = start_x + (i * used_distance)
		var pos_y = 0.0
		if bend:
			pos_y = bend.sample(t) * used_height
		var target_pos = Vector3(pos_x, pos_y, i * 0.01)
		var angle = lerp(used_angle, -used_angle, t)
		var target_rot = Vector3(0, 0, angle)
		# Apply transforms
		if snap or Engine.is_editor_hint():
			child.position = target_pos
			child.rotation_degrees = target_rot
		else:
			var tween = child.tween_to_local(target_pos, 0.2)
			tween.parallel().tween_property(child, "rotation_degrees", target_rot, 0.2)
			tween.parallel().tween_property(child, "scale", Vector3.ONE, 0.2)


## Adds an item to the hand and sets up its input tracker.
func add_item_option (item: Node, notify: bool, organize: bool):
	super(item, notify, organize)
	_add_input_tracker(item as Card)


## Removes an item from the hand and cleans up its input tracker.
func remove_item_option (item: Node, notify: bool):
	super(item, notify)
	_dispose_input_tracker(item as Card)


## Cleans up the input tracker for a given card.
func _dispose_input_tracker (card: Card) -> void:
	if _input_monitor.has(card):
		_input_monitor[card]._dispose()
		_input_monitor.erase(card)


## Adds an input tracker for a given card if it doesn't already have one.
func _add_input_tracker (card: Card) -> void:
	if Engine.is_editor_hint():
		return
	if not _input_monitor.has(card):
		_input_monitor[card] = CardInputTracker.new(card, self)


## Calculates the intended index for a card based on its local position.
## [param pos]: The local position to calculate the index for.
func _get_index_by_position (pos: Vector3) -> int:
	var count = get_child_count()
	if count <= 1:
		return 0
	# Layout parameters for index calculation
	var total_width = (count - 1) * distance
	var used_distance = distance
	if total_width > max_width:
		total_width = max_width
		used_distance = max_width / (count - 1)
	var start_x = -total_width / 2 - (used_distance / 2)
	# Determine index by X coordinate
	if pos.x <= start_x:
		return 0
	if pos.x >= start_x + used_distance * (count - 1):
		return count
	var result = int((pos.x - start_x) / used_distance)
	return result


## Virtual handler for card hover entry within the hand.
func _handle_card_hover_entered (card: Card) -> void:
	pass


## Virtual handler for card hover exit within the hand.
func _handle_card_hover_exited (card: Card) -> void:
	pass


## Virtual handler for when a card drag operation starts.
func _handle_card_drag_began (card: Card, mouse_pos: Vector2) -> void:
	pass


## Handles card movement while dragging to allow repositioning within the hand.
func _handle_card_dragged (card: Card, mouse_pos: Vector2) -> void:
	if not allow_repositioning_on_drag:
		return
	var current_index = card.get_index()
	var hand_index = min(_get_index_by_position(card.position), get_child_count() - 1)
	# Update index if position changed significantly
	if hand_index == current_index:
		return
	move_child(card, hand_index)
	_organize_ignore(card)


## Virtual handler for when a card drag operation ends.
func _handle_card_drag_ended (card: Card, mouse_pos: Vector2) -> void:
	pass


## Virtual handler for card click events within the hand.
func _handle_card_clicked (_card: Card, mouse_pos: Vector2) -> void:
	pass


## Internal helper class to track input events on cards and route them to Hand handlers.
class CardInputTracker:
	var card: Card
	var hand: Hand

	## Connects all relevant card signals to internal handlers.
	func _init (card_: Card, hand_: Hand) -> void:
		card = card_
		hand = hand_
		card.on_hover_entered.connect(_hover_entered)
		card.on_hover_exited.connect(_hover_exited)
		card.on_drag_began.connect(_drag_began)
		card.on_dragged.connect(_dragged)
		card.on_drag_ended.connect(_drag_ended)
		card.on_clicked.connect(_clicked)

	## Disconnects all card signals.
	func _dispose () -> void:
		card.on_hover_entered.disconnect(_hover_entered)
		card.on_hover_exited.disconnect(_hover_exited)
		card.on_drag_began.disconnect(_drag_began)
		card.on_dragged.disconnect(_dragged)
		card.on_drag_ended.disconnect(_drag_ended)
		card.on_clicked.disconnect(_clicked)
	
	## Handlers for routing signals back to the parent Hand instance.
	func _hover_entered () -> void:
		hand._handle_card_hover_entered(card)
	
	func _hover_exited () -> void:
		hand._handle_card_hover_exited(card)

	func _drag_began (mouse_pos: Vector2) -> void:
		hand._handle_card_drag_began(card, mouse_pos)

	func _dragged (mouse_pos: Vector2) -> void:
		hand._handle_card_dragged(card, mouse_pos)

	func _drag_ended (mouse_pos: Vector2) -> void:
		hand._handle_card_drag_ended(card, mouse_pos)
		hand._organize()

	func _clicked (mouse_pos: Vector2) -> void:
		hand._handle_card_clicked(card, mouse_pos)
