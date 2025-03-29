extends Area2D

@onready var sprite = $AnimatedSprite2D  
@export var explosion_damage: int = 24

func _ready():
	
	sprite.play("explode")
	connect("body_entered", _on_body_entered)
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(explosion_damage, Vector2.ZERO)
