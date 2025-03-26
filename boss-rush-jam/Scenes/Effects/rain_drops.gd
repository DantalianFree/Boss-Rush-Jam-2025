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
	
	# Assign material
	process_material = material
	
	# Particle settings (set lifetime here, not in the material)
	amount = 500
	lifetime = 1.0  # Set lifetime directly on the GPUParticles2D node
	preprocess = 1.0
	one_shot = false
	
	# Texture settings
	texture = preload("res://Assets/Effects/Rainparticle.png")
