extends Node2D

@export var spawns: Array[Spawn_info] = []

@onready var player_cat = get_tree().get_first_node_in_group("player_cat")

var time: int = 0
var max_wave_time: int = 300

func _on_timer_timeout() -> void:
	time = (time + 1) % max_wave_time

	for spawn_info in spawns:
		if time >= spawn_info.time_start and time <= spawn_info.time_end:
			if spawn_info.spawn_delay_counter < spawn_info.enemy_spawn_delay:
				spawn_info.spawn_delay_counter += 1
			else:
				spawn_info.spawn_delay_counter = 0
				spawn_enemies(spawn_info)
		elif time > spawn_info.time_end:
			spawn_info.spawn_delay_counter = 0

func spawn_enemies(spawn_info: Spawn_info) -> void:
	await get_tree().process_frame  # Ensures a frame passes before spawning

	var enemy_scene = load(spawn_info.enemy.resource_path) if spawn_info.enemy else null
	if enemy_scene == null:
		return  # Skip if the enemy scene is invalid

	for _i in range(spawn_info.enemy_num):
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.global_position = get_valid_spawn_position()
		get_tree().current_scene.add_child(enemy_instance)

func get_valid_spawn_position() -> Vector2:
	var max_attempts: int = 10

	for _i in range(max_attempts):
		var spawn_position = get_random_position()
		if not is_position_in_water(spawn_position) and not is_position_near_player(spawn_position):
			return spawn_position

	# Default fallback near the player
	return player_cat.global_position + Vector2(100, 100)

func is_position_near_player(spawn_pos: Vector2) -> bool:
	return spawn_pos.distance_to(player_cat.global_position) < 50

func get_random_position() -> Vector2:
	var vpr = get_viewport_rect().size
	var bottom_right_corner = Vector2(vpr.x / 2, vpr.y / 2)
	var radius = bottom_right_corner.length() * randf_range(1.1, 1.4)
	var angle = randf_range(0, 2 * PI)
	return Vector2(radius, 0).rotated(angle)

func is_position_in_water(spawn_pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()

	query.shape = RectangleShape2D.new()
	query.shape.extents = Vector2(8, 8)  # Small area check
	query.transform = Transform2D(0, spawn_pos)
	query.collide_with_areas = true

	var results = space_state.intersect_shape(query)

	for result in results:
		var collider = result.collider
		if collider.is_in_group("water_zones") or collider.is_in_group("obstacles"):
			return true

	return false
