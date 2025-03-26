extends Control

func _input(event: InputEvent):
	if Input.is_action_just_pressed("Enter"):
		get_tree().change_scene_to_file("res://Scenes/Menu/MainMenu.tscn")
