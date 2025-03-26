extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealhBarUI
@onready var boss_health_bar: TextureProgressBar = $BossHealthBarUI

func _ready():
	var boss = get_tree().get_first_node_in_group("Enemy")
	var player = get_tree().get_first_node_in_group("Player")
	boss.connect("health_updated", update_boss_health_bar)
	player.connect("health_updated", update_health_bar)
	
	# Initialize values
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	boss_health_bar.max_value = boss.maxHealth
	boss_health_bar.value = boss.health

func update_health_bar(value: int):
	health_bar.value = value
	# Add optional pulse animation when damaged
	if value < health_bar.value:
		create_tween().tween_property(health_bar, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.1).timeout
		create_tween().tween_property(health_bar, "scale", Vector2.ONE, 0.1)

func update_boss_health_bar(value: int):
	boss_health_bar.value = value

	if value < boss_health_bar.value:
		create_tween().tween_property(boss_health_bar, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.1).timeout
		create_tween().tween_property(boss_health_bar, "scale", Vector2.ONE, 0.1)
