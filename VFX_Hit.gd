extends AnimatedSprite2D
@onready var sound = $Standart
@onready var fast = $Fast
@onready var heavy = $Heavy

# YENİ: Dışarıdan hangi sesin çalacağını belirleyeceğiz
var hit_type: String = "standard"  # Varsayılan

func _ready():
	# Hit tipine göre doğru sesi çal
	match hit_type:
		"fast":
			fast.play()
		"heavy":
			heavy.play()
		_:  # "standard" veya diğerleri
			sound.play()

func _on_animation_finished():
	queue_free()
