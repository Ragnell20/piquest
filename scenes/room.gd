extends Node2D

signal room_exited(direction)

@export var room_bounds: Rect2 = Rect2(-60, -41, 176, 224)
@export var chest_scene: PackedScene
@export var has_north: bool = false
@export var has_south: bool = false
@export var has_east: bool = false
@export var has_west: bool = false

@onready var enemies_node = $Enemies
@onready var spawn_point = $SpawnPoint

var enemies_cleared: bool = true

func _ready():
	print("Room _ready çalıştı!")
	setup_doors()
	await get_tree().process_frame


func setup_doors():
	for child in $Doors.get_children():  # Doors içindeki her child için yapılacak demek
		if child.has_signal("player_entered"):
			child.player_entered.connect(_on_door_entered)

func check_enemies():
	if enemies_node == null:
		print("enemies_node null!")
		enemies_cleared = true
		return
	var enemies = enemies_node.get_children()
	print("Düşman sayısı: ", enemies.size())
	if enemies.size() == 0:
		enemies_cleared = true
	else:
		enemies_cleared = false
		for enemy in enemies:
			print("Enemy: ", enemy.name, " died sinyali var mı: ", enemy.has_signal("died"))
			if enemy.has_signal("died"):
				enemy.died.connect(on_enemy_died)

func on_enemy_died():
	await get_tree().process_frame
	var alive = enemies_node.get_children().filter(func(e): return is_instance_valid(e))
	if alive.size() == 0:
		enemies_cleared = true
		print("cleared_rooms'a eklendi: ", GameManager.current_grid_pos)
		if not GameManager.cleared_rooms.has(GameManager.current_grid_pos):
			GameManager.cleared_rooms.append(GameManager.current_grid_pos)
		print("spawn_chest false ile çağrılıyor")  # oda dictionarysine kayıt
		spawn_chest(false)


func _on_door_entered(direction: String):
	if not enemies_cleared:
		return
	emit_signal("room_exited", direction)

func setup_player(player, came_from: String = ""):
	match came_from:
		"north": player.global_position = $Doors/Door3.global_position + Vector2(0, 20)
		"south": player.global_position = $Doors/Door.global_position + Vector2(0, -20)
		"east":  player.global_position = $Doors/Door2.global_position + Vector2(-20, 0)
		"west":  player.global_position = $Doors/Door4.global_position + Vector2(20, 0)
		_: player.global_position = $SpawnPoint.global_position

func spawn_chest(opened: bool = false):
	if chest_scene == null:
		return
	var chest = chest_scene.instantiate()
	chest.is_opened = opened
	chest.global_position = $SpawnPoint.global_position
	add_child(chest)
	if not GameManager.room_states.has(GameManager.current_grid_pos):
		GameManager.room_states[GameManager.current_grid_pos] = {"chest_opened": false}
