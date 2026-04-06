extends CharacterBody2D

# --- Değişkenler ---
# (Sadece 'chase_speed'e ihtiyacımız var, 'lunge' veya 'cooldown' yok)
@export var chase_speed: float = 70.0

# --- Node Referansları ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $"Detection Area" # "Gözler"
@onready var sprite: Sprite2D = $Sprite2D
# (Hurtbox'ı tutuyoruz, ileride saldırı eklerken lazım olacak)
@onready var hurt_box: Area2D = $HurtBox 

# --- Yapay Zeka (AI) Durumları ---
# (Artık 'player_in_range', 'is_attacking', 'is_on_cooldown'
# gibi değişkenlere İHTİYACIMIZ YOK)

# --- Hazırlık ---
func _ready() -> void:
	animation_player.play("idle")
	# (Artık sinyal bağlantılarına veya 'await' koduna gerek yok)


# --- Fizik Motoru (Hareket ve AI) ---
func _physics_process(_delta: float) -> void:
	
	# --- BÖLÜM 1: KARAR VERME (GÜVENİLİR YÖNTEM) ---
	
	# "Gözlerimin (DetectionArea) içinde şu anda bir Player var mı?"
	var player_target = get_player_in_range()
	
	if player_target != null:
		# --- DURUM 1: Player menzilde ---
		# Ona doğru yürü (sürün)
		var direction = global_position.direction_to(player_target.global_position)
		velocity = direction * chase_speed
		animation_player.play("walk")
	else:
		# --- DURUM 2: Player menzilde değil ---
		# Dur
		velocity = Vector2.ZERO
		animation_player.play("idle")
			
	# --- BÖLÜM 2: HAREKETİ ve YÖNÜ UYGULAMA ---
	move_and_slide()
	update_sprite_direction()


# --- Özel Fonksiyonlar ---

# !! BU, SİSTEMİN KALBİDİR !!
# "Gözlerin (DetectionArea) içinde Player var mı?" diye soran fonksiyon
func get_player_in_range() -> CharacterBody2D:
	# "DetectionArea"nın şu anda içinde olan TÜM bedenlerin
	# (bodies) bir listesini al:
	var bodies_in_area = detection_area.get_overlapping_bodies()
	
	for body in bodies_in_area:
		# Eğer o bedenlerden BİRİ 'Player' (CharacterBody2D) ise...
		if body is CharacterBody2D:
			# ...Player'ı hedef olarak döndür.
			return body as CharacterBody2D
			
	# Eğer döngü (loop) biterse ve Player bulunamazsa,
	# "hiç kimse yok" (null) döndür.
	return null

# Yön (flip) güncellemesi (Bu aynı kaldı)
func update_sprite_direction() -> void:
	if velocity.x > 0:
		sprite.flip_h = true
	elif velocity.x < 0:
		sprite.flip_h = false

# (Hurtbox sinyalini bağlayabilirsiniz, ama saldırmadığımız için 'pass' yapacak)
func _on_hurt_box_body_entered(body: Node2D) -> void:
	# Şu anda saldırmadığımız için hiçbir şey yapma
	pass 

# (Artık 'attack' animasyonu olmadığı için bu fonksiyonlara gerek yok
# ama script'te kalmalarının bir zararı da yok)
func _on_animation_finished(anim_name: StringName) -> void:
	pass

func _on_attack_cooldown_timer_timeout() -> void:
	pass
