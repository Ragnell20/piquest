extends CharacterBody2D

signal died
@onready var hurt_box: Area2D = $HurtBox
@export var hp: int = 200
@export var knockback_strength: float = 80.0
@export var movement_bounds: Rect2 = Rect2(-80, -60, 160, 120)  # merkeze göre

const VFX_HIT_SCENE = preload("res://scenes/vfx_hit.tscn")
const BULLET_STRAIGHT = preload("res://scenes/bullet_straight.tscn")
const BULLET_ARC = preload("res://scenes/bullet_arc.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player: CharacterBody2D = null
var is_invincible: bool = false
var is_dead: bool = false

# Pattern sırası: 0=mermi yağmuru, 1=hedefli burst, 2=alan saldırısı
var pattern_index: int = 0

func _ready():
	player = GameManager.player
	await get_tree().create_timer(1.0).timeout
	run_pattern()

func run_pattern():
	if is_dead:
		return
	match pattern_index:
		0: await mermi_yagmuru()
		1: await hedefli_burst()
		2: await alan_saldirisi()
	
	pattern_index = (pattern_index + 1) % 3
	await hareket_et()  # saldırılar arası hareket
	await get_tree().create_timer(1.0).timeout
	run_pattern()
	
	
	
func hareket_et():
	var hedef_offset = Vector2(randf_range(-50, 50), randf_range(-30, 30))
	var baslangic = global_position
	var hedef = baslangic + hedef_offset
	hedef.x = clamp(hedef.x, -90, 90)
	hedef.y = clamp(hedef.y, -65, 65)
	
	var sure = 0.6
	var gecen = 0.0
	
	while gecen < sure:
		if is_dead or not is_instance_valid(self):
			return
		var delta = get_process_delta_time()
		gecen += delta
		global_position = baslangic.lerp(hedef, gecen / sure)
		await get_tree().process_frame


# --- PATTERN 1: 360° mermi yağmuru ---
func mermi_yagmuru():
	var tur_sayisi = 16
	var mermi_sayisi = 14
	var angle = 0.0
	var direction_sign = 1
	var step = deg_to_rad(20)
	
	for t in range(tur_sayisi):
		for i in range(mermi_sayisi):
			var a = (2 * PI / mermi_sayisi) * i + angle
			var dir = Vector2(cos(a), sin(a))
			var b = BULLET_STRAIGHT.instantiate()
			b.direction = dir
			b.speed = 80.0
			get_tree().current_scene.add_child(b)
			b.global_position = global_position
		
		angle += step * direction_sign
		# Her 6 turda bir yön değiştir
		if t % 6 == 5:
			direction_sign *= -1
		
		await get_tree().create_timer(0.32).timeout

# --- PATTERN 2: Oyuncuya hedefli 3'lü burst ---
func hedefli_burst():
	if not is_instance_valid(player):
		return
	for i in range(8):
		if not is_instance_valid(player):
			break
		var dir = global_position.direction_to(player.global_position)
		var b = BULLET_ARC.instantiate()
		b.direction = dir
		b.speed = 110.0
		get_tree().current_scene.add_child(b)
		b.global_position = global_position
		await get_tree().create_timer(0.4).timeout

# --- PATTERN 3: Alan saldırısı ---
func alan_saldirisi():
	if not is_instance_valid(player):
		return
	
	var hedef_pos = player.global_position
	
	# Uyarı göster
	var warning = ColorRect.new()
	warning.size = Vector2(64, 64)
	warning.color = Color(1, 0, 0, 0.4)
	get_tree().current_scene.add_child(warning)
	warning.global_position = hedef_pos - Vector2(32, 32)
	
	await get_tree().create_timer(1.2).timeout
	warning.queue_free()
	
	# Animasyonunu oynat (varsa)
	# animation_player.play("explosion")
	# await animation_player.animation_finished
	
	# Hasar alanı
	var hit_area = Area2D.new()
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	hit_area.add_child(shape)
	get_tree().current_scene.add_child(hit_area)
	hit_area.global_position = hedef_pos
	
	await get_tree().process_frame
	
	for body in hit_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.take_damage(20, "enemy", hedef_pos)
	
	hit_area.queue_free()
	await get_tree().create_timer(0.1).timeout

# --- HASAR ALMA ---
func take_damage(amount: int, damage_type: String, damage_source_position: Vector2) -> void:
	if is_dead or is_invincible:
		return
	is_invincible = true
	hp -= amount
	
	var knockback_dir = damage_source_position.direction_to(global_position)
	velocity = knockback_dir * knockback_strength
	
	var vfx = VFX_HIT_SCENE.instantiate()
	vfx.hit_type = damage_type
	get_parent().add_child(vfx)
	vfx.global_position = global_position
	
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.15).timeout
	sprite.modulate = Color.WHITE
	
	if hp <= 0:
		die()
		return
	
	await get_tree().create_timer(0.3).timeout
	is_invincible = false

func die():
	is_dead = true
	if GameManager.music_player:
		GameManager.music_player.stop()
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)
	velocity = Vector2.ZERO
	animation_player.play("death")
	await animation_player.animation_finished
	emit_signal("died")
	queue_free()

func _physics_process(delta):
	velocity = velocity.move_toward(Vector2.ZERO, 150 * delta)
	move_and_slide()
	
	# Oyuncuya göre yönü ayarla
	if is_instance_valid(player) and not is_dead:
		if player.global_position.x < global_position.x:
			sprite.flip_h = true   # Sola bak
		else:
			sprite.flip_h = false  # Sağa bak
