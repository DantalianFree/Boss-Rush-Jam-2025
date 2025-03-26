extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect

func _ready() -> void:
	fade_rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(
		fade_rect,
		"modulate:a",
		1.0,
		1.0
	).set_trans(tween.TRANS_LINEAR).set_ease(tween.EASE_IN_OUT)

func _on_button_pressed() -> void:
	print("Restart button pressed!")  # Debugging
	# Unpause the game (if paused)
	get_tree().paused = false
	queue_free()
	get_tree().reload_current_scene()
