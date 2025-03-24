extends CharacterBody2D

@export var move_speed : float = 100
@export var starting_direction : Vector2 = Vector2(0, 1)

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var shoot_timer = $shoot_timer

func _ready():
	
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
	
	launch_projectile("res://Characters/bolt.tscn")
	
	await get_tree().create_timer(0.5).timeout
	
	launch_projectile("res://Characters/stun.tscn")


func launch_projectile(scene_path):
	
	var projectile_scene = load(scene_path)
	var projectile = projectile_scene.instantiate()
	
	projectile.global_position = global_position

	var nearest_enemy = find_nearest_enemy()
	
	if nearest_enemy:
		
		projectile.direction = (nearest_enemy.global_position - global_position).normalized()
		
	else:
		
		projectile.direction = Vector2(0, -1)

	get_tree().current_scene.call_deferred("add_child", projectile)

func find_nearest_enemy():
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var min_distance = INF  

	for enemy in enemies:
		
		var distance = global_position.distance_to(enemy.global_position)
		
		if distance < min_distance:
			
			min_distance = distance
			nearest_enemy = enemy

	return nearest_enemy
