extends Area2D

@export var speed: float = 200
@export var max_speed: float = 300
@export var damage: int = 48  # Max level: 48 magic damage
@export var explosion_radius: float = 380  # Max level: Radius 380 (Base 300 + 10*8)
@export var aoe_duration: float = 3.0  # Time AoE lingers
@export var projectile_count: int = 9  # Max level: 9 projectiles
@export var cooldown: float = 2.5  # Max level: Cooldown 2.5s (Base 5 - 0.5*8)
@export var is_dragonus: bool = false

var direction: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var explosion_timer = $ExplosionTimer

func _ready():
	sprite.play("fire")  # Use an appropriate animation name
	connect("body_entered", _on_body_entered)

	if is_dragonus:
		spawn_extra_projectiles()

func _process(delta):
	global_position += direction * speed * delta
	
	# Collision check using Area2D's physics
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = collision_layer  # Ensure it checks the right layers

	var result = space_state.intersect_point(query)
	if result:
		explode()


func spawn_extra_projectiles():
	var projectile_scene = preload("res://Characters/kisses.tscn")
	var total_projectiles = projectile_count + (1 if name == "PlayerCat" else 0)  # PlayerCat gets 10 total

	for i in range(total_projectiles):
		var angle = (2 * PI / total_projectiles) * i  # Circular pattern
		var new_direction = Vector2.RIGHT.rotated(angle)  # Get direction

		var extra_projectile = projectile_scene.instantiate()
		extra_projectile.global_position = global_position + (new_direction * 20)  # Offset from center
		extra_projectile.set_direction(new_direction)
		extra_projectile.damage = damage
		extra_projectile.explosion_radius = explosion_radius

		get_tree().current_scene.call_deferred("add_child", extra_projectile)

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(damage, Vector2.ZERO)  # No knockback
		explode()


func explode():
	var explosion_scene = preload("res://Characters/explosion.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", explosion)

	explosion_timer.start(aoe_duration)
	apply_aoe_damage()

	queue_free()

func _on_explosion_timer_timeout():
	queue_free()

func apply_aoe_damage():
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not enemy or not enemy is Node2D:
			continue  

		if enemy.global_position.distance_to(global_position) <= explosion_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage / 2, Vector2.ZERO)  # No knockback
