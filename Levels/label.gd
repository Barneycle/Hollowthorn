extends Label

@export var float_up_speed: float = 30
@export var fade_out_speed: float = 1.5

func _ready():
	
	modulate.a = 1.0

func _process(delta):
	
	position.y -= float_up_speed * delta
	modulate.a -= fade_out_speed * delta
	
	if modulate.a <= 0:
		
		queue_free()
