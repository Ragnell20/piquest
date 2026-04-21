extends CanvasLayer

@onready var hp_bar = $"VBoxContainer/HP Bar/ProgressBar"
@onready var weapon_label = $VBoxContainer/Weapon
@onready var hp_label = $"VBoxContainer/HP Bar/HP"



var player = null

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		hp_bar.max_value = player.max_hp
		hp_bar.value = player.hp

func _process(_delta):
	if player:
		hp_bar.max_value = player.max_hp  # max_hp değişince bar güncellenir
		hp_bar.value = player.hp
		hp_label.text = "%d / %d" % [player.hp, player.max_hp]
		if player.current_weapon:
			weapon_label.text = player.current_weapon.name
		else:
			weapon_label.text = "Silah yok"
