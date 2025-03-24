extends CharacterBody2D

@export var speed: float = 40
@export var attack_range: float = 20
@export var attack_delay: float = 0.5
@export var max_hp: int = 100
@export var friction: float = 5.0  
@export var max_knockback_distance: float = 50
@export var knockback_duration: float = 0.2

@onready var anim = $AnimatedSprite2D
@onready var player = get_tree().get_nodes_in_group("player_cat")[0] if get_tree().has_group("player_cat") else null
@onready var nav_agent = $NavigationAgent2D

var current_hp: int
var attacking = false
var dead = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0  
var last_direction: String = "down"
var stuck_timer = 0.0  # Timer to track if enemy is stuck
var previous_position = Vector2.ZERO  # Store last position

func _ready():
	current_hp = max_hp
	
	if player:
		nav_agent.target_position = player.global_position
	else:
		print_debug("⚠️ Player (player_cat) not found!")

func _process(_delta):
	if dead or attacking or knockback_timer > 0:
		return

	if player:
		# Continuously update the path toward the player
		nav_agent.target_position = player.global_position
		
		var distance = global_position.distance_to(player.global_position)
		
		if distance <= attack_range:
			start_attack()
		else:
			chase_player()

func chase_player():
	if attacking or knockback_timer > 0:
		return

	if player:
		# Set target position only if the path is valid
		if nav_agent.is_target_reachable():
			nav_agent.target_position = player.global_position

	var next_path_position = nav_agent.get_next_path_position()
	if next_path_position == Vector2.ZERO:
		return  # No valid path, do not move

	var direction = (next_path_position - global_position).normalized()

	# Check if moving towards an obstacle
	if not nav_agent.is_target_reachable():
		velocity = Vector2.ZERO  # Stop moving if path is blocked
	else:
		velocity = direction * speed  # Move normally if path is clear

	move_and_slide()

	# Play the correct animation based on movement direction
	if abs(direction.x) > abs(direction.y):
		anim.play("walk_right" if direction.x > 0 else "walk_left")
	else:
		anim.play("walk_down" if direction.y > 0 else "walk_up")


func start_attack():
	attacking = true
	velocity = Vector2.ZERO

	var direction = (player.global_position - global_position).normalized()
	if abs(direction.x) > abs(direction.y):
		anim.play("attack_right" if direction.x > 0 else "attack_left")
	else:
		anim.play("attack_down" if direction.y > 0 else "attack_up")

	await get_tree().create_timer(attack_delay).timeout
	attacking = false

func die():
	if dead:
		return
		
	dead = true
	velocity = Vector2.ZERO
	set_process(true)

	anim.play("death_" + last_direction)

	await get_tree().create_timer(1.0).timeout
	queue_free()

func take_damage(amount: int, knockback: Vector2):
	if dead:
		return
	
	current_hp -= amount
	print("Enemy HP:", current_hp)

	show_damage_number(amount)

	if knockback.length() > max_knockback_distance:
		knockback = knockback.normalized() * max_knockback_distance

	knockback_velocity = knockback  
	knockback_timer = knockback_duration  

	if current_hp <= 0:
		die()

func show_damage_number(amount: int):
	var damage_number_scene = preload("res://Levels/label.tscn")
	var damage_number = damage_number_scene.instantiate()
	
	damage_number.text = str(amount)  
	damage_number.global_position = global_position + Vector2(randf_range(-10, 10), -20)  
	
	get_parent().add_child(damage_number)

func stun(duration: float):
	if dead:
		return

	var stun_timer = $StunTimer if has_node("StunTimer") else null
	
	if stun_timer:
		stun_timer.start(duration)
	else:
		print_debug("⚠️ StunTimer not found!")

	velocity = Vector2.ZERO  
	set_process(false)  

	anim.play("stun_" + last_direction)

	await stun_timer.timeout  

	if not dead:
		set_process(true)

func _physics_process(delta):
	if dead or attacking or knockback_timer > 0:
		return

	# Check if navigation is finished
	if player and not nav_agent.is_navigation_finished():
		nav_agent.target_position = player.global_position

	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	# Prevent enemies from getting stuck
	if global_position.distance_to(previous_position) < 1.0:
		stuck_timer += delta
		if stuck_timer > 0.5:  # If stuck for 0.5 seconds, recalculate path
			nav_agent.target_position = player.global_position
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0  # Reset timer if moving normally

	previous_position = global_position

	# Ensure proper movement
	if direction.length() > 0.1 and nav_agent.is_target_reachable():
		velocity = velocity.lerp(direction * speed, 0.1)
	else:
		velocity = Vector2.ZERO  # Stop moving if path is blocked

	move_and_slide()
