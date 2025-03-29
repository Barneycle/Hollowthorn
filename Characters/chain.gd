extends Area2D

@export var speed: float = 200
@export var damage: int = 10
@export var bounce_count: int = 5
@export var slow_duration: float = 2.0
@export var slow_factor: float = 0.5

var range: float = 5000
var bounces_left: int
var target: Node2D
var hit_enemies: Array = []  # Stores already hit enemies to prevent bouncing back

func _ready():
	bounces_left = bounce_count
	find_new_target()
	connect("body_entered", _on_collision)

func _process(delta):
	if target:
		position = position.move_toward(target.global_position, speed * delta)

		if global_position.distance_to(target.global_position) < 10:
			apply_effects(target)
			bounce()

func find_new_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	enemies = enemies.filter(func(e): return e not in hit_enemies and e != target)  

	if enemies.is_empty():
		bounce_off_wall()
	else:
		enemies.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
		target = enemies[0]

func apply_effects(enemy):
	if not enemy is CharacterBody2D or not enemy.has_method("take_damage"):
		return 
	
	enemy.take_damage(damage, Vector2.ZERO)
	enemy.apply_slow(slow_factor, slow_duration)
	hit_enemies.append(enemy)

	global_position += (global_position - enemy.global_position).normalized() * 20

func bounce():
	if bounces_left > 0:
		bounces_left -= 1
		await get_tree().create_timer(0.2).timeout  
		find_new_target()
	else:
		queue_free()

func bounce_off_wall():
	var random_angle = randf_range(-PI / 3, PI / 3)
	var bounce_direction = (global_position - target.global_position).normalized().rotated(random_angle)
	
	var new_target_position = global_position + (bounce_direction * 100)
	var direction = (new_target_position - global_position).normalized()
	global_position += direction * speed * 0.1  

func _on_collision(body):
	if body.is_in_group("walls"):
		bounce_off_wall()
