extends Area2D

@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

var damage := {
	"front_attack1": 20,
	"front_attack2": 25,
	"front_attack3": 30,
	"left_attack1": 20,
	"left_attack2": 25,
	"left_attack3": 30,
	"right_attack1": 20,
	"right_attack2": 25,
	"right_attack3": 30,
	"back_attack1": 20,
	"back_attack2": 25,
	"back_attack3": 30
}
func get_current_damage() -> int:
	var anim_name = animation_player.current_animation
	if anim_name in damage:
		return damage[anim_name]
	return 0
