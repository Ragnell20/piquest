extends Node

var player = null
var current_room = null

var music_player: AudioStreamPlayer
var normal_music = preload("res://music/3. Twilight March.ogg")
var boss_music = preload("res://music/boss_music.ogg")  

var cleared_rooms: Array = []
var room_states: Dictionary = {}  # {Vector2i: {cleared, chest_opened}}
# Oda sahneleri
var room_scenes = [
	preload("res://scenes/rooms/room1.tscn"),
	preload("res://scenes/rooms/room2.tscn"),
	preload("res://scenes/rooms/room3.tscn"),
	preload("res://scenes/rooms/room4.tscn"),
]
var boss_room = preload("res://scenes/rooms/roomboss.tscn")

# Grid ve oda verileri
var grid = {}  # {Vector2i: room_scene_index}
var room_connections = {}  # {Vector2i: {direction: Vector2i}}
var current_grid_pos = Vector2i(0, 0)

# Yön vektörleri
var directions = {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0)
}
var opposite = {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east"
}
func play_music(stream: AudioStream):
	if music_player.stream == stream:
		return  # zaten çalıyorsa tekrar başlatma
	music_player.stream = stream
	music_player.play()
func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.volume_db = +5
	play_music(normal_music)

func register_player(p):
	player = p

func generate_level(room_count: int = 8):
	grid.clear()
	room_connections.clear()
	
	var pos = Vector2i(0, 0)
	var available_dirs = ["north", "south", "east", "west"]
	
	# Başlangıç odasını koy
	grid[pos] = randi() % room_scenes.size()
	room_connections[pos] = {}
	
	for i in range(room_count - 1):
		# Rastgele yön seç
		available_dirs.shuffle()
		var moved = false
		
		for dir in available_dirs:
			var next_pos = pos + directions[dir]
			if not grid.has(next_pos):
				# Bağlantı kur
				room_connections[pos][dir] = next_pos
				room_connections[next_pos] = {}
				room_connections[next_pos][opposite[dir]] = pos
				
				# Normal oda mı boss odası mı
				if i == room_count - 2:
					grid[next_pos] = -1  # -1 = boss
				else:
					grid[next_pos] = randi() % room_scenes.size()
				
				pos = next_pos
				moved = true
				break
		
		if not moved:
			break
	
	# Başlangıç odasını yükle
	current_grid_pos = Vector2i(0, 0)
	load_room(current_grid_pos, "")

func load_room(grid_pos: Vector2i, came_from: String):
	if current_room:
		current_room.queue_free()
	
	var scene
	if grid[grid_pos] == -1:
		scene = boss_room
	else:
		scene = room_scenes[grid[grid_pos]]
	
	current_room = scene.instantiate()
	if grid[grid_pos] == -1:
		play_music(boss_music)
	else:
		play_music(normal_music)
	get_tree().current_scene.add_child(current_room)
	
	var connections = room_connections[grid_pos]
	for door in current_room.get_node("Doors").get_children():
		if connections.has(door.direction):
			door.visible = true
			door.get_node("Area2D").set_deferred("monitoring", true)
		else:
			door.visible = false
			door.get_node("Area2D").set_deferred("monitoring", false)
	
	current_room.room_exited.connect(_on_room_exited)
	
	if player:
		current_room.setup_player(player, came_from)
	
	await get_tree().process_frame
	
	if cleared_rooms.has(grid_pos):
		for enemy in current_room.enemies_node.get_children():
			enemy.queue_free()
		current_room.enemies_cleared = true
		if room_states.has(grid_pos):
			current_room.spawn_chest(room_states[grid_pos].chest_opened)
	else:
		current_room.check_enemies()
	
	var camera = player.get_node("Camera2D")
	var room_pos = current_room.global_position
	camera.limit_left = int(room_pos.x + 100)
	camera.limit_top = int(room_pos.y - 88)
	camera.limit_right = int(room_pos.x + 112)
	camera.limit_bottom = int(room_pos.y + 88)

func _on_room_exited(direction: String):
	var next_pos = room_connections[current_grid_pos][direction]
	current_grid_pos = next_pos
	call_deferred("load_room", current_grid_pos, opposite[direction])

func reset():
	grid.clear()
	room_connections.clear()
	cleared_rooms.clear()
	room_states.clear()
	current_grid_pos = Vector2i(0, 0)
	current_room = null
	if music_player:
		music_player.play()
	
	# Player'a dokunmadan önce geçerli mi kontrol et
	if is_instance_valid(player):
		player.max_hp = 100
		player.hp = player.max_hp
		player.bonus_damage = 0
	
	player = null  # En sona taşı
