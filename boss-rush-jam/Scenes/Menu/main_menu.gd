extends Control

@onready var fade_rect: ColorRect = $FadeRect

func _ready() -> void:
	fade_rect.visible = false

func _on_play_button_pressed() -> void:
	fade_rect.visible = true
	# Create a Tween using Godot 4's create_tween()
	var tween = create_tween()
	# Tween the alpha component of fade_rect.modulate from 0 to 1 over 0.5 seconds.
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)
	# Wait for the tween to finish, then change scene.
	await tween.finished
	get_tree().change_scene_to_file("res://Scenes/World/tutorial.tscn")
