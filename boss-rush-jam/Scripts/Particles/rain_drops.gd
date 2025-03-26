extends GPUParticles2D

func _ready():
	emitting = true
	
	# Create and configure process material
	var material = ParticleProcessMaterial.new()
	
	# Gravity and movement
	material.gravity = Vector3(0, 980, 0)
	material.initial_velocity_min = 800
	material.initial_velocity_max = 1000
	material.direction = Vector3(0, 1, 0)
	material.spread = 45
	
	# Lifetime and appearance
	material.lifetime = 1.5
	material.lifetime_randomness = 0.2
	material.scale_amount_min = 2.0
	material.scale_amount_max = 4.0
	
	# Assign material
	process_material = material
	
	# Particle settings
	amount = 500
	preprocess = 1.0
	one_shot = false
	
	# Texture settings
	texture = preload("res://Assets/Effects/Rainparticle.png")
