extends Resource
class_name AnitoSkill

enum SkillType { ACTIVE, PASSIVE }

@export var skill_type : int = SkillType.PASSIVE
@export var skill_name : String = "Unnamed Anito"
@export var skill_description : String = ""

# Mark as virtual if meant to be overridden
func apply_effect(player):
	pass  # Derived classes should implement this

func activate_effect(player):
	pass
