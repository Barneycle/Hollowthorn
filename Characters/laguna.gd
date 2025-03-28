extends Area2D

@export var speed: float = 250
@export var damage: int = 40
@export var knockback_force: float = 50
@export var extra_projectiles: int = 0  # Increases at levels 2, 4, 6, 8
@export var is_extra: bool = false  # Prevents infinite extra projectiles

var direction: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	sprite.play("laguna")  # Use "laguna" animation
	connect("body_entered", _on_body_entered)

	# Spawn extra projectiles if allowed
	if extra_projectiles > 0 and not is_extra:
		spawn_extra_projectiles()

func _process(delta):
	global_position += direction * speed * delta

	# Check collision with walls (prevents infinite travel)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * speed * delta)
	var result = space_state.intersect_ray(query)

	if result and result.collider.is_in_group("walls"):
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		var knockback_direction = (body.global_position - global_position).normalized()
		body.take_damage(damage, knockback_direction * knockback_force)  
		queue_free()
	elif body.is_in_group("walls") or body.is_in_group("obstacles"):
		queue_free()

func spawn_extra_projectiles():
	for i in range(extra_projectiles):
		var projectile_scene = preload("res://Characters/laguna.tscn")
		var extra_projectile = projectile_scene.instantiate()

		extra_projectile.global_position = global_position
		extra_projectile.damage = damage
		extra_projectile.direction = direction.rotated(deg_to_rad(randf_range(-10, 10)))  # Slight spread
		extra_projectile.is_extra = true

		get_tree().current_scene.call_deferred("add_child", extra_projectile)

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
