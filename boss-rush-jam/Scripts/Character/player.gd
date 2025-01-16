extends CharacterBody2D

const SPEED = 250

func _process(delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("Walk_Right"):
		direction.x += 1
	if Input.is_action_pressed("Walk_Left"):
		direction.x -= 1
	if Input.is_action_pressed("Walk_Down"):
		direction.y += 1
	if Input.is_action_pressed("Walk_Up"):
		direction.y -= 1
	velocity = direction.normalized() * SPEED
	print(direction)
	move_and_slide()
