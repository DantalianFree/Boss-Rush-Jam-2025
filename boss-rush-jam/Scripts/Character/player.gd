extends CharacterBody2D
@onready var animated_sprite = $Maharlikav1

const SPEED = 300

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
	
	if direction != Vector2.ZERO:
		animated_sprite.play()
		if direction.y > 0:
			animated_sprite.animation = "front_run"
		elif direction.y < 0:
			animated_sprite.animation = "back_run"
		elif direction.x > 0:
			animated_sprite.animation = "right_run"
		elif direction.x <0:
			animated_sprite.animation = "left_run"
	else:
		animated_sprite.animation = "Idle"
		
	move_and_slide()
