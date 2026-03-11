class_name HandTester
## A sample script demonstrating how to use the Hand zone to manage cards in a hand layout.
extends Hand

var prefab: Node


## Handles shortcut keys for testing hand interactions.
func _input (event: InputEvent) -> void:
	if event is InputEventKey and not event.echo and event.pressed:
		# Shuffle cards on Space key
		if event.keycode == KEY_SPACE:
			print("Shuffling")
			shuffle()
			_organize()
		# Add a new redundant card on 'D' key
		elif event.keycode == KEY_D:
			print("Adding")
			if not prefab:
				prefab = get_last()
			var new_card = prefab.duplicate()
			add_item(new_card)
			_organize()
		# Re-organize on 'S' key
		elif event.keycode == KEY_S:
			_organize()
