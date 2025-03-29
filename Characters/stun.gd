extends Area2D

@export var speed: float = 200
@export var max_speed: float = 300
@export var damage: int = 0
@export var stun_duration: float = 2.0
@export var bounce_count: int = 1

var direction: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	sprite.play("stun")
	connect("body_entered", _on_body_entered)

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

		# Only spawn bouncing projectiles if there are enemies around
		if bounce_count > 0 and find_nearest_enemy():
			spawn_bouncing_projectiles()

		queue_free()
	elif body.is_in_group("walls") or body.is_in_group("obstacles"):
		queue_free()

func spawn_bouncing_projectiles():
	if not find_nearest_enemy():
		return  # No enemy, don't spawn

	var projectile_scene = preload("res://Characters/stun.tscn")

	for angle in [-15, 15]:
		var new_projectile = projectile_scene.instantiate()
		new_projectile.global_position = global_position + (direction * 15)
		new_projectile.damage = damage
		new_projectile.stun_duration = stun_duration
		new_projectile.direction = direction.rotated(deg_to_rad(angle))
		new_projectile.bounce_count = bounce_count - 1
		new_projectile.speed = speed

		get_tree().current_scene.call_deferred("add_child", new_projectile)

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()

func find_nearest_enemy() -> Node2D:
	var nearest_enemy = null
	var min_distance = INF

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy

	return nearest_enemy
