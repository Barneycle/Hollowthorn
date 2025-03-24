extends Area2D

@export var speed: float = 200
@export var max_speed: float = 300
@export var damage: int = 50
@export var knockback_force: float = 50
@export var is_dragonus: bool = false

var direction: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	
	sprite.play("bolt")
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
		
		var knockback_direction = (body.global_position - global_position).normalized()
		
		body.take_damage(damage, knockback_direction * knockback_force)  
		queue_free()
		
	elif body.is_in_group("walls") or body.is_in_group("obstacles"):
		queue_free()

func spawn_extra_projectile():
	
	var projectile_scene = preload("res://Characters/bolt.tscn")
	var extra_projectile = projectile_scene.instantiate()
	
	extra_projectile.global_position = global_position
	extra_projectile.damage = damage
	extra_projectile.direction = direction.rotated(deg_to_rad(10))
	extra_projectile.is_dragonus = false

	get_tree().current_scene.call_deferred("add_child", extra_projectile)
