extends Node2D

@onready var animation_tree: AnimationPlayer = $AnimationTree
@onready var tutorial_text: RichTextLabel = $TutorialText
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if animation_tree.animation_finished:
		if Input.is_action_just_pressed("Enter"):
			get_tree().change_scene_to_file("res://Scenes/World/world.tscn")
