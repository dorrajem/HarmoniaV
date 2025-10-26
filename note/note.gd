extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@export var color: Color = Color(1, 0.2, 0.2)
func _ready():
	sprite_2d.frame = randi_range(0, 4)
	if $ColorRect:
		$ColorRect.color = color
		sprite_2d.modulate = color
		#$ColorRect.rect_size = Vector2(64, 24)
		$ColorRect.position = Vector2(-32, -12) # center-ish
