extends Area2D

@export var speed: float = 200
@export var max_speed: float = 300
@export var damage: int = 48
@export var explosion_radius: float = 380
@export var aoe_duration: float = 3.0
@export var projectile_count: int = 9
@export var cooldown: float = 2.5

var direction: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var explosion_timer = $ExplosionTimer

func _ready():
	sprite.play("fire")  # Use an appropriate animation name
	connect("body_entered", _on_body_entered)

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

	# Adjust the explosion's CollisionShape2D size
	var explosion_area = explosion.get_node("Area2D/CollisionShape2D")
	if explosion_area:
		explosion_area.shape.radius = explosion_radius  # Set radius dynamically

	# Add explosion effect to the scene
	get_tree().current_scene.call_deferred("add_child", explosion)

	queue_free()  # Remove projectile

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
