@tool
class_name Zone
## Abstract base class for all card zones. Provides core item management and organization hooks.
extends Node3D

signal on_item_added (item: Node)
signal on_item_removed (item: Node)
signal on_shuffled

@export var organize_after_add: bool = true
@export var organize_after_remove: bool = true
@export var organize_after_shuffle: bool = true

@export_tool_button("Organize")
var organize_button = organize_button_pressed
## Button handler for the editor-side "Organize" button.
func organize_button_pressed ():
	_organize()


## Adds an item to the zone and notifies listeners.
func add_item (item: Node):
	add_item_option(item, true, organize_after_add)


## Adds an item to the zone without triggering notification signals.
func add_item_no_notify (item: Node):
	add_item_option(item, false, organize_after_add)


## Base implementation for adding an item with various options.
func add_item_option (item: Node, notify: bool, organize: bool):
	var item_parent = item.get_parent()
	# Reparent item if necessary
	if not item_parent:
		add_child(item)
	elif item_parent != self:
		item.reparent(self)
	_item_added(item)
	# Emit signal and optionally re-organize
	if notify:
		on_item_added.emit(item)
	if organize:
		_organize()


## Inserts an item at a specific index and notifies listeners.
func insert_item (index: int, item: Node):
	insert_item_option(index, item, true)


## Inserts an item at a specific index without notification signals.
func insert_item_no_notify (index: int, item: Node):
	insert_item_option(index, item, false)


## Base implementation for inserting an item at an index.
func insert_item_option (index: int, item: Node, notify: bool):
	add_item_option(item, false, false)
	# Reposition child within the tree
	move_child(item, index)
	if notify:
		on_item_added.emit(item)
	if organize_after_add:
		_organize()


## Removes an item from the zone and notifies listeners.
func remove_item (item: Node):
	remove_item_option(item, true)


## Removes an item from the zone without notification.
func remove_item_no_nofity (item: Node):
	remove_item_option(item, false)


## Base implementation for removing an item. Reparents it to the scene tree root.
func remove_item_option (item: Node, notify: bool):
	if item.get_parent() == self:
		item.reparent(get_tree().root)
	_item_removed(item)
	if notify:
		on_item_removed.emit(item)
	if organize_after_remove:
		_organize()


## Shuffles the items within the zone.
func shuffle ():
	shuffle_option(true)


## Shuffles the items without notification.
func shuffle_no_notify ():
	shuffle_option(false)


## Base implementation for shuffling items within the zone.
func shuffle_option (notify: bool):
	var children = get_children()
	children.shuffle()
	# Apply randomized order back to the tree
	var i = 0
	for child in children:
		move_child(child, i)
		i += 1
	if notify:
		on_shuffled.emit()
	if organize_after_shuffle:
		_organize()


## Finds the index of a given item. Returns -1 if not found.
func find (item: Node) -> int:
	return get_children().find(item)


## Returns true if the zone contains the specified item.
func has (item: Node):
	get_children().has(item)


## Returns the first item in the zone.
func get_first () -> Node:
	if get_child_count() == 0:
		return null
	return get_child(0)


## Returns the last item in the zone.
func get_last () -> Node:
	if get_child_count() == 0:
		return null
	return get_child(-1)


## Virtual callback when an item is added to the zone.
func _item_added (_item: Node):
	pass


## Virtual callback when an item is removed from the zone.
func _item_removed (_item: Node):
	pass


## Virtual callback when the zone is shuffled.
func _shuffled () -> void:
	pass


## Abstract organization logic. Must be implemented by subclasses.
func _organize () -> void:
	pass
