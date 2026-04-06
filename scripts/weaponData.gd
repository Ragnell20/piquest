# WeaponData.gd
extends Resource
class_name WeaponData


enum ElementType { NONE, FIRE, ICE, LIGHTNING }

@export var name: String = "Silah"
@export var texture: Texture2D
@export var damage: int = 10
@export var cooldown: float = 0.5
@export var knockback_force: float = 200.0
@export var element: ElementType = ElementType.NONE 
@export var weapon_scale: Vector2 = Vector2(1.0, 1.0)
@export_enum("standard", "fast", "heavy") var damage_type: String = "standard"
