extends CharacterBody2D

# Imports:
var Bullet = preload("res://bullet.tscn")
const Zombie = preload("res://zombie.gd")

# Player state:
var NORMAL_SPEED = 400
var DASH_SPEED = 1200
var speed = NORMAL_SPEED
var dash_ability = true
var is_dashing = false

# Weapon state
var MUZZLE_OFFSET = 32
var weapon_cooldown_time = 0.2 #(secs)
var current_weapon_cooldown = 0

#TODO: lots of fun buffs: dash effects, speed, armor, touch effects, 
#various healing (lifesteal, regen, medkits)

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
		if collider is Zombie:
			var colliding_zombie = collider as Zombie
			colliding_zombie._on_collide_with_dashing_player(collision_info.get_collider_velocity())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector2.ZERO #Player Movement Vector
	velocity.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		
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
	var shoot_direction = Vector2.ZERO
	if current_weapon_cooldown > 0:
		current_weapon_cooldown -= delta
		
	if not is_dashing:
		shoot_direction.x = Input.get_action_strength("fire_right") - Input.get_action_strength("fire_left")
		shoot_direction.y = Input.get_action_strength("fire_down") - Input.get_action_strength("fire_up")
		
		if current_weapon_cooldown <= 0:
			if shoot_direction.length() > 0:
				fire_bullet(shoot_direction)
			elif Input.is_action_pressed("fire_kb_test"):
				fire_bullet(velocity)			
		
	# What sprite to use?	
	# Pick sprite based on dir of movement
	# (if velocity.length == 0 then choose sprite based on shooting direction)
	if velocity.y < 0:
		$AnimatedSprite2D.play("up_walk")
	elif velocity.y > 0 or velocity.x != 0:
		$AnimatedSprite2D.play("down_walk")
		if velocity.x > 0:
			$AnimatedSprite2D.play("right_walk")
		if velocity.x < 0:
			$AnimatedSprite2D.play("left_walk")
	#(otherwise just leave the sprite as is, unless shooting)
	
	# If not moving then change sprite based on direction of fire
	if shoot_direction.y >= 0 and velocity.length() == 0:
		if shoot_direction.x > 0:
			$AnimatedSprite2D.play("right_walk")
		elif shoot_direction.x < 0:
			$AnimatedSprite2D.play("left_walk")
		else:
			$AnimatedSprite2D.play("down_walk")
			
	# I say where my position is every frame, move or not
	# (since Zombie movement depends on this)
	player_detected.emit(position, delta)


# TODO: manage rate of fire
func fire_bullet(dir: Vector2):
	current_weapon_cooldown = weapon_cooldown_time
	
	var b = Bullet.instantiate()
	#TODO: need to fire with the collision (center + (0,32)) at your feet
	# with a reduced MUZZLE_OFFSET*dir and then use layers so the bullet's visibility
	# is sensible 
	var bullet_position = position + MUZZLE_OFFSET*dir
	if dir.length() > 0:
		b.start(bullet_position, dir.angle())
	else: 
		b.start(bullet_position, 0.0)
		
	get_tree().root.add_child(b)
	
