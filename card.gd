@icon("uid://cahitwf3e4b12")
@tool
class_name Card
extends Draggable

@export var data: CardData:
	set(new_data):
		data = new_data
		_setup(new_data)
@export var field_views: Dictionary[String, Variant]

@export_group("References")
@export var front: Node3D
@export var back: Node3D
@export var glow_obj: Node3D
@export var visuals: Array[VisualInstance3D]

var is_highlighted: bool = false
var highlight_frozen_state: bool = false
var card_name: String = "Card"

var is_face_up: bool:
	get: return global_basis.z.dot(Vector3.UP) >= 0
var is_glowing: bool:
	get: return glow_obj.visible

var _values: Dictionary[String, Variant]
var _camera: Camera3D
var _drag_quat: Quaternion
var _main_tween: Tween
var _front_highlight_tween: Tween
var _back_highlight_tween: Tween
var _default_highlight_settings: HighlightSettings
var _saved_sorting_order: int
var _last_sorting_order: int

const FACE_UP = Quaternion(-0.7071, 0, 0, 0.7071)
const FACE_DOWN = Quaternion(0.0, 0.7071, -0.7071, 0.0)
const HIGHLIGHT_HEIGHT: float = 0.5


func _ready () -> void:
	super()
	_values = {}
	_camera = get_viewport().get_camera_3d()
	if not _camera and not Engine.is_editor_hint():
		Debug.log_error("No camera 3D found in the current viewport.")
	_default_highlight_settings = HighlightSettings.new(
			Vector3(0, 0, HIGHLIGHT_HEIGHT),
			Vector3(0, 0, -HIGHLIGHT_HEIGHT),
			Vector3(1.1, 1.1, 1.1),
			false,
			0.2,
			Tween.TRANS_BOUNCE,
			Tween.EASE_OUT)


func set_data (data_: CardData) -> void:
	data = data_
	_setup(data)


func set_field_value (key: String, value: Variant):
	_values[key] = value
	if field_views.has(key):
		var field = field_views[key]
		if field is NodePath:
			_update_view(key, value, get_node(field))
		elif field is Array:
			for nodepath in field:
				_update_view(key, value, get_node(nodepath))
		else:
			Debug.log_error("Field view for key %s is neither a NodePath nor an Array of NodePaths." % key)


func set_highlight (on: bool, force: bool = false) -> void:
	if highlight_frozen_state:
		return
	if on == is_highlighted and not force:
		return
	_apply_highlight(on, _default_highlight_settings)
	is_highlighted = on
	if on:
		set_sorting(Global.highlighted_card_sorting, false)
	else:
		set_sorting(_saved_sorting_order)


func set_highlight_and_freeze (on: bool, freeze: bool) -> void:
	if not freeze:
		highlight_frozen_state = false
	set_highlight(on, true)
	if freeze:
		highlight_frozen_state = true


func set_face (up: bool) -> void:
	if up:
		quaternion = FACE_UP
	else:
		quaternion = FACE_DOWN


func flip () -> void:
	var up = not is_face_up
	var target_quaternion = (FACE_UP if up else FACE_DOWN) * get_parent().quaternion.inverse()
	var start_position = global_position
	var subtween = create_tween()
	subtween.tween_property(self, "global_position", start_position + Vector3(0, 1.5, 0), 0.1)
	subtween.tween_property(self, "global_position", start_position, 0.1)
	_kill_main_tween()
	_main_tween = create_tween()
	_main_tween.tween_subtween(subtween)
	_main_tween.parallel().tween_property(self, "quaternion", target_quaternion, 0.2)
	_main_tween.finished.connect(_handle_flip_finished)


func set_glow (on: bool) -> void:
	glow_obj.visible = on


func tween_to (position: Vector3, time: float) -> Tween:
	_kill_main_tween()
	_main_tween = create_tween()
	_main_tween.tween_property(self, "global_position", position, time)
	return _main_tween


func tween_to_local (position: Vector3, time: float) -> Tween:
	_kill_main_tween()
	_main_tween = create_tween()
	_main_tween.tween_property(self, "position", position, time)
	return _main_tween


func get_sorting() -> int:
	if visuals.size() > 0:
		return visuals[0].sorting_offset
	return 0


func set_sorting (order: int, save: bool = true) -> void:
	if save:
		_last_sorting_order = _saved_sorting_order
		_saved_sorting_order = order
	if is_highlighted:
		order = Global.highlighted_card_sorting
	for visual in visuals:
		visual.sorting_offset = order


func _setup (_data: CardData):
	if not _data:
		return
	var name = _data.get_name()
	if name:
		card_name = name
	else:
		card_name = "Card"
	for key in _data.fields:
		set_field_value(key, _data.fields[key])


func _apply_highlight(on: bool, settings: HighlightSettings) -> void:
	if on:
		if _front_highlight_tween:
			_front_highlight_tween.kill()
		_front_highlight_tween = create_tween()
		_front_highlight_tween.set_trans(settings.trans)
		_front_highlight_tween.set_ease(settings.ease)
		_front_highlight_tween.tween_property(front, "position", settings.front_offset, settings.time)
		_front_highlight_tween.parallel().tween_property(front, "scale", settings.scale, settings.time)
		if settings.face_camera:
			var target_quat = _face_camera_quat() * quaternion.inverse()
			_front_highlight_tween.parallel().tween_property(front, "quaternion", target_quat, settings.time)
		if _back_highlight_tween:
			_back_highlight_tween.kill()
		_back_highlight_tween = create_tween()
		_back_highlight_tween.set_trans(settings.trans)
		_back_highlight_tween.set_ease(settings.ease)
		_back_highlight_tween.tween_property(back, "position", settings.back_offset, settings.time)
		_back_highlight_tween.parallel().tween_property(back, "scale", settings.scale, settings.time)
	else:
		if _front_highlight_tween:
			_front_highlight_tween.kill()
		_front_highlight_tween = create_tween()
		_front_highlight_tween.set_trans(settings.trans)
		_front_highlight_tween.set_ease(settings.ease)
		_front_highlight_tween.tween_property(front, "position", Vector3(0, 0, 0), 0.2)
		_front_highlight_tween.parallel().tween_property(front, "scale", Vector3(1, 1, 1), 0.2)
		if front.quaternion != Quaternion.IDENTITY:
			_front_highlight_tween.parallel().tween_property(front, "quaternion", Quaternion.IDENTITY, 0.2)
		if _back_highlight_tween:
			_back_highlight_tween.kill()
		_back_highlight_tween = create_tween()
		_back_highlight_tween.set_trans(settings.trans)
		_back_highlight_tween.set_ease(settings.ease)
		_back_highlight_tween.tween_property(back, "position", Vector3(0, 0, 0), 0.2)
		_back_highlight_tween.parallel().tween_property(back, "scale", Vector3(1, 1, 1), 0.2)


func _update_view (key: String, value: Variant, node: Node):
	if value is bool:
		node.visible = value
		return
	var node_class = node.get_class()
	match node_class:
		"Label", "Label3D", "RichTextLabel":
			node.text = str(value)
		"Sprite2D", "Sprite3D", "TextureRect", "NinePatchRect":
			node.texture = value
		_:
			Debug.log_error("Treatment for field view with key %s and class %s is not implemented." % [key, node_class])


func _kill_main_tween () -> void:
	if _main_tween:
		_main_tween.kill()
		_handle_main_tween_killed()


func _hover_entered ():
	set_highlight(true)


func _hover_exited ():
	set_highlight(false)


func _begin_drag (_mouse_position: Vector2):
	set_highlight(false)
	var camera = get_viewport().get_camera_3d()
	_drag_quat = _face_camera_quat()
	set_sorting(Global.drag_card_sorting, false)


func _drag (_mouse_position: Vector2):
	quaternion = quaternion.slerp(_drag_quat, _begin_drag_lerp)


func _end_drag (_mouse_position: Vector2):
	pass


func _click (_mouse_position: Vector2):
	pass


func _handle_flip_finished () -> void:
	pass


func _handle_main_tween_killed () -> void:
	pass


func _face_camera_quat () -> Quaternion:
	if is_face_up:
		return _camera.quaternion * get_parent().quaternion.inverse()
		# return Quaternion(get_parent().global_basis.z, _drag_rotation_vector)
	return Quaternion(Basis(-_camera.basis.x, _camera.basis.y, -_camera.basis.z)) * get_parent().quaternion.inverse()


class HighlightSettings:
	var front_offset: Vector3
	var back_offset: Vector3
	var scale: Vector3
	var face_camera: bool
	var time: float
	var trans: int
	var ease: int

	func _init (front_offset: Vector3, back_offset: Vector3, scale: Vector3, face_camera: bool, time: float, trans: int, ease: int):
		self.front_offset = front_offset
		self.back_offset = back_offset
		self.scale = scale
		self.face_camera = face_camera
		self.time = time
		self.trans = trans
		self.ease = ease
