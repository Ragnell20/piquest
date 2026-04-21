extends Node2D

func _ready():
	GameManager.register_player(get_tree().get_first_node_in_group("player"))
	GameManager.generate_level(2)
