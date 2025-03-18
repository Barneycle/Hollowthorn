extends Sprite2D

@onready var anim_player = $AnimationPlayer

func _on_Area2D_body_entered(body):
	if body.is_in_group("player"):
		anim_player.play("chest_opening")

func _on_Area2D_body_exited(body):
	if body.is_in_group("player"):
		anim_player.play("chest_closing")
