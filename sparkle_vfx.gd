extends Node2D


@onready var sfx= $AnimationPlayer

# YENİ: Dışarıdan hangi sesin çalacağını belirleyeceğiz
var tier: String = "standard"  # Varsayılan

func _ready():
	sfx.play()

func _on_animation_finished():
	queue_free()
