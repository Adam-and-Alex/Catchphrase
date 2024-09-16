extends CharacterBody2D

# Imports:
const Zombie = preload("res://zombie.gd")
const Player = preload("res://player.gd")
const Bullet = preload("res://bullet.gd")
const Tombstone = preload("res://tombstone.gd")
const tombstone_scene = preload("res://tombstone.tscn")
const bullet_scene = preload("res://bullet.tscn")

# Zombie state
var chase_speed = randi_range(150, 250)
var starting_position: Vector2 = Vector2.ZERO

# Make Zombie movement more interesting, part 1
# Every CONFUSION_PERIOD we add an error to the direction of movement
const MAX_CONFUSION_ANGLE = PI/2.0 #(radians)
const SCATTER_SPEED = 1000
var confusion_angle = 0.0

# Make Zombie movement more interesting part 2
var is_scattering = false
var scatter_angle = 0.0
var scatter_speed = 0.0
const MAX_SCATTER_ANGLE = PI/6.0 #(radians)

# Knockback
@export var knockback_resistance: float = 10
var knockback = Vector2.ZERO
# Hp and damage system
var MAX_HP = 30
var zombie_hp = MAX_HP
var zombie_damage_visibility = 0
var default_zombie_damage = 10

# Transient state
var player_position: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("clear_on_start")
	$AnimatedSprite2D.play("front")
	$AnimatedSprite2D.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$AnimatedSprite2D.z_index = min(max(position.y, 0), 999)
	
	if zombie_damage_visibility > 0:
		zombie_damage_visibility = maxf(zombie_damage_visibility - 0.01, 0)
		modulate = Color(1, 1 - zombie_damage_visibility, 1 - zombie_damage_visibility)

# Handles collisions
func _physics_process(_delta):		
	# Knockback			
	knockback = knockback.move_toward(Vector2.ZERO, knockback_resistance)
	velocity += knockback
	
	#(move and collide results in zombies bumping each other into immobility!)
	var did_collide = move_and_slide()
	# Pass on scattering
	var damping_coefficient = (0.8*scatter_speed)/SCATTER_SPEED #(each scatter collision passes on less force)
	if did_collide:
		for i in get_slide_collision_count():
			var collision_info = get_slide_collision(i)
			var collider = collision_info.get_collider()
			if collider is Zombie and is_scattering and damping_coefficient > 0.25:
				var colliding_zombie = collider as Zombie
				colliding_zombie._on_collide_with_scattered_zombie(
					collision_info.get_collider_velocity(), damping_coefficient
				)				
			if collider is Player:
				var colliding_player = collider as Player
				colliding_player._on_collide_with_zombie(default_zombie_damage)
			if collider is Tombstone:
				var colliding_tombstone = collider as Tombstone
				var damage = 0
				# If a zombie is close to a player then they can break tombstones 
				if player_position and player_position.distance_to(position) < 20:
					damage = default_zombie_damage
				colliding_tombstone._on_collide_with_zombie(damage)
				
func _on_player_player_detected(_player_position: Vector2, _delta):
	player_position = _player_position
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

# If a scatter zombie collides with me, I scatter slightly less frantically!
func _on_collide_with_scattered_zombie(velo: Vector2, damping: float):
	_on_collide_with_other_character(velo, damping)

# If a player dashes into me, I scatter!
func _on_collide_with_dashing_player(velo: Vector2):
	_on_collide_with_other_character(velo, 1.0)

# Common code for scattering
func _on_collide_with_other_character(velo: Vector2, damping: float):
	is_scattering = true
	scatter_speed = SCATTER_SPEED*damping
	scatter_angle = velo.angle() + randf_range(-MAX_SCATTER_ANGLE, MAX_SCATTER_ANGLE)
	$ScatterTimer.start()

# Shot with a bullet!
func _on_collide_with_bullet(bullet: Bullet):
	
	var bullet_velocity = bullet.velocity
	var knockback_strength = bullet.BULLET_KNOCKBACK
	var bullet_damage = bullet.default_bullet_damage

	# Very basic knockback
	knockback = knockback + bullet_velocity.normalized()*knockback_strength
	zombie_hp = zombie_hp - bullet_damage
	zombie_damage_visibility = 1.0

	#TODO pierce
	
	if zombie_hp <= 0:
		var tombstone_instance = tombstone_scene.instantiate()
		tombstone_instance.position = position
		get_tree().root.add_child(tombstone_instance)
		queue_free()

		# Bullet fragments on death
		var bouncing_bullets = bullet.mob_bounce
		if bouncing_bullets > 0:
			var bullet_dir_offset = randf()*2.0*PI
			for i in range(bouncing_bullets):
				var b = bullet_scene.instantiate()
				b.make_bounce(bullet, bullet_dir_offset + 2.0*PI*i/bouncing_bullets)
				get_tree().root.add_child(b)	

# Effect of being scatters finishes
func _on_scatter_timer_timeout():
	is_scattering = false
