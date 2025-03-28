extends Node2D

@export var duration: float = 10.0  # Mark duration

func _ready():
	
	$AnimatedSprite2D.play("mark")  # Play the mark animation
	await get_tree().create_timer(duration).timeout
	queue_free()  # Remove mark after duration
