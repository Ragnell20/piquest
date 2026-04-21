extends Area2D

var speed: float = 100.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 10

func _ready():
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(4.0).timeout.connect(queue_free)

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage, "enemy", global_position)
		queue_free()
