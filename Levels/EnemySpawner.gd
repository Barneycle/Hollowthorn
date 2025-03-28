extends Node2D

@export var enemy_scene: PackedScene  # Drag enemy scene into Inspector
@export var spawn_area: Control  # Defines spawn area
@export var underground_tilemap: TileMap  # Tilemap containing water tiles
@export var spawn_delay: float = 0.8  # Faster enemy spawns

var max_attempts = 100  # More attempts to find land
var max_enemies = 15  # Increase enemy count
var current_enemies = 0

@onready var timer: Timer = $Timer  # Ensure Timer exists

func _ready():
	if not timer:
		print("❌ Timer node is missing!")
		return

	timer.wait_time = spawn_delay
	timer.timeout.connect(spawn_enemy)
	timer.start()

func spawn_enemy():
	if current_enemies >= max_enemies:
		return  # Stop if at limit

	var spawn_pos = get_valid_spawn_position()
	if spawn_pos != Vector2.ZERO:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_pos
		add_child(enemy)
		current_enemies += 1
		timer.start(spawn_delay)  # Schedule next spawn

func get_valid_spawn_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return Vector2.ZERO  # No player found

	for _i in range(max_attempts):  # Try multiple times
		var random_pos = get_random_position_near_player(player.global_position)
		if not is_position_in_water(random_pos):
			return random_pos

	print("⚠️ No valid spawn position found.")
	return Vector2.ZERO  # Return (0,0) if all fail

func get_random_position_near_player(player_pos: Vector2) -> Vector2:
	var rect = spawn_area.get_global_rect()
	
	var min_distance = 100  # Minimum distance from player
	var max_distance = 250  # Maximum distance (so they don't spawn too far)
	
	var angle = randf_range(0, TAU)
	var distance = randf_range(min_distance, max_distance)
	
	var rand_x = player_pos.x + cos(angle) * distance
	var rand_y = player_pos.y + sin(angle) * distance
	
	return Vector2(rand_x, rand_y)

func is_position_in_water(position: Vector2) -> bool:
	if not underground_tilemap:
		print("❌ Tilemap not set!")
		return false

	# Convert the global position to the tilemap's local position
	var tile_pos = underground_tilemap.local_to_map(underground_tilemap.to_local(position))

	# Check if the tile position is within the bounds of the tilemap
	if not underground_tilemap.get_used_cells(0).has(tile_pos):
		return false  # Outside bounds

	# Get the tile ID at the specified position
	var tile_id = underground_tilemap.get_cellv(tile_pos)

	# Check if the tile ID corresponds to a water tile
	if tile_id != -1:  # Ensure the tile exists
		var tile_data = underground_tilemap.tile_set.tile_get_metadata(tile_id)
		if tile_data and tile_data.get("water", false):  # Check for custom data "water"
			return true  # Water detected

	return false
