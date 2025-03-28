extends Area2D  

@onready var sprite = $AnimatedSprite2D  

func _ready():
	sprite.play("explode")
	await get_tree().create_timer(1.0).timeout  # Force delete after 1 sec
	queue_free()
