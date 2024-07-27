extends CharacterBody2D

#Zombie state
var chase_speed = randi_range(150, 250)
var starting_position: Vector2 = Vector2.ZERO

# Make Zombie movement more interesting, part 1
# Every CONFUSION_PERIOD we add an error to the direction of movement
var MAX_CONFUSION_ANGLE = PI/2.0 #(radians)
var SCATTER_SPEED = 1000
var confusion_angle = 0.0

# Make Zombie movement more interesting part 2
var is_scattering = false
var scatter_angle = 0.0
var scatter_speed = 0.0
var MAX_SCATTER_ANGLE = PI/6.0 #(radians)

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("front")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Handles collisions
func _physics_process(delta):
	#(move and collide results in zombies bumping each other into immobility!)
	var did_collide = move_and_slide()
	# Pass on scattering
	var damping_coefficient = (0.8*scatter_speed)/SCATTER_SPEED #(each scatter collision passes on less force)
	if did_collide and is_scattering and damping_coefficient > 0.25:
		for i in get_slide_collision_count():
			var collision_info = get_slide_collision(i)
			var collider = collision_info.get_collider()
			if collider.has_method("_on_collide_with_scattered_zombie"):
				collider._on_collide_with_scattered_zombie(
					collision_info.get_collider_velocity(), damping_coefficient
				)

func _on_player_player_detected(player_position: Vector2, delta):
	if (player_position.y < position.y):
		$AnimatedSprite2D.play("back")
	elif (player_position.x > position.x):
		$AnimatedSprite2D.play("right")
	elif (player_position.x < position.x):
		$AnimatedSprite2D.play("left")
	else:
		$AnimatedSprite2D.play("front")
		
	if is_scattering:
		# Scatter movement
		velocity = Vector2.from_angle(scatter_angle) * scatter_speed 
	else:
		# Normal movement
		var chase_velocity = player_position - position
		if chase_velocity.length() > 0:
			var angle_to_player = chase_velocity.angle()
			chase_velocity = Vector2.from_angle(angle_to_player + confusion_angle)
			velocity = chase_velocity.normalized() * chase_speed
		else:
			velocity = Vector2.ZERO

# Every few seconds, Zombie wakes up and takes another - inaccurate! - bead on the player
func _on_confusion_timer_timeout():
	confusion_angle = randf_range(-MAX_CONFUSION_ANGLE, MAX_CONFUSION_ANGLE)

func _on_collide_with_scattered_zombie(velo: Vector2, damping: float):
	_on_collide_with_other_character(velo, damping)

func _on_collide_with_dashing_player(velo: Vector2):
	_on_collide_with_other_character(velo, 1.0)

func _on_collide_with_other_character(velo: Vector2, damping: float):
	is_scattering = true
	scatter_speed = SCATTER_SPEED*damping
	scatter_angle = velo.angle() + randf_range(-MAX_SCATTER_ANGLE, MAX_SCATTER_ANGLE)
	$ScatterTimer.start()

func _on_collide_with_bullet():
	# TODO: for now just eliminate
	queue_free()

func _on_scatter_timer_timeout():
	is_scattering = false
