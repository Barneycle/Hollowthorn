extends Area2D

@export var speed: float = 200
@export var max_speed: float = 300
@export var damage: int = 10
@export var stun_duration: float = 0.5
@export var is_dragonus: bool = false
@export var bounce_count: int = 1  # Number of times it can split

var direction: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	sprite.play("stun")
	connect("body_entered", _on_body_entered)

	if is_dragonus:
		spawn_extra_projectile()

func _process(delta):
	global_position += direction * speed * delta
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * speed * delta)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.is_in_group("walls"):
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(damage, Vector2.ZERO)
		body.stun(stun_duration)

		# Only split if there are bounces left
		if bounce_count > 0:
			spawn_bouncing_projectiles()

		queue_free()
	elif body.is_in_group("walls") or body.is_in_group("obstacles"):
		queue_free()

func spawn_extra_projectile():
	var projectile_scene = preload("res://Characters/stun.tscn")  # ✅ Ensure correct path!
	var extra_projectile = projectile_scene.instantiate()

	extra_projectile.global_position = global_position + (direction * 10)  # ✅ Small offset
	extra_projectile.damage = damage
	extra_projectile.stun_duration = stun_duration
	extra_projectile.direction = direction.rotated(deg_to_rad(10))
	extra_projectile.is_dragonus = false
	extra_projectile.bounce_count = bounce_count  # ✅ Ensure it inherits bounce count
	extra_projectile.speed = speed  # ✅ Ensure speed is inherited

	get_tree().current_scene.call_deferred("add_child", extra_projectile)

func spawn_bouncing_projectiles():
	var projectile_scene = preload("res://Characters/stun.tscn")  # ✅ Load the correct scene

	# Create two new projectiles with rotated directions
	for angle in [-15, 15]:  # ✅ Wider spread for more noticeable effect
		var new_projectile = projectile_scene.instantiate()
		new_projectile.global_position = global_position + (direction * 15)  # ✅ Offset to avoid re-hitting the same enemy
		new_projectile.damage = damage
		new_projectile.stun_duration = stun_duration
		new_projectile.direction = direction.rotated(deg_to_rad(angle))  # ✅ Set new direction
		new_projectile.bounce_count = bounce_count - 1  # ✅ Decrease bounce count
		new_projectile.speed = speed  # ✅ Ensure new projectiles have speed

		get_tree().current_scene.call_deferred("add_child", new_projectile)
