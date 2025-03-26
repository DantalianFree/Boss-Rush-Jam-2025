extends CharacterBody2D

signal died
signal health_updated(new_health)

var passive_skills: Array = []
var active_skills: Array = []
var current_passive_skills: Array = []

# Node references
@onready var camera = $Camera2D
@onready var shake_timer = $Camera2D/Timer
@onready var attack_animations = $Attacks/AnimationPlayer
@onready var attack_anim = $Attacks
@onready var fx: AudioStreamPlayer2D = $SoundFx/Attack
@onready var dash: AudioStreamPlayer2D = $SoundFx/Dash
@onready var grass_run: AudioStreamPlayer2D = $SoundFx/GrassRun
@onready var dash_particles: GPUParticles2D = $DashParticles
@onready var dash_trail: Line2D = $DashTrail
@onready var enemy: Node2D = get_tree().get_first_node_in_group("Enemy")
@onready var hurt_box: Area2D = $HurtBox
const PASSIVE_SKILL_LOADOUT = preload("res://rESOURCE/PASSIVE_SKILL.tres")

# Collision shapes for attacks
@onready var collision_front = $Attacks/Hitbox/FrontAttackCollision
@onready var collision_back = $Attacks/Hitbox/BackAttackCollision
@onready var collision_left = $Attacks/Hitbox/LeftAttackCollision
@onready var collision_right = $Attacks/Hitbox/RightAttackCollision

# Health properties
@export var max_health := 100
var health: int = max_health:
	set(value):
		health = clamp(value, 0, max_health)
		emit_signal("health_updated", health)

# Movement & Combat properties
@export var SPEED = 200
@export var damage = 200
@export var randomStrength: float = 30.0
@export var shakeFade: float = 5.0
@export var knockback_strength: float = 200.0
@export var knockback_duration := 0.2
var is_knockback := false
var knockback_timer := 0.0
var is_attacking = false

# Dash system properties
@export var dash_trail_length: int = 10
@export var dash_trail_color: Color = Color(0.5, 0.8, 1.0, 0.7)
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.8
@export var dash_invuln_time: float = 0.2
@export var max_consecutive_dashes: int = 2
var consecutive_dashes: int = 0
var can_dash: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

@export var base_zoom: Vector2 = Vector2(2.5, 2.5)

# ------------------------------
# COMBO SYSTEM VARIABLES
# ------------------------------
var combo_stage: int = 0         # 0 means no combo; valid stages: 1,2,3
var combo_timer: float = 0.0       # Timer to allow chaining the next attack
const COMBO_RESET_TIME: float = 1.0  # Time window (seconds) for combo input
# ------------------------------

# Slight attack movement impulse (lunge forward)
@export var attack_move_speed: float = 300.0

func _ready():
	set_skill_loadout(PASSIVE_SKILL_LOADOUT)
	disable_all_collision_shapes()
	dash_trail.default_color = dash_trail_color
	dash_trail.width = 8.0
	dash_trail.visible = false
	dash_particles.visible = false
	camera.zoom = base_zoom
	# Initialize combo state
	combo_stage = 0
	combo_timer = 0.0

func _process(delta):
	# Process combo timer if a combo is in progress and not currently attacking
	if combo_stage > 0 and not is_attacking:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()
	
	if is_knockback:
		handle_knockback(delta)
	else:
		handle_dash(delta)
		
		if is_dashing:
			move_and_slide()
			return
		
		# When not attacking, process movement and attack input
		if not is_attacking:
			handle_normal_movement(delta)
			handle_attack_input()

func set_skill_loadout(loadout):
	passive_skills = loadout.passive_skills.duplicate()
	active_skills = loadout.active_skills.duplicate()
	
	for skill in passive_skills:
		skill.update_description()
		if skill and skill.has_method("apply_effect"):
			skill.apply_effect(self)
			print("Setting passive skill:", skill.skill_name)
			print("Skill Description:", skill.skill_description)

func handle_knockback(delta):
	knockback_timer -= delta
	if knockback_timer > 0:
		move_and_slide()  # Continue knockback movement
	else:
		is_knockback = false
		velocity = Vector2.ZERO

func handle_dash(delta):
	# Dash input
	if Input.is_action_just_pressed("Dash") and can_dash and not is_attacking:
		start_dash()
		dash.play()
	
	if is_dashing:
		dash_particles.visible = true
		camera.add_trauma(0.1)
		dash_timer -= delta
		dash_trail.add_point(global_position)
		# Keep dash trail length consistent
		while dash_trail.get_point_count() > dash_trail_length:
			dash_trail.remove_point(0)
		if dash_timer <= 0:
			end_dash()
	
	# Dash cooldown logic
	if not can_dash:
		dash_cooldown -= delta
		if dash_cooldown <= 0:
			can_dash = true
			dash_cooldown = 0.8

func start_dash():
	var direction = Vector2.ZERO
	# Get movement input for dash
	if Input.is_action_pressed("Walk_Right"): direction.x += 1
	if Input.is_action_pressed("Walk_Left"): direction.x -= 1
	if Input.is_action_pressed("Walk_Down"): direction.y += 1
	if Input.is_action_pressed("Walk_Up"): direction.y -= 1
	
	if direction == Vector2.ZERO:
		# If no movement input, dash toward mouse position
		dash_direction = (get_global_mouse_position() - global_position).normalized()
	else:
		dash_direction = direction.normalized()
	
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	velocity = dash_direction * dash_speed
	
	dash_trail.clear_points()
	dash_trail.visible = true
	dash_particles.emitting = true
	attack_anim.modulate = Color(1, 1, 1, 0.7)
	
	update_animation_by_movement(dash_direction)
	attack_animations.speed_scale = 2.0
	
	hurt_box.monitoring = false
	consecutive_dashes += 1
	
	camera.add_trauma(0.15)
	var target_zoom = base_zoom * 0.9
	var tween = create_tween()
	tween.tween_property(camera, "zoom", target_zoom, 0.1)
	tween.tween_property(camera, "zoom", base_zoom, 0.2)
	dash_trail.modulate = dash_trail_color
	create_tween().tween_property(dash_trail, "modulate:a", 0.0, dash_duration)

func end_dash():
	dash_trail.visible = false
	dash_trail.clear_points()
	dash_particles.emitting = false
	attack_anim.modulate = Color.WHITE
	if attack_animations.current_animation.ends_with("_run"):
		attack_animations.speed_scale = 1.0
	is_dashing = false
	velocity = Vector2.ZERO
	update_animation_by_mouse()
	await get_tree().create_timer(dash_invuln_time).timeout
	hurt_box.monitoring = true
	
	dash_cooldown = 0.8 + (0.3 * consecutive_dashes)
	if consecutive_dashes >= max_consecutive_dashes:
		can_dash = false
		consecutive_dashes = 0

func handle_normal_movement(delta):
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
		update_animation_by_movement(direction)
	else:
		update_animation_by_mouse()
	
	move_and_slide()

# -----------------------------
# COMBO SYSTEM & ATTACK FUNCTIONS
# -----------------------------
func handle_attack_input():
	# When attack is pressed and not already attacking:
	if Input.is_action_just_pressed("attack") and not is_attacking:
		fx.play()
		is_attacking = true
		attack_anim.visible = true
		# Update combo stage: if no combo active, start at 1; otherwise increment (max 3)
		if combo_stage == 0:
			combo_stage = 1
		else:
			combo_stage = min(combo_stage + 1, 3)
		# Reset the combo timer for chaining
		combo_timer = COMBO_RESET_TIME
		attack()

func attack():
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()
	
	# Instead of completely halting, apply a slight attack impulse in the attack direction
	velocity = direction_to_mouse * attack_move_speed
	move_and_slide()  # Immediately apply the lunge
	
	# Determine directional attack animation name by appending combo stage number.
	var anim_name: String = ""
	if abs(direction_to_mouse.y) > abs(direction_to_mouse.x):
		if direction_to_mouse.y > 0:
			anim_name = "front_attack" + str(combo_stage)
			collision_front.disabled = false
		else:
			anim_name = "back_attack" + str(combo_stage)
			collision_back.disabled = false
	else:
		if direction_to_mouse.x > 0:
			anim_name = "right_attack" + str(combo_stage)
			collision_right.disabled = false
		else:
			anim_name = "left_attack" + str(combo_stage)
			collision_left.disabled = false
	
	# Play the chosen attack animation.
	attack_animations.play(anim_name)
	
	# Optionally, after a very short delay clear the attack impulse so the player stops lunging.
	await get_tree().create_timer(0.1).timeout
	velocity = Vector2.ZERO

func _on_attack_animation_finished(anim_name: StringName):
	# When the attack animation is finished, mark attack as complete.
	is_attacking = false
	disable_all_collision_shapes()
	update_animation_by_mouse()
	# If combo stage reached 3, reset the combo; otherwise allow chaining (until timer expires)
	if combo_stage >= 3:
		reset_combo()
	# (If the player inputs another attack before combo_timer runs out, combo_stage will update in handle_attack_input)

func reset_combo():
	combo_stage = 0
	combo_timer = 0.0
# -----------------------------

func update_animation_by_movement(direction: Vector2):
	if abs(direction.y) > abs(direction.x):
		if direction.y > 0:
			attack_animations.play("front_run")
		else:
			attack_animations.play("back_run")
	else:
		if direction.x > 0:
			attack_animations.play("right_run")
		else:
			attack_animations.play("left_run")

func update_animation_by_mouse():
	var mouse_position = get_global_mouse_position()
	var direction_to_mouse = (mouse_position - global_position).normalized()
	if abs(direction_to_mouse.y) > abs(direction_to_mouse.x):
		if direction_to_mouse.y > 0:
			attack_animations.play("idle_front")
		else:
			attack_animations.play("idle_back")
	else:
		if direction_to_mouse.x > 0:
			attack_animations.play("idle_right")
		else:
			attack_animations.play("idle_left")

func disable_all_collision_shapes():
	collision_front.disabled = true
	collision_back.disabled = true
	collision_left.disabled = true
	collision_right.disabled = true

func on_area_entered(area):
	if area.is_in_group("Enemy"):
		camera.add_trauma(0.5)

func take_damage(amount: int, knockback_direction: Vector2 = Vector2.ZERO): 
	health -= amount
	if health <= 0:
		emit_signal("died")
		queue_free()
	else: 
		if knockback_direction != Vector2.ZERO:
			is_knockback = true
			knockback_timer = knockback_duration
			velocity = knockback_direction.normalized() * knockback_strength
		camera.add_trauma(0.5)
		attack_anim.modulate = Color.RED
		await get_tree().create_timer(0.5).timeout
		attack_anim.modulate = Color.WHITE

func _on_hurt_box_area_entered(area):
	if area.is_in_group("enemy_attacks"):
		var knockback_direction = (global_position - area.global_position).normalized()
		take_damage(enemy.enemy_damage, knockback_direction)
