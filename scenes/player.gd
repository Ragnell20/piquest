extends CharacterBody2D
@onready var inventory_ui = $InventoryUI
@onready var weapon_sprite = $WeaponPivot/SwordArea/WeaponSprite
@onready var attack_sound = $WeaponPivot/AttackSound

# --- Değişkenler ---
@export var speed: float = 100.0
@export var hp: int = 100 # Oyuncunun Canı
@export var iframe_duration: float = 0.3 

var iframe_timer: float = 0.0
var is_invincible: bool = false
# Geri Sekme (Hasar alınca) gücü
const KNOCKBACK_STRENGTH: float = 200.0

#silahlar
@export var inventory: Array[WeaponData] = [] # Silahları buraya sürükleyeceğiz
var current_weapon_index: int = 0
var current_weapon: WeaponData = null

var attack_cooldown_timer: float = 0.0

# Hasar efektini (VFX) önceden yükle
const VFX_HIT_SCENE = preload("res://scenes/VFX_Hit.tscn")

# --- Node Referansları ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

# YENİ: Kılıç Sistemi Referansları
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var sword_area: Area2D = $WeaponPivot/SwordArea

# --- Durumlar ---
var facing_direction: Vector2 = Vector2.DOWN # Başlangıçta aşağı bakıyor
var is_taking_damage: bool = false # Hasar alırken hareketi kilitler
var is_attacking: bool = false     # YENİ: Saldırı sırasında hareketi kilitler

# Menzildeki sandık/npc'yi tutan hafıza kutusu
var interactable_in_range: Area2D = null


func _ready() -> void:
	sprite.modulate = Color.WHITE # Hasar alma animasyonu için rengi sıfırla
	
	# YENİ: Oyun başlarken kılıç gizli ve zararsız olsun
	weapon_pivot.visible = false
	sword_area.monitoring = false
	inventory_ui.set_player_reference(self)
	if inventory.size() > 0:
		equip_weapon(0)


func _physics_process(delta: float) -> void:
	if iframe_timer > 0:
		iframe_timer -= delta
		# Yanıp sönme efekti (opsiyonel)
		sprite.modulate.a = 0.5 if int(iframe_timer * 10) % 2 == 0 else 1.0
	else:
		is_invincible = false
		sprite.modulate.a = 1.0  # Tam görünür
	# 1. COOLDOWN SAYACI
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	# 2. ÖNCELİKLİ DURUMLAR (Hasar alma veya Saldırma)
	# Eğer hasar alıyorsak, kontrol bizde değil
	if is_taking_damage:
		move_and_slide()
		return

	# YENİ: Eğer saldırıyorsak, normal yürümeyi iptal et
	# ama "Lunge" (ileri atılma) hızını uygula
	if is_attacking:
		move_and_slide()
		return

	# --- 3. GİRİŞLERİ (INPUT) KONTROL ET ---

	# YENİ: SALDIRI KONTROLÜ - COOLDOWN KONTROLÜ EKLE
	if Input.is_action_just_pressed("attack"):
		# Cooldown dolmadıysa saldırma
		if attack_cooldown_timer <= 0:
			attack()
		else:
			print("Cooldown: %.2f saniye kaldı" % attack_cooldown_timer)  # Debug
		return # Saldırı başladıysa aşağıya (yürümeye) geçme

	# ETKİLEŞİM KONTROLÜ (Sandık vb.)
	if Input.is_action_just_pressed("interact"):
		if interactable_in_range != null and interactable_in_range.has_method("interact"):
			interactable_in_range.interact()

	# --- 4. YÜRÜME MANTIĞI ---
	var input_direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	
	velocity = input_direction * speed
	move_and_slide()
	
	# --- 5. ANİMASYONLARI GÜNCELLE ---
	# Yönü güncelle (Sadece hareket ediyorsak)
	if input_direction != Vector2.ZERO:
		facing_direction = input_direction
	
	if velocity.length() > 0:
		if facing_direction.y < 0:
			animation_player.play("walk_up")
		elif facing_direction.y > 0:
			animation_player.play("walk_down")
		elif facing_direction.x < 0:
			animation_player.play("walk_left")
		elif facing_direction.x > 0:
			animation_player.play("walk_right")
	else:
		if facing_direction.y < 0:
			animation_player.play("idle_up")
		elif facing_direction.y > 0:
			animation_player.play("idle_down")
		elif facing_direction.x < 0:
			animation_player.play("idle_left")
		elif facing_direction.x > 0:
			animation_player.play("idle_right")


func equip_weapon(index: int):
	if index >= inventory.size():
		return
	
	current_weapon_index = index
	current_weapon = inventory[index]
	
	# Silahın görselini güncelle
	if weapon_sprite:
		weapon_sprite.texture = current_weapon.texture
	
	
	# Pivot'u scale ettiğimiz için hem resim hem de collision (Area2D) büyür/küçülür.
	# Eğer weapon_scale tanımlı değilse hata vermesin diye kontrol veya varsayılan değer:
	if "weapon_scale" in current_weapon:
		weapon_pivot.scale = current_weapon.weapon_scale
	else:
		weapon_pivot.scale = Vector2(1.0, 1.0) # Varsayılan
	
	print("Kuşanılan Silah: ", current_weapon.name)

#  SALDIRI FONKSİYONU 
func attack() -> void:
	if current_weapon == null: # Silah yoksa saldırma
		return
	
	# Zaten saldırıyorsa çık (ekstra güvenlik)
	if is_attacking:
		return
	
	is_attacking = true
	
	# COOLDOWN'U BAŞLAT
	attack_cooldown_timer = current_weapon.cooldown
	attack_sound.play()
	# 1. YÖN HESAPLAMA
	# Hangi yöne baktığımızı bulalım (up, down, left, right)
	var anim_direction = "down" # Varsayılan
	
	if facing_direction.y < 0: anim_direction = "up"
	elif facing_direction.y > 0: anim_direction = "down"
	elif facing_direction.x < 0: anim_direction = "left"
	elif facing_direction.x > 0: anim_direction = "right"
	
	
	# Kılıcı sallamadan önce, karakteri o yönün "yürüme" animasyonuna sokuyoruz.
	animation_player.play("walk_" + anim_direction)
	
	# Animasyonun 0.15. saniyesine (veya adımın tam atıldığı kareye) atla
	animation_player.seek(0.15, true)
	
	# Ve animasyonu orada DONDUR. 
	# Artık karakterimiz adım atmış şekilde dondu.
	animation_player.stop()
	
	# 3. KILIÇ AYARLARI
	weapon_pivot.rotation = facing_direction.angle()
	
	# Fiziksel Lunge (İleri itme)
	velocity = facing_direction * 75.0
	
	# 4. SALDIRIYI BAŞLAT
	# (Not: 'attack' animasyonunun içinde Sprite2D izi (track) OLMAMALI.
	# Eğer varsa, bizim az önce ayarladığımız donmuş pozu bozar.)
	animation_player.play("attack")
	
	await animation_player.animation_finished
	
	is_attacking = false
	velocity = Vector2.ZERO


func _on_sword_area_body_entered(body: CharacterBody2D) -> void:
	# Çarptığımız şeyin 'take_damage' fonksiyonu var mı? (Düşman mı?)
	if body.has_method("take_damage"):
		# YENİ: Silahın damage_type'ını gönder
		body.take_damage(
			current_weapon.damage, 
			current_weapon.damage_type,  # "fast", "heavy" veya "standard"
			global_position
		)
	

# --- DİĞER FONKSİYONLAR (Hasar alma, Etkileşim vb.) ---

func take_damage(amount: int, damage_type: String, damage_source_position: Vector2) -> void:
	# YENİ: İframe kontrolü - Hala invincible'sak hasar alma
	if is_invincible:
		return
	
	# Eğer zaten hasar alma sürecindeysek (invincible), çık.
	if is_taking_damage:
		return

	# !!! ÇÖZÜM BURASI: SALDIRI İPTALİ !!!
	if is_attacking:
		is_attacking = false
		weapon_pivot.visible = false
		sword_area.monitoring = false
		animation_player.stop()

	# --- Standart Hasar Alma Kodu ---
	is_taking_damage = true
	is_invincible = true  # YENİ: Invincibility başlat
	iframe_timer = iframe_duration  # YENİ: Timer'ı ayarla
	
	hp -= amount
	print("Player HP: ", hp)
	
	# Geri Sekme
	var knockback_direction = damage_source_position.direction_to(global_position)
	velocity = knockback_direction * KNOCKBACK_STRENGTH
	
	# Hasar Animasyonunu Oynat
	animation_player.play("damage_taken")
	
	# VFX
	var vfx_instance = VFX_HIT_SCENE.instantiate()
	
	# Damage_type'a göre ses belirle
	if damage_type == "heavy":
		vfx_instance.hit_type = "heavy"
	elif damage_type == "fast":
		vfx_instance.hit_type = "fast"
	elif damage_type == "enemy":
		vfx_instance.hit_type = "standard"  # Veya "enemy" ses ekleyebilirsiniz
	else:
		vfx_instance.hit_type = "standard"
	
	get_parent().add_child(vfx_instance)
	vfx_instance.global_position = global_position
	
	await animation_player.animation_finished
	is_taking_damage = false
	# NOT: is_invincible iframe_timer bitince otomatik kapanacak


func _on_interaction_area_area_entered(area: Area2D) -> void:
	interactable_in_range = area


func _on_interaction_area_area_exited(area: Area2D) -> void:
	if area == interactable_in_range:
		interactable_in_range = null
