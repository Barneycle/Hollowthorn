extends CharacterBody2D

@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0, 1)
@export var max_health : float = 100  # Default HP
@export var track_damage: int = 6
@export var track_cooldown: float = 10.0
@export var track_projectile_count: int = 1
@export var track_amp: float = 0.2  # 20% extra damage
@export var track_duration: float = 10.0

var track_ready = true  # Track cooldown system
# Scion of Skywrath effect (only for player_cat)
var extra_projectiles = 0
var spread_angle = 0

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var shoot_timer = $shoot_timer

var current_health

func _ready():
	# Apply Scion of Skywrath effect only to player_cat
	if name == "PlayerCat":
		
		max_health *= 0.75  # Reduce HP
		extra_projectiles = 2  # Additional projectiles
		spread_angle = 15  # Spread angle between projectiles
	
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
	shoot_projectile("res://Characters/bolt.tscn")
	await get_tree().create_timer(0.5).timeout
	shoot_projectile("res://Characters/stun.tscn")
	await get_tree().create_timer(0.5).timeout
	cast_kisses()
	await get_tree().create_timer(0.5).timeout
	cast_track()

func shoot_projectile(scene_path):
	var projectile_scene = load(scene_path)
	var base_projectile = projectile_scene.instantiate()
	
	var nearest_enemy = find_nearest_enemy()
	var base_direction = Vector2(0, -1) if not nearest_enemy else (nearest_enemy.global_position - global_position).normalized()
	
	launch_projectile(base_projectile, base_direction)
	
	# Only player_cat gets extra projectiles
	if name == "PlayerCat" and extra_projectiles > 0:
		for i in range(extra_projectiles):
			var spread_offset = spread_angle * ((i + 1) / 2) * (-1 if i % 2 == 0 else 1)
			var new_direction = base_direction.rotated(deg_to_rad(spread_offset))
			var extra_projectile = projectile_scene.instantiate()
			extra_projectile.direction = new_direction
			launch_projectile(extra_projectile, new_direction)

func launch_projectile(projectile, direction):
	projectile.global_position = global_position
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)
	else:
		projectile.direction = direction  # Ensure it has the property
	get_tree().current_scene.call_deferred("add_child", projectile)

func find_nearest_enemy() -> Node2D:
	var nearest_enemy = null
	var min_distance = INF

	for enemy in get_tree().get_nodes_in_group("enemies"):  # ✅ Ensure enemies are in the correct group
		if not enemy is Node2D:
			print("⚠️ Skipping non-Node2D:", enemy)
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy

	return nearest_enemy

	
func cast_kisses():
	var nearest_enemy = find_nearest_enemy()
	if not nearest_enemy:
		return  # Don't shoot if no enemies exist

	var projectile_scene = load("res://Characters/kisses.tscn")
	var projectile = projectile_scene.instantiate()

	var direction = (nearest_enemy.global_position - global_position).normalized()
	projectile.global_position = global_position
	projectile.set_direction(direction)  # Set movement direction

	# Add to scene
	get_tree().current_scene.add_child(projectile)

func find_strongest_enemy(range: float) -> Node2D:
	# Retrieve all enemies (adjust "enemies" to the actual group name in your game)
	var enemies = get_tree().get_nodes_in_group("enemies")

	var strongest_enemy = null
	var highest_hp = -1
	var closest_enemy = null
	var closest_distance = INF  

	for enemy in enemies:
		# 🛑 Skip nodes that aren't actual enemies or don't have current_hp
		if not (enemy is CharacterBody2D) or not ("current_hp" in enemy):
			print_debug("Skipping non-enemy node:", enemy.name)
			continue  

		# 🟢 Must be inside the loop
		var distance = enemy.global_position.distance_to(global_position)  

		# Find the enemy with the highest HP in range
		if distance <= range and enemy.current_hp > highest_hp:
			strongest_enemy = enemy
			highest_hp = enemy.current_hp

		# Find the closest enemy in range as a backup
		if distance <= range and distance < closest_distance:
			closest_enemy = enemy
			closest_distance = distance

	# If no strongest enemy was found, default to the closest enemy
	if strongest_enemy == null and closest_enemy != null:
		strongest_enemy = closest_enemy

	return strongest_enemy

func cast_track():
	if not track_ready:
		return  # On cooldown

	var enemy = find_strongest_enemy(200)  # Adjust range
	if enemy:
		track_ready = false

		enemy.apply_mark(track_amp, track_duration)  # Mark the enemy

		# Reset cooldown
		await get_tree().create_timer(track_cooldown).timeout
		track_ready = true

func apply_track_effect(enemy: Node2D) -> void:
	if enemy == null:
		print_debug("⚠️ No enemy found to apply Track effect!")
		return

	# Example effect: Mark the enemy (customize this as needed)
	enemy.add_mark()  # Ensure enemy has this method
	print_debug("✅ Track effect applied to:", enemy.name)
