extends CharacterBody2D

enum State { IDLE, ATTACK, VULNERABLE, DEAD }

signal enemy_died
signal health_updated(new_health)

@export var maxHealth := 500
var health: int = maxHealth:
	set(value):
		health = clamp(value, 0, maxHealth)
		emit_signal("health_updated", health)

@export var move_speed := 150.0
@export var attack_cooldown := 3.0
@export var vulnerable_time := 2.0

var current_state: State = State.IDLE
@onready var player: Node2D = get_tree().get_first_node_in_group("Player")
var attack_timer: float = 0.0
var vulnerable_timer: float = 0.0

# Node references (adjust paths as needed)
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var hurtbox = $HurtBox
@onready var hitbox = $HitBox
@onready var sound_fx: Array = [ 
	$SoundFX/ChargeAttack, 
	$SoundFX/Screech,
	$SoundFX/WingFlaps
]

# Extra effect nodes for quality of life:
@onready var rage_particles: GPUParticles2D = $RageParticles
@onready var rage_roar: AudioStreamPlayer2D = $SoundFX/RageRoar

@onready var tounge_mid: Line2D = $ToungeAttack/ToungeMid
@onready var tounge_hitbox: Area2D = $ToungeAttack/ToungeMid/ToungeHitBox
@onready var tounge_collision: CollisionShape2D = $ToungeAttack/ToungeMid/ToungeHitBox/Tounge_Collision

var is_tounge_exteding := false
var tounge_target_pos := Vector2.ZERO

var is_charging := false
var charge_direction := Vector2.ZERO
var charge_target_pos := Vector2.ZERO

# Rage mode flag
var is_raging := false

@export var enemy_damage := 25
@export var tounge_damage := 30  # Separate damage for tongue attack
@export var charge_speed := 800
@export var charge_duration := 0.4  # Charge duration
@export var charge_windup_time := 0.5  # Windup before charging
@export var charge_cooldown := 1.5
@export var tongue_retract_delay := 0.5  # Delay before retracting the tongue
@export var tounge_charge_duration := 0.3
@export var tounge_windup_time := 0.5
@export var tounge_cooldown := 2

func _ready():
	change_state(State.IDLE)
	hitbox.monitorable = false
	tounge_mid.visible = false
	tounge_hitbox.monitoring = false
	tounge_collision.disabled = true  # Disable collision shape initially
	# Ensure extra effects are off initially:
	rage_particles.emitting = false

func _physics_process(delta):
	match current_state:
		State.IDLE:
			update_idle(delta)
		State.ATTACK:
			update_attack(delta)
		State.VULNERABLE:
			update_vulnerable(delta)
	
	if is_charging:
		handle_charge_movement(delta)
	
	move_and_slide()

func change_state(new_state: State):
	current_state = new_state
	match current_state:
		State.IDLE:
			enter_idle()
		State.ATTACK:
			enter_attack()
		State.VULNERABLE:
			enter_vulnerable()
		State.DEAD:
			enter_dead()

#region STATE FUNCTIONS
func enter_idle():
	animation_player.play("idle")
	sound_fx[2].play()
	hitbox.monitorable = true
	hitbox.monitoring = true
	attack_timer = attack_cooldown

func update_idle(delta):
	# Basic floating movement
	position.y += sin(Time.get_ticks_msec() * 0.01) * 0.5
	attack_timer -= delta
	if attack_timer <= 0:
		change_state(State.ATTACK)

func enter_attack():
	animation_player.play("charge_attack_state")
	hitbox.monitorable = true
	var attack_pattern = randi() % 2
	match attack_pattern:
		0:
			prepare_charge_attack()
		1:
			charge_tounge()

func update_attack(delta):
	# Add per-frame updates during attacks if needed
	pass

func enter_vulnerable():
	animation_player.play("vulnerable_state")
	vulnerable_timer = vulnerable_time
	hitbox.monitorable = false
	hitbox.monitoring = false

func update_vulnerable(delta):
	vulnerable_timer -= delta
	if vulnerable_timer <= 0:
		change_state(State.IDLE)

func enter_dead():
	emit_signal("enemy_died")
	animation_player.play("idle")
	hitbox.set_deferred("monitoring", false)
	queue_free()
#endregion

func _on_hurtbox_area_entered(area):
	if current_state != State.VULNERABLE:
		return
	if area.is_in_group("player_attacks"):
		print(area.get_current_damage())
		take_damage(area.get_current_damage())

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	shake_camera(0.5)
	sound_fx[1].play()
	if health <= 0:
		change_state(State.DEAD)
		return
	else:
		# Flash red briefly
		modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		# Only reset modulate if not in rage mode.
		if not is_raging:
			modulate = Color.WHITE
	# Check for rage mode activation if not already raging
	if not is_raging:
		proc_ragemode(health)

#region RAGE MODE FUNCTIONS
func proc_ragemode(current_health: int) -> void:
	# When health is 200 or less, trigger rage mode.
	if current_health <= 200:
		is_raging = true 
		enter_rage()

func enter_rage() -> void:
	# Update boss parameters for a more aggressive behavior.
	move_speed = 250
	attack_cooldown = 1.5
	vulnerable_time = 1.8
	enemy_damage = 40
	tounge_damage = 50
	charge_speed = 1000
	charge_cooldown = 1
	charge_duration = 0.3
	tongue_retract_delay = 0.3
	tounge_charge_duration = 0.2
	tounge_windup_time = 0.3
	tounge_cooldown = 1
	# Set the boss to be permanently red in rage mode.
	modulate = Color(1, 0, 0)
	# Play a dedicated rage roar sound effect.
	rage_roar.play()
	# Turn on the rage particles effect.
	rage_particles.emitting = true
	# (Optional) Trigger other visual effects here.
#endregion

#region ATTACK PATTERNS
func charge_tounge() -> void:
	if player == null:
		return
	animation_player.play("Tounge_Charge")
	sound_fx[0].play()
	tounge_target_pos = player.global_position
	show_tounge_warning()
	await get_tree().create_timer(tounge_windup_time).timeout
	extend_tounge_gradually()
	await get_tree().create_timer(tounge_charge_duration).timeout
	await get_tree().create_timer(tongue_retract_delay).timeout
	retract_tounge()
	change_state(State.VULNERABLE)

func show_tounge_warning() -> void:
	var warning_line = Line2D.new()
	warning_line.width = 10
	warning_line.default_color = Color(1, 0, 0, 0.5)
	var base_pos = tounge_mid.global_position
	var direction = (tounge_target_pos - base_pos).normalized()
	var distance = base_pos.distance_to(tounge_target_pos)
	warning_line.add_point(Vector2.ZERO)
	warning_line.add_point(direction * distance)
	add_child(warning_line)
	await get_tree().create_timer(tounge_windup_time).timeout
	warning_line.queue_free()

func extend_tounge_gradually() -> void:
	tounge_mid.visible = true
	tounge_collision.disabled = false
	var local_target_pos = tounge_mid.to_local(tounge_target_pos)
	var direction = (local_target_pos - Vector2.ZERO).normalized()
	var distance = local_target_pos.length()
	var elapsed_time = 0.0
	while elapsed_time < tounge_charge_duration:
		elapsed_time += get_process_delta_time()
		var progress = elapsed_time / tounge_charge_duration
		tounge_mid.clear_points()
		tounge_mid.add_point(Vector2.ZERO)
		tounge_mid.add_point(direction * distance * progress)
		update_collision_shape(direction * distance * progress)
		await get_tree().process_frame
	tounge_hitbox.monitoring = true

func update_collision_shape(end_point: Vector2) -> void:
	var shape = SegmentShape2D.new()
	shape.a = Vector2.ZERO
	shape.b = end_point
	tounge_collision.shape = shape
	print("Collision Shape: Start =", shape.a, ", End =", shape.b)

func retract_tounge() -> void:
	tounge_hitbox.monitoring = false
	tounge_collision.disabled = true
	tounge_mid.visible = false

func _on_tounge_tip_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Player"):
		print("tip touched")
		area.take_damage(tounge_damage)

func prepare_charge_attack() -> void:
	if player == null:
		return
	start_triple_charge()

func start_triple_charge() -> void:
	# Use 5 charges if in rage mode; otherwise use 3 charges.
	var num_charges = 5 if is_raging else 3
	for i in range(num_charges):
		await perform_single_charge()
		if i < num_charges - 1:
			await get_tree().create_timer(0.5).timeout
	change_state(State.VULNERABLE)

func perform_single_charge() -> void:
	if player == null:
		return
	# Start with the initial charge attack state.
	animation_player.play("charge_attack_state")
	sound_fx[0].play()
	hitbox.monitorable = true
	modulate = Color(2, 0.5, 0.5)
	await animation_player.animation_finished
	animation_player.play("charge_attack")
	# (Optional) Charge effect could be triggered here.
	var windup_tween = create_tween()
	windup_tween.tween_property(self, "scale", Vector2(1.2, 0.8), charge_windup_time / 2)
	windup_tween.tween_property(self, "scale", Vector2.ONE, charge_windup_time / 2)
	await animation_player.animation_finished
	await get_tree().create_timer(charge_windup_time).timeout
	# Update charge_target_pos to the latest player's position.
	charge_target_pos = player.global_position
	charge_direction = (charge_target_pos - global_position).normalized()
	is_charging = true
	# Only reset modulate if not in rage mode.
	if not is_raging:
		modulate = Color.WHITE
	var charge_timer = get_tree().create_timer(charge_duration)
	charge_timer.connect("timeout", Callable(self, "_on_charge_timeout"))
	await charge_timer.timeout
	# (Optional) Turn off any charge effect here.
	
func handle_charge_movement(delta: float) -> void:
	var collision = move_and_collide(charge_direction * charge_speed * delta)
	if collision:
		handle_charge_collision(collision)

func handle_charge_collision(collision: KinematicCollision2D) -> void:
	if collision.get_collider().is_in_group("Player"):
		var knockback_direction = (collision.get_collider().global_position - global_position).normalized()
		collision.get_collider().take_damage(enemy_damage, knockback_direction)
		# Spawn an impact effect at the collision point.
		spawn_impact_effect(collision.get_position())
	else:
		shake_camera(0.3)
	end_charge()

func end_charge() -> void:
	if not is_charging:
		return
	is_charging = false
	rotation = 0
	velocity = Vector2.ZERO
	# In rage mode, modulate remains red.
	if not is_raging:
		modulate = Color.WHITE
	hitbox.monitorable = false
	animation_player.play("idle")

func _on_charge_timeout() -> void:
	end_charge()

func shake_camera(intensity: float) -> void:
	if player != null and player.has_node("Camera2D"):
		player.get_node("Camera2D").add_trauma(intensity)

# A stub for spawning an impact effect at a given position.
func spawn_impact_effect(effect_pos: Vector2) -> void:
	# You can instance an impact particles scene here.
	print("Spawning impact effect at: ", effect_pos)
#endregion
