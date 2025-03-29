extends Area2D

@export var speed: float = 200
@export var max_speed: float = 300
@export var damage: int = 48
@export var knockback_force: float = 104
@export var pierce_count: int = 1
@export var projectile_count: int = 9  # Still keeping for reference

var direction: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	sprite.play("bolt")
	connect("body_entered", _on_body_entered)

func _process(delta):
	global_position += direction * speed * delta

	# Check for collision with walls
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * speed * delta)
	var result = space_state.intersect_ray(query)

	if result and result.collider.is_in_group("walls"):
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		var knockback_direction = (body.global_position - global_position).normalized()
		body.take_damage(damage, knockback_direction * knockback_force)

		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()
	elif body.is_in_group("walls") or body.is_in_group("obstacles"):
		queue_free()

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
