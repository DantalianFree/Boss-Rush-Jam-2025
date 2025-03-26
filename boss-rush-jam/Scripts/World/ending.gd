extends Node2D


@onready var anito: Sprite2D = $Anito
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if animation_player.animation_finished:
		get_tree().change_scene_to_file("res://Scenes/World/credits_control.tscn")
