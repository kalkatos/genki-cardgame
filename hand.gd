@tool
@icon("uid://6k7urmibyeb8")
class_name Hand
extends Zone

@export var bend: Curve
@export var bend_height: float = 1.0
@export var distance: float = 3.0
@export var max_angle: float = 15.0
@export var max_width: float = 15.0
@export var count_reference: int = 5
@export var allow_repositioning_on_drag: bool = true

var _input_monitor: Dictionary[Card, CardInputTracker] = {}


func _organize ():
	_organize_option(false)


func _organize_ignore (ignore_card: Card):
	_organize_option(false, 0, ignore_card)


func _organize_option (snap: bool, sorting_base: int = 0, ignore_card: Card = null) -> void:
	var count = get_child_count()
	if count == 0:
		return
	var used_distance = distance
	var used_height = lerp(0.0, bend_height, min(1.0, float(count - 1) / count_reference))
	var used_angle = lerp(0.0, max_angle, min(1.0, float(count - 1) / count_reference))
	var total_width = (count - 1) * distance
	if total_width > max_width:
		total_width = max_width
		used_distance = max_width / (count - 1)
	var start_x = -total_width / 2
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
		if snap or Engine.is_editor_hint():
			child.position = target_pos
			child.rotation_degrees = target_rot
		else:
			var tween = child.tween_to_local(target_pos, 0.2)
			tween.parallel().tween_property(child, "rotation_degrees", target_rot, 0.2)
			tween.parallel().tween_property(child, "scale", Vector3.ONE, 0.2)


func add_item_option (item: Node, notify: bool, organize: bool):
	super(item, notify, organize)
	_add_input_tracker(item as Card)


func remove_item_option (item: Node, notify: bool):
	super(item, notify)
	_dispose_input_tracker(item as Card)


func _dispose_input_tracker (card: Card) -> void:
	if _input_monitor.has(card):
		_input_monitor[card]._dispose()
		_input_monitor.erase(card)


func _add_input_tracker (card: Card) -> void:
	if Engine.is_editor_hint():
		return
	if not _input_monitor.has(card):
		_input_monitor[card] = CardInputTracker.new(card, self)


func _get_index_by_position (pos: Vector3) -> int:
	var count = get_child_count()
	if count <= 1:
		return 0
	var total_width = (count - 1) * distance
	var used_distance = distance
	if total_width > max_width:
		total_width = max_width
		used_distance = max_width / (count - 1)
	var start_x = -total_width / 2 - (used_distance / 2)
	if pos.x <= start_x:
		return 0
	if pos.x >= start_x + used_distance * (count - 1):
		return count
	var result = int((pos.x - start_x) / used_distance)
	return result


func _handle_card_hover_entered (card: Card) -> void:
	pass


func _handle_card_hover_exited (card: Card) -> void:
	pass


func _handle_card_drag_began (card: Card, mouse_pos: Vector2) -> void:
	pass


func _handle_card_dragged (card: Card, mouse_pos: Vector2) -> void:
	if not allow_repositioning_on_drag:
		return
	var current_index = card.get_index()
	var hand_index = min(_get_index_by_position(card.position), get_child_count() - 1)
	if hand_index == current_index:
		return
	move_child(card, hand_index)
	_organize_ignore(card)


func _handle_card_drag_ended (card: Card, mouse_pos: Vector2) -> void:
	pass


func _handle_card_clicked (_card: Card, mouse_pos: Vector2) -> void:
	pass


class CardInputTracker:
	var card: Card
	var hand: Hand

	func _init (card_: Card, hand_: Hand) -> void:
		card = card_
		hand = hand_
		card.on_hover_entered.connect(_hover_entered)
		card.on_hover_exited.connect(_hover_exited)
		card.on_drag_began.connect(_drag_began)
		card.on_dragged.connect(_dragged)
		card.on_drag_ended.connect(_drag_ended)
		card.on_clicked.connect(_clicked)

	func _dispose () -> void:
		card.on_hover_entered.disconnect(_hover_entered)
		card.on_hover_exited.disconnect(_hover_exited)
		card.on_drag_began.disconnect(_drag_began)
		card.on_dragged.disconnect(_dragged)
		card.on_drag_ended.disconnect(_drag_ended)
		card.on_clicked.disconnect(_clicked)
	
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
