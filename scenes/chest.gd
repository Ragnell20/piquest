extends Area2D

@onready var animation_player = $AnimationPlayer
var is_opened: bool=false


func _ready():
	animation_player.play("idle")


func interact()-> void:
	if is_opened==true:
		pass
	else:
		is_opened=true
		animation_player.play("open_chest")
