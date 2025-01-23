extends CharacterBody2D

@onready var animation_player = $Sprite2D/AnimationPlayer

const SPEED = 200

var is_attacking = false 

func _process(delta):
	var direction = Vector2.ZERO

	if !is_attacking:
		update_animation_by_mouse()
		
	# Handle movement input
	if Input.is_action_pressed("Walk_Right"):
		direction.x += 1
	if Input.is_action_pressed("Walk_Left"):
		direction.x -= 1
	if Input.is_action_pressed("Walk_Down"):
		direction.y += 1
	if Input.is_action_pressed("Walk_Up"):
		direction.y -= 1
	velocity = direction.normalized() * SPEED


	move_and_slide()

func update_animation_by_movement(direction: Vector2):
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0:
			pass
		else:
			pass
	else:
		if direction.x > 0:
			pass
		else:
			pass

func update_animation_by_mouse():
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()

	if abs(direction_to_mouse.y) > abs(direction_to_mouse.x):
		if direction_to_mouse.y > 0:
			animation_player.play("front_idle")
		else:
			animation_player.play("back_idle")
	else:
		if direction_to_mouse.x > 0:
			animation_player.play("right_idle")
		else:
			animation_player.play("left_idle")
