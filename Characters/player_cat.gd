extends CharacterBody2D

@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0, 1)
@export var max_health : float = 100
@export var track_damage: int = 6
@export var track_cooldown: float = 10.0
@export var track_projectile_count: int = 1
@export var track_amp: float = 0.2
@export var track_duration: float = 10.0
@export var projectile_count: int = 9

var track_ready = true
var extra_projectiles = 0
var spread_angle = 0

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var shoot_timer = $shoot_timer

var current_health

func _ready():
	if name == "PlayerCat":
		max_health *= 0.75
		extra_projectiles = 2
		spread_angle = 15
	
	current_health = max_health
	update_animation_parameters(starting_direction)
	shoot_timer.timeout.connect(shoot)

func _physics_process(_delta):
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()
	
	update_animation_parameters(input_direction)
	
	velocity = input_direction * move_speed
	move_and_slide()
	pick_new_state()

func update_animation_parameters(move_input : Vector2):
	if move_input != Vector2.ZERO:
		animation_tree.set("parameters/Walk/blend_position", move_input)
		animation_tree.set("parameters/Idle/blend_position", move_input)

func pick_new_state():
	if velocity != Vector2.ZERO:
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")

func shoot():
	
	cast_bolt()
	await get_tree().create_timer(0.5).timeout
	cast_stun()
	#await get_tree().create_timer(0.5).timeout
	#cast_track()
	#await get_tree().create_timer(0.5).timeout
	#cast_kisses()
	#await get_tree().create_timer(0.5).timeout
	#cast_chain()
	#await get_tree().create_timer(0.5).timeout
	#cast_laguna()

func cast_bolt():
	
	var projectile_scene = load("res://Characters/bolt.tscn")
	var total_projectiles = projectile_count + (1 if name == "PlayerCat" else 0)

	for i in range(total_projectiles):
		var angle = (2 * PI / total_projectiles) * i
		var direction = Vector2.RIGHT.rotated(angle)

		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position + (direction * 20)
		projectile.set_direction(direction)

		get_tree().current_scene.add_child(projectile)

func cast_stun():
	
	var projectile_scene = load("res://Characters/stun.tscn")
	var total_projectiles = projectile_count + (1 if name == "PlayerCat" else 0)

	for i in range(total_projectiles):
		var angle = (2 * PI / total_projectiles) * i
		var direction = Vector2.RIGHT.rotated(angle)

		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position + (direction * 20)
		projectile.set_direction(direction)

		get_tree().current_scene.add_child(projectile)


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

func cast_kisses():
	var nearest_enemy = find_nearest_enemy()
	if not nearest_enemy:
		return

	var projectile_scene = load("res://Characters/kisses.tscn")
	var projectile = projectile_scene.instantiate()

	var direction = (nearest_enemy.global_position - global_position).normalized()
	projectile.global_position = global_position
	projectile.set_direction(direction)

	get_tree().current_scene.add_child(projectile)
	
	if name == "PlayerCat" and extra_projectiles > 0:
		for i in range(extra_projectiles):
			var spread_offset = spread_angle * ((i + 1) / 2) * (-1 if i % 2 == 0 else 1)
			var new_direction = direction.rotated(deg_to_rad(spread_offset))
			var extra_projectile = projectile_scene.instantiate()
			extra_projectile.set_direction(new_direction)
			extra_projectile.global_position = global_position
			get_tree().current_scene.add_child(extra_projectile)

func find_strongest_enemy(range: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var strongest_enemy = null
	var highest_hp = -1
	var closest_enemy = null
	var closest_distance = INF  

	for enemy in enemies:
		if not (enemy is CharacterBody2D) or not ("current_hp" in enemy):
			continue  

		var distance = enemy.global_position.distance_to(global_position)  

		if distance <= range and enemy.current_hp > highest_hp:
			strongest_enemy = enemy
			highest_hp = enemy.current_hp

		if distance <= range and distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance

	if strongest_enemy == null and closest_enemy != null:
		strongest_enemy = closest_enemy

	return strongest_enemy

func cast_track():
	if not track_ready:
		return

	var primary_enemy = find_strongest_enemy(3000)

	if primary_enemy and primary_enemy.has_method("apply_mark"):
		track_ready = false
		primary_enemy.apply_mark(0.7, 10)

		if name == "PlayerCat":
			var all_enemies = get_tree().get_nodes_in_group("enemies")
			var marked_count = 0

			for enemy in all_enemies:
				if enemy != primary_enemy and marked_count < 4:
					if enemy.has_method("apply_mark"):
						enemy.apply_mark(0.7, 10)
						marked_count += 1

		await get_tree().create_timer(4).timeout
		track_ready = true

func apply_track_effect(enemy: Node2D) -> void:
	if enemy == null:
		return

	enemy.add_mark()

func cast_chain():
	var chain_scene = preload("res://Characters/chain.tscn")
	var chain = chain_scene.instantiate()
	
	chain.global_position = global_position
	get_parent().add_child(chain)

func cast_laguna():
	var laguna_scene = preload("res://Characters/laguna.tscn")
	var laguna = laguna_scene.instantiate()
	
	laguna.global_position = global_position
	var target = find_nearest_enemy()

	if target:
		laguna.set_direction((target.global_position - global_position).normalized())
	else:
		laguna.set_direction(Vector2.RIGHT)

	get_parent().add_child(laguna)
	
	if name == "PlayerCat" and extra_projectiles > 0:
		for i in range(extra_projectiles):
			var spread_offset = spread_angle * ((i + 1) / 2) * (-1 if i % 2 == 0 else 1)
			var new_direction = laguna.direction.rotated(deg_to_rad(spread_offset))
			var extra_projectile = laguna_scene.instantiate()
			extra_projectile.set_direction(new_direction)
			extra_projectile.global_position = global_position
			get_tree().current_scene.add_child(extra_projectile)
