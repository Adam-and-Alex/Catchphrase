extends CharacterBody2D

# Player state:
var NORMAL_SPEED = 400
var DASH_SPEED = 1200
var speed = NORMAL_SPEED
var dash_ability = true
var is_dashing = false

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
			collider._on_collide_with_dashing_player(collision_info.get_collider_velocity(), 1.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = Vector2.ZERO #Player Movement Vector
	if Input.is_action_pressed("move_up"):
		velocity.y -= 5
		$AnimatedSprite2D.play("up_walk")
	if Input.is_action_pressed("move_down"):
		velocity.y += 5
		$AnimatedSprite2D.play("down_walk")
	if Input.is_action_pressed("move_right"):
		velocity.x += 5
		$AnimatedSprite2D.play("right_walk")
	if Input.is_action_pressed("move_left"):
		velocity.x -= 5
		$AnimatedSprite2D.play("left_walk")
	if Input.is_action_pressed("move_up") && Input.is_action_pressed("move_left"):
		$AnimatedSprite2D.play("up_walk")
	if Input.is_action_pressed("move_up") && Input.is_action_pressed("move_right"):
		$AnimatedSprite2D.play("up_walk")
		
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
	
	# I say where my position is every frame, move or not
	# (since Zombie movement depends on this)
	player_detected.emit(position, delta)

