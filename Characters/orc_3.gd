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
@onready var notifier = $VisibleOnScreenNotifier2D if has_node("VisibleOnScreenNotifier2D") else null
@onready var path_timer = $PathfindingUpdateTimer  # Add a Timer node in the scene (set to 0.5s)
@onready var stun_timer = $StunTimer if has_node("StunTimer") else null

var current_hp: int
var attacking = false
var dead = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_timer: float = 0.0  
var last_direction: String = "down"
var stuck_timer = 0.0  
var previous_position = Vector2.ZERO  
var can_update_path = true  # Used to control pathfinding frequency
var is_marked = false
var damage_amp = 1.0

func _ready():
	current_hp = max_hp
	path_timer.start()  # Start the timer to update pathfinding every 0.5s
	path_timer.timeout.connect(_on_PathUpdateTimer_timeout)

	if not player:
		print_debug("⚠️ Player (player_cat) not found!")

func _process(_delta):
	if not notifier.is_on_screen() or dead or attacking or knockback_timer > 0:
		return  # Skip updates if off-screen, dead, attacking, or knocked back

	var distance = global_position.distance_to(player.global_position)
	
	if distance <= attack_range:
		start_attack()
	elif can_update_path:
		chase_player()

func _on_PathUpdateTimer_timeout():
	can_update_path = true  # Allow path updates

func chase_player():
	if attacking or knockback_timer > 0 or dead:
		return

	if can_update_path and player:
		nav_agent.target_position = player.global_position  
		can_update_path = false  # Prevent frequent path updates

	var next_position = nav_agent.get_next_path_position()
	if next_position == Vector2.ZERO:
		return  

	var direction = (next_position - global_position).normalized()

	# Check if stuck (moved less than 1px in last 0.5s)
	if global_position.distance_to(previous_position) < 1.0:
		stuck_timer += get_process_delta_time()
		if stuck_timer > 0.5:
			velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10  
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0  

	previous_position = global_position  

	if direction.length() > 0.1 and nav_agent.is_target_reachable():
		velocity = velocity.lerp(direction * speed, 0.1)
	else:
		velocity = Vector2.ZERO  

	move_and_slide()
	update_animation(direction)

func update_animation(direction: Vector2):
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
	set_process(false)  # Stop further updates

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
	else:
		chase_player()  

func show_damage_number(amount: int):
	var damage_number_scene = preload("res://Levels/label.tscn")
	var damage_number = damage_number_scene.instantiate()
	
	damage_number.text = str(amount)  
	damage_number.global_position = global_position + Vector2(randf_range(-10, 10), -20)  
	
	get_parent().add_child(damage_number)

func stun(duration: float):
	if dead:
		return

	if stun_timer:
		stun_timer.start(duration)
	else:
		print_debug("⚠️ StunTimer not found!")

	velocity = Vector2.ZERO  
	set_physics_process(false)  # Stop physics updates
	set_process(false)  # Stop normal updates
	nav_agent.set_velocity(Vector2.ZERO)  # Stop navigation movement

	anim.play("stun_" + last_direction)

	await stun_timer.timeout  

	if not dead:
		set_physics_process(true)  # Resume physics updates
		set_process(true)  # Resume normal updates
		nav_agent.target_position = player.global_position  # Force re-path
		chase_player()  # Ensure movement resumes

func _physics_process(delta):
	
	if not dead and not attacking and stun_timer and stun_timer.time_left == 0:
		nav_agent.target_position = player.global_position  # Recalculate path

	if dead or attacking or knockback_timer > 0:
		return

	if player and can_update_path:
		nav_agent.target_position = player.global_position  

	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	if global_position.distance_to(previous_position) < 1.0:
		stuck_timer += delta
		if stuck_timer > 0.5:
			velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 10  
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0  

	previous_position = global_position  

	if direction.length() > 0.1 and nav_agent.is_target_reachable():
		velocity = velocity.lerp(direction * speed, 0.1)
	else:
		velocity = Vector2.ZERO  

	move_and_slide()
	update_animation(direction)

func apply_mark(amp, duration):
	is_marked = true
	damage_amp = 1.0 + amp
	
	var mark = preload("res://Characters/mark_effect.tscn").instantiate()
	add_child(mark)
	
	await get_tree().create_timer(duration).timeout
	is_marked = false
	damage_amp = 1.0
	mark.queue_free()
