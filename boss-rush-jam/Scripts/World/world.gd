extends Node2D

const YouDiedScene = preload("res://Scenes/Menu/you_died.tscn")
const Ending = preload("res://Scenes/World/ending.tscn")

func _ready():
	var player = $Player
	var manananggal = $Enemies/BoxEnemy

func _on_player_died():
	var you_died_instance = YouDiedScene.instantiate()
	get_tree().root.add_child(you_died_instance)

func _on_box_enemy_enemy_died():
	var enemy_died_instance = Ending.instantiate()
	get_tree().current_scene.add_child(enemy_died_instance)
