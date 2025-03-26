extends Camera2D

@export var decay_rate: float = 5.0
@export var max_offset: Vector2 = Vector2(30, 30)
@export var max_roll: float = 0.1

var trauma: float = 0.0
var trauma_power: int = 2

func _ready():
	randomize()

func _process(delta):
	if trauma > 0:
		trauma = max(trauma - decay_rate * delta, 0)
		apply_shake()

func apply_shake():
	var amount = pow(trauma, trauma_power)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)
