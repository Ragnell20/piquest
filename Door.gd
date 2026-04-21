extends Node2D

signal player_entered(direction)

@export var direction: String = "north"

# Her yön için texture
@export var texture_north: Texture2D
@export var texture_south: Texture2D
@export var texture_east: Texture2D
@export var texture_west: Texture2D

func _ready():
	$Area2D.body_entered.connect(_on_body_entered)
	update_sprite()

func update_sprite():
	match direction:
		"north": $Sprite2D.texture = texture_north
		"south": $Sprite2D.texture = texture_south
		"east":  $Sprite2D.texture = texture_east
		"west":  $Sprite2D.texture = texture_west

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("player_entered", direction)
