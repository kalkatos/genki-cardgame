class_name HandTester
extends Hand

var prefab: Node


func _input (event: InputEvent) -> void:
	if event is InputEventKey and not event.echo and event.pressed:
		if event.keycode == KEY_SPACE:
			Debug.logm("Shuffling")
			shuffle()
			_organize()
		elif event.keycode == KEY_D:
			Debug.logm("Adding")
			if not prefab:
				prefab = get_last()
			var new_card = prefab.duplicate()
			add_item(new_card)
			_organize()
		elif event.keycode == KEY_S:
			_organize()
