extends Node2D

@export var interactable_objects: Array[Node2D] = []
var currently_selected_object = Node2D

func _ready() -> void:
	currently_selected_object = interactable_objects[0]

func _process(delta) -> void:
	match _check_player_input():
		Vector2(-1.0, 0.0):
			print("left")
		Vector2(1.0, 0.0):
			print("right")
		Vector2(0.0, -1.0):
			print("up")
		Vector2(0.0, 1.0):
			print("down")
		_:
			pass
	for object in interactable_objects:
		if object == currently_selected_object:
			object.scale = Vector2(1.5, 1.5)
		else:
			object.scale = Vector2.ONE

func _check_player_input() -> Vector2:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	return direction

func _check_left_object() -> void:
	
	pass 

	
