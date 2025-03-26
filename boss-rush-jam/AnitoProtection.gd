extends AnitoSkill
class_name AnitoProtection

@export var defense_bonus: int = 10
@export var duration: float = 10.0

func _init():
	update_description()  # Ensure it updates on instance creation

func _get_property_list():
	update_description()  # Ensure it updates when viewed in the editor

func update_description():
	skill_name = "Anito of Protection"
	skill_description = "Boosts defense by " + str(defense_bonus) + " for " + str(duration) + " seconds."
