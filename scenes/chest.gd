extends Area2D

@export var weapon_to_give: WeaponData
@export var hp_icon: Texture2D
@export var damage_icon: Texture2D

var is_opened: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const LOOT_VFX = preload("res://scenes/sparkle_vfx.tscn")
const WEAPONS = [
	preload("res:///weapons/sword.tres"),
	preload("res:///weapons/axe.tres"),
]

func _ready():
	weapon_to_give = WEAPONS[randi() % WEAPONS.size()]
	print("_ready is_opened: ", is_opened)
	if is_opened:
		animation_player.play("opened")
	else:
		animation_player.play("idle")

func interact():
	if is_opened:
		print("Bu sandık zaten açıldı!")
		return
	open_chest()

func open_chest():
	is_opened = true
	if GameManager.room_states.has(GameManager.current_grid_pos):
		GameManager.room_states[GameManager.current_grid_pos].chest_opened = true
	if animation_player and animation_player.has_animation("open_chest"):
		animation_player.play("open_chest")
	elif sprite:
		sprite.frame = 1
	give_loot()
	spawn_loot_effect()

enum LootType { WEAPON, MAX_HP, BONUS_DAMAGE }

func give_loot():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var loot_type = randi() % 3
	match loot_type:
		LootType.WEAPON:
			if weapon_to_give:
				player.add_weapon_to_inventory(weapon_to_give)
				show_loot_notification(weapon_to_give.name)
		LootType.MAX_HP:
			player.max_hp += 20
			player.hp += 20
			show_loot_notification("+HP")
		LootType.BONUS_DAMAGE:
			player.bonus_damage += 5
			show_loot_notification("+Hasar")

func show_loot_notification(text: String):
	var icon = Sprite2D.new()
	icon.z_index = 100
	icon.scale = Vector2(1, 1)
	icon.modulate.a = 0.0
	icon.position = global_position + Vector2(0, -20)
	
	if text.contains("HP"):
		icon.texture = hp_icon
	elif text.contains("Hasar"):
		icon.texture = damage_icon
	elif weapon_to_give != null and weapon_to_give.texture:
		icon.texture = weapon_to_give.texture
	else:
		return
	
	get_tree().current_scene.add_child(icon)
	
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(icon):
		return
	
	icon.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(icon, "position:y", icon.position.y - 30, 4.2)
	tween.parallel().tween_property(icon, "modulate:a", 0.0, 0.6)
	await tween.finished
	if is_instance_valid(icon):
		icon.queue_free()

func spawn_loot_effect():
	if LOOT_VFX:
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(self):
			var vfx = LOOT_VFX.instantiate()
			get_parent().add_child(vfx)
			vfx.global_position = global_position
