extends Node2D

@export var spawns: Array[Spawn_info] = []

@onready var player_cat = get_tree().get_first_node_in_group("player_cat")

var time = 0
var max_wave_time = 300

func _on_timer_timeout() -> void:
	time += 1
	
	if time > max_wave_time:
		time = time % max_wave_time

	for i in spawns:
		if time >= i.time_start and time <= i.time_end:
			if i.spawn_delay_counter < i.enemy_spawn_delay:
				i.spawn_delay_counter += 1
			else:
				i.spawn_delay_counter = 0
				spawn_enemies(i)

		if time > i.time_end:
			i.spawn_delay_counter = 0

func spawn_enemies(spawn_info: Spawn_info):
	await get_tree().process_frame  # Wait for one frame before checking

	var enemy_types = [spawn_info.enemy, spawn_info.enemy, spawn_info.enemy]  # Include orc_2 and orc_3
	var enemy_names = ["orc_1", "orc_2", "orc_3"]  # Names for debug purposes

	for idx in range(enemy_types.size()):
		var enemy_scene = load(enemy_types[idx].resource_path) if enemy_types[idx] else null
		if enemy_scene == null:
			print("❌ ERROR: Could not load enemy scene:", enemy_names[idx])
			continue

		var counter = 0
		while counter < spawn_info.enemy_num:
			var enemy_spawn = enemy_scene.instantiate()
			enemy_spawn.global_position = get_valid_spawn_position()
			
			# Add to correct parent (ensure enemies are in the game scene)
			get_tree().current_scene.add_child(enemy_spawn)
			
			print("✅ Spawned:", enemy_names[idx], "at", enemy_spawn.global_position)
			counter += 1

func get_valid_spawn_position():
	var max_attempts = 10
	var attempts = 0
	var spawn_position = Vector2.ZERO

	while attempts < max_attempts:
		spawn_position = get_random_position()

		if not is_position_in_water(spawn_position) and not is_position_near_player(spawn_position):
			print("✅ Valid spawn position found:", spawn_position)
			return spawn_position

		print("❌ Invalid spawn position (retrying):", spawn_position)
		attempts += 1

	print("⚠️ Failed to find a valid position, defaulting near player")
	return player_cat.global_position + Vector2(100, 100)

func is_position_near_player(spawn_pos: Vector2) -> bool:
	return spawn_pos.distance_to(player_cat.global_position) < 50

func get_random_position():
	var vpr = get_viewport_rect().size
	var bottom_right_corner = Vector2(vpr.x / 2, vpr.y / 2)
	var radius = Vector2.ZERO.distance_to(bottom_right_corner) * randf_range(1.1, 1.4)
	var angle = randf_range(0, 2 * PI)
	return Vector2(radius, 0).rotated(angle)

func is_position_in_water(spawn_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()

	var shape = RectangleShape2D.new()
	shape.extents = Vector2(8, 8)  # Small area check

	query.shape = shape
	query.transform = Transform2D(0, spawn_pos)
	query.collide_with_areas = true

	var results = space_state.intersect_shape(query)

	if results.is_empty():
		print("✅ No collision at:", spawn_pos)
	else:
		print("⚠️ Collision detected at:", spawn_pos)
		for result in results:
			print("   → Collided with:", result.collider.name, "Groups:", result.collider.get_groups())

	for result in results:
		if result.collider.is_in_group("water_zones"):
			print("❌ Water detected at", spawn_pos)
			return true
		if result.collider.is_in_group("obstacles"):
			print("❌ Obstacle detected at", spawn_pos)
			return true

	return false
