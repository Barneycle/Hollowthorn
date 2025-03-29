extends Area2D

@export var speed: float = 200
@export var max_speed: float = 300
@export var damage: int = 0
@export var knockback_force: float = 50
@export var explosion_radius: float = 80  # AoE damage radius
@export var aoe_duration: float = 3.0  # Time AoE lingers
@export var is_dragonus: bool = false

var direction: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var explosion_timer = $ExplosionTimer

func _ready():
	sprite.play("fire")  # Use an appropriate animation name
	connect("body_entered", _on_body_entered)

	if is_dragonus:
		spawn_extra_projectile()

func _process(delta):
	global_position += direction * speed * delta
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * speed * delta)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.is_in_group("walls"):
		explode()
		
func spawn_extra_projectile():
	var projectile_scene = preload("res://Characters/kisses.tscn")
	var extra_projectile = projectile_scene.instantiate()
	
	extra_projectile.global_position = global_position + (direction * 10)
	extra_projectile.damage = damage
	extra_projectile.speed = speed
	extra_projectile.is_dragonus = false
	
	extra_projectile.set_direction(direction.rotated(deg_to_rad(10)))  
	get_tree().current_scene.call_deferred("add_child", extra_projectile)

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		var knockback_direction = (body.global_position - global_position).normalized()
		body.take_damage(damage, knockback_direction * knockback_force)  
		explode()
	elif body.is_in_group("walls") or body.is_in_group("obstacles"):
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
				var knockback_direction = (enemy.global_position - global_position).normalized()
				var aoe_knockback = knockback_direction * (knockback_force / 2)
				enemy.take_damage(damage / 2, aoe_knockback)
