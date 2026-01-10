@tool
class_name Zone
extends Node3D

signal on_item_added (item: Node)
signal on_item_removed (item: Node)
signal on_shuffled

@export var organize_after_add: bool = true
@export var organize_after_remove: bool = true
@export var organize_after_shuffle: bool = true

@export_tool_button("Organize")
var organize_button = organize_button_pressed
func organize_button_pressed ():
	_organize()


func add_item (item: Node):
	add_item_option(item, true, organize_after_add)


func add_item_no_notify (item: Node):
	add_item_option(item, false, organize_after_add)


func add_item_option (item: Node, notify: bool, organize: bool):
	var item_parent = item.get_parent()
	if not item_parent:
		add_child(item)
	elif item_parent != self:
		item.reparent(self)
	_item_added(item)
	if notify:
		on_item_added.emit(item)
	if organize:
		_organize()


func insert_item (index: int, item: Node):
	insert_item_option(index, item, true)


func insert_item_no_notify (index: int, item: Node):
	insert_item_option(index, item, false)


func insert_item_option (index: int, item: Node, notify: bool):
	add_item_option(item, false, false)
	move_child(item, index)
	if notify:
		on_item_added.emit(item)
	if organize_after_add:
		_organize()


func remove_item (item: Node):
	remove_item_option(item, true)


func remove_item_no_nofity (item: Node):
	remove_item_option(item, false)


func remove_item_option (item: Node, notify: bool):
	if item.get_parent() == self:
		item.reparent(get_tree().root)
	_item_removed(item)
	if notify:
		on_item_removed.emit(item)
	if organize_after_remove:
		_organize()


func shuffle ():
	shuffle_option(true)


func shuffle_no_notify ():
	shuffle_option(false)


func shuffle_option (notify: bool):
	var children = get_children()
	children.shuffle()
	var i = 0
	for child in children:
		move_child(child, i)
		i += 1
	if notify:
		on_shuffled.emit()
	if organize_after_shuffle:
		_organize()


func find (item: Node) -> int:
	return get_children().find(item)


func has (item: Node):
	get_children().has(item)


func get_first () -> Node:
	if get_child_count() == 0:
		return null
	return get_child(0)


func get_last () -> Node:
	if get_child_count() == 0:
		return null
	return get_child(-1)


func _item_added (_item: Node):
	pass


func _item_removed (_item: Node):
	pass


func _shuffled ():
	pass


func _organize ():
	pass
