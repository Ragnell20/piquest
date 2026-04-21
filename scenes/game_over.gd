extends CanvasLayer

func _ready():
	get_tree().paused = true




func _on_button_pressed():
	print("buton basıldı!")
	Engine.time_scale = 1.0
	get_tree().paused = false
	await get_tree().process_frame
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func reload():
	get_tree().reload_current_scene()
