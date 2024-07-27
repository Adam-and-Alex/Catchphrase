extends CharacterBody2D

# Player state:
var NORMAL_SPEED = 400
var DASH_SPEED = 1200
var speed = NORMAL_SPEED
var dash_ability = true
var is_dashing = false

# Weapon
var Bullet = preload("res://bullet.tscn")

# Dashing state logic
func _on_dash_duration_timeout():
	speed = NORMAL_SPEED
	is_dashing = false
func _on_dash_cooldown_timeout():
	dash_ability = true

# Each frame, the player entity advertizes its location
# (nice thing is that mobs out of eyesight could ignore it)
signal player_detected(player_position)

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("down_walk")	

# Handles collisions
func _physics_process(delta):
	#(prefer move and collide to move and slide because player should have control over 
	# their movement)
	var collision_info = move_and_collide(velocity * delta)
	if collision_info and is_dashing:
		var collider = collision_info.get_collider()
		if collider.has_method("_on_collide_with_dashing_player"):
			collider._on_collide_with_dashing_player(collision_info.get_collider_velocity())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector2.ZERO #Player Movement Vector
	velocity.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	# Pick sprite based on dir of movement
	if velocity.y < 0:
		$AnimatedSprite2D.play("up_walk")
	if velocity.y > 0:
		$AnimatedSprite2D.play("down_walk")
		if velocity.x > 0:
			$AnimatedSprite2D.play("right_walk")
		if velocity.x < 0:
			$AnimatedSprite2D.play("left_walk")
		
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

		# Dash logic, only if moving
		if Input.is_action_pressed("dash"):
			if dash_ability == true:
				speed = DASH_SPEED
				is_dashing = true
				dash_ability = false
				$DashCooldown.start()
				$DashDuration.start()
	
	# Shooting logic:
	# (Can't shoot and dash at the same time)
	if not is_dashing:
		var shoot_direction = Vector2.ZERO
		shoot_direction.x = Input.get_action_strength("fire_right") - Input.get_action_strength("fire_left")
		shoot_direction.y = Input.get_action_strength("fire_down") - Input.get_action_strength("fire_up")
		
		if shoot_direction.length() > 0:
			fire_bullet(shoot_direction)
		elif Input.is_action_pressed("fire_kb_test"):
			fire_bullet(velocity)
			
	# I say where my position is every frame, move or not
	# (since Zombie movement depends on this)
	player_detected.emit(position, delta)


# TODO: position is wrong (fake "height" + needs to be outside of player sprite so doesn't immediately collide)
# TODO: manage rate of fire
func fire_bullet(dir):
	var b = Bullet.instantiate()
	if dir.length() > 0:
		b.start(position, dir.angle())
	else: 
		b.start(position, 0.0)
		
	get_tree().root.add_child(b)
	
