extends CharacterBody2D

@export var chase_speed: float = 70.0
@export var lunge_speed: float = 110.0
@export var detection_range: float = 10.0
@export var wander_speed: float = 30.0
@export var wander_wait_time: float = 2.0
@export var wander_move_time: float = 3.0
signal died
@export var hp: int = 30               # Düşman Canı
@export var knockback_strength: float = 150.0 # Geri sekme gücü

# Hasar efekti sahnesini yükle
const VFX_HIT_SCENE = preload("res://scenes/vfx_hit.tscn")

var is_hurt: bool = false # Hasar alma durumu

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $"Detection Area"
@onready var attack_range_area: Area2D = $AttackRangeArea
@onready var hurt_box: Area2D = $HurtBox
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var sprite: Sprite2D = $Sprite2D

enum State { IDLE, WANDER, CHASE, ATTACK, COOLDOWN, HURT }
var current_state: State = State.IDLE
var player_in_chase_range: bool = false
var player_in_attack_range: bool = false
var player_target: CharacterBody2D = null
var is_attacking: bool = false
var is_on_cooldown: bool = false
var is_invincible: bool = false
# Wander değişkenleri
var wander_timer: Timer

var wander_direction: Vector2 = Vector2.ZERO
var wander_state: String = "wait" # "wait" veya "move"

func _ready():
	
	is_attacking = false
	player_in_chase_range = false
	player_in_attack_range = false
	player_target = null
	player_in_chase_range = false
	var shape: CircleShape2D = detection_area.get_node("CollisionShape2D").shape
	shape.radius = detection_range
	
	animation_player.play("idle")
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# Wander timer'ı oluştur
	wander_timer = Timer.new()
	add_child(wander_timer)
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	wander_timer.one_shot = true
	
	await get_tree().physics_frame
	detection_area.monitoring = true
	attack_range_area.monitoring = true
	
	# İlk wander durumunu başlat  timer hazır olduktan sonra
	# çakışmama için giriş beklemesi
	await get_tree().create_timer(0.1).timeout
	
	start_wander_wait()

	
	
	

func _physics_process(_delta):
	if is_hurt:
		velocity = velocity.move_toward(Vector2.ZERO, 200 * _delta)
		move_and_slide()
		return
	
	if is_attacking:
		move_and_slide()  # pass yerine
		return
	
	if is_on_cooldown:
		velocity = velocity.move_toward(Vector2.ZERO, 100 * _delta)
	elif player_in_attack_range and player_target != null:
		if wander_timer.time_left > 0:
			wander_timer.stop()
		attack_lunge(player_target)
	elif player_in_chase_range and player_target != null:
		if wander_timer.time_left > 0:
			wander_timer.stop()
		chase_player(player_target)
	else:
		wander()
	
	move_and_slide()
	
	if not is_attacking and not is_hurt:
		if velocity.length() == 0:
			animation_player.play("idle")
		else:
			animation_player.play("walk")
	
	update_sprite_direction()

func wander():
	# Eğer timer çalışmıyorsa ve player yoksa, yeniden başlat
	if wander_timer.is_stopped() and not player_in_chase_range:
		start_wander_wait()
	
	if wander_state == "move":
		velocity = wander_direction * wander_speed
	else:
		velocity = Vector2.ZERO

func start_wander_wait():
	wander_state = "wait"
	wander_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	wander_timer.wait_time = wander_wait_time
	if wander_timer.is_inside_tree():
		wander_timer.start() 

func start_wander_move():
	wander_state = "move"
	# Rastgele bir yön seç (-1, 0, 1 için x ve y)
	var random_x = randf_range(-1.0, 1.0)
	var random_y = randf_range(-1.0, 1.0)
	wander_direction = Vector2(random_x, random_y).normalized()
	
	wander_timer.wait_time = wander_move_time
	wander_timer.start()

func _on_wander_timer_timeout():
	# Sadece player menzilde değilse wander devam 
	if not player_in_chase_range:
		if wander_state == "wait":
			start_wander_move()
		else:
			start_wander_wait()

func chase_player(target):
	var direction = global_position.direction_to(target.global_position)
	velocity = direction * chase_speed

func attack_lunge(target):
	if is_attacking:
		return
	
	is_attacking = true
	animation_player.play("attack")
	var dir = global_position.direction_to(target.global_position)
	velocity = dir * lunge_speed
	
	# Saldırı başladığında zaten HurtBox içinde olan hedeflere hasar ver
	check_hurt_box_overlaps()

func update_sprite_direction():
	if velocity.x > 0:
		sprite.flip_h = true
	elif velocity.x < 0:
		sprite.flip_h = false

func take_damage(amount: int, damage_type: String, damage_source_position: Vector2) -> void:
	if hp <= 0: return # Zaten ölü işlem yapılıyor
	if is_invincible: return 
	is_invincible = true
	hp -= amount
	print("Slime HP: ", hp)
	
	# 1. ÖNCE Geri Sekme (Knockback) Hızını Uygula (Ölecek olsa bile!)
	var knockback_dir = damage_source_position.direction_to(global_position)
	velocity = knockback_dir * knockback_strength
	
	# 2. Görsel Efekt (VFX)
	var vfx = VFX_HIT_SCENE.instantiate()
	vfx.hit_type = damage_type  # "fast", "heavy" veya "standard"
	get_parent().add_child(vfx)
	vfx.global_position = global_position
	
	# 3. Kırmızı Yanıp Sönme
	sprite.modulate = Color.RED
	
	# --- KRİTİK AYRIM BURADA ---
	await get_tree().create_timer(0.2).timeout
	if hp <= 0:
		# Eğer öldüyse, Ölüm Fonksiyonunu çağır (ama beklemeden)
		die()
		return
	else:
		# Eğer ölmediyse normal HURT (Sersemleme) durumuna geç
		is_hurt = true
		await get_tree().create_timer(0.4).timeout
		
		current_state = State.HURT
		# Rengi normale döndür
		await get_tree().create_timer(0.2).timeout
		sprite.modulate = Color.WHITE
		is_hurt = false
		is_invincible = false
func die() -> void:
	# 1. Hemen durdurma! Önce 'HURT' durumuna geç ki fizik motoru onu kaydırsın.
	current_state = State.HURT
	
	# 2. Çarpışmaları kapat (Geri uçarken oyuncuya takılmasın)
	$CollisionShape2D.set_deferred("disabled", true)
	hurt_box.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitorable", false)
	
	# 3. Geri sekme süresi kadar BEKLE (Slime geriye uçuyor...)
	await get_tree().create_timer(0.2).timeout
	
	# 4. Artık durabiliriz
	set_physics_process(false)
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE # Rengi düzelt (Kırmızı kalmasın)
	
	# 5. Ölüm animasyonunu oynat
	animation_player.play("death") # Animasyon adın "death" ise
	
	# 6. Animasyon bitene kadar bekle
	await animation_player.animation_finished
	
	# 7. Ve sil ve oda için sinyal ver
	emit_signal("died")
	queue_free()





func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_chase_range = true
		player_target = body
		# Player gelince wander'ı durdur
		if wander_timer and not wander_timer.is_stopped():
			wander_timer.stop()

func _on_detection_area_body_exited(body):
	if body == player_target:
		player_in_chase_range = false
		player_target = null
		player_in_attack_range = false
		# Player çıkınca tekrar wander'a başla
		start_wander_wait()

func _on_attack_range_area_body_entered(body):
	if body == player_target:
		player_in_attack_range = true

func _on_attack_range_area_body_exited(body):
	if body == player_target:
		player_in_attack_range = false

func _on_hurt_box_body_entered(body):
	if is_attacking and body.has_method("take_damage"):
		body.take_damage(10, "physical", global_position)

# Saldırı başladığında HurtBox'taki tüm varlıkları kontrol et
func check_hurt_box_overlaps():
	var overlapping_bodies = hurt_box.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.has_method("take_damage") and body != self:
			body.take_damage(10, "physical", global_position)

func _on_animation_finished(anim_name):
	if anim_name == "attack":
		is_attacking = false
		velocity = Vector2.ZERO
		is_on_cooldown = true
		if attack_cooldown_timer.is_stopped():
			attack_cooldown_timer.start()

func _on_attack_cooldown_timer_timeout():
	is_on_cooldown = false





func _on_startup_timer_timeout():
	pass
