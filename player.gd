extends CharacterBody2D

# Imports:
var bullet_scene = preload("res://bullet.tscn")
const Zombie = preload("res://zombie.gd")
const Tombstone = preload("res://tombstone.gd")

# Player movement state:
const NORMAL_SPEED = 400
const DASH_SPEED = 1200
var speed = NORMAL_SPEED
var dash_ability = true
var is_dashing = false

# Weapon state
const MUZZLE_OFFSET = 32
const MIN_WEAPON_COOLDOWN = 0.1
const INIT_WEAPON_COOLDOWN = 0.2
var weapon_cooldown_time = INIT_WEAPON_COOLDOWN #(secs)
var current_weapon_cooldown = 0 #(tracks where we are between 0 and weapon_cooldown_time)
const MAX_BULLET_SCALE = 3
var bullet_scale = 1
const MAX_MOB_BOUNCE = 6
const MAX_TOMBSTONE_BOUNCE = 4
var mob_bounce = 0
var tombstone_bounce = 1
var mob_pierce = 0 #TODO need to make this work

# Health state
const MAX_MAX_HP = 400
const MAX_HP = 100
var max_player_hp = MAX_HP
var player_hp = MAX_HP
var is_dead = false
var player_damage_visibility = 0

# Size of area
const MAX_TELEPORTS = 5
var player_area: Vector2
var num_teleports = 1
var teleport_ability = false #(use dash cooldown)

# Temp collision state
var num_collisions = 0

#TODO: lots of fun buffs: dash effects, speed, armor, touch effects, 
#various healing (lifesteal, regen, medkits)

# Dashing state logic
func _on_dash_duration_timeout():
	speed = NORMAL_SPEED
	is_dashing = false
func _on_dash_cooldown_timeout():
	dash_ability = true
	teleport_ability = true

# Each frame, the player entity advertizes its location
# (nice thing is that mobs out of eyesight could ignore it)
signal player_detected(player_position)

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("down_walk")	

func start_game(game_area: Vector2):
	player_area = game_area
	player_damage_visibility = 0
	modulate = Color(1, 1, 1)
	player_hp = MAX_HP
	bullet_scale = 1
	$AnimatedSprite2D.play("down_walk")	
	dash_ability = true
	is_dashing = false
	is_dead = false
	num_teleports = 1
	teleport_ability = true
	weapon_cooldown_time = INIT_WEAPON_COOLDOWN
	mob_bounce = 0
	tombstone_bounce = 1
	mob_pierce = 0

# Handles collisions
func _physics_process(delta):
	if is_dead:
		return
	
	#(prefer move and collide to move and slide because player should have control over 
	# their movement)
	num_collisions = 0
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		num_collisions = 1
		var collider = collision_info.get_collider()
		if is_dashing:
			if collider is Zombie:
				var colliding_zombie = collider as Zombie
				colliding_zombie._on_collide_with_dashing_player(collision_info.get_collider_velocity())	
		if collider is Tombstone:
			var colliding_tombstone = collider as Tombstone
			colliding_tombstone._on_collide_with_player()	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_dead:
		return
		
	# (Don't allow the player out of bounds)
	if player_area and player_area.x > 0 and player_area.y > 0 and \
		(position.y < 0 or position.y > player_area.y or \
		position.x < 0 or position.x > player_area.x):
		player_hp -= 20

	# Set layering		
	$AnimatedSprite2D.z_index = position.y
	
	if Input.is_action_pressed("teleport") and num_teleports > 0 and teleport_ability:
		teleport_ability = false
		$DashCooldown.start()
		teleport()
	
	
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
			#TODO: have some key make you shoot in the direction of travel
			#elif Input.is_action_pressed("TODO"):
			#	fire_bullet(velocity)			
		
	# What sprite to use?	
	# Pick sprite based on dir of movement
	# (if velocity.length == 0 then choose sprite based on shooting direction)
	if velocity.y < 0:
		$AnimatedSprite2D.play("up_walk")
	elif velocity.y > 0 or velocity.x != 0:
		if velocity.x == 0:
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
			$AnimatedSprite2D.stop()
		elif shoot_direction.x < 0:
			$AnimatedSprite2D.play("left_walk")
			$AnimatedSprite2D.stop()
		else:
			$AnimatedSprite2D.play("down_walk")
			$AnimatedSprite2D.stop()
			
	# I say where my position is every frame, move or not
	# (since Zombie movement depends on this)
	player_detected.emit(position, delta)
	
	if player_hp <= 0:
		is_dead = true
		$AnimatedSprite2D.play("dead")
	
	if player_damage_visibility > 0:
		player_damage_visibility = maxf(player_damage_visibility - 0.01, 0)
		modulate = Color(1, 1 - player_damage_visibility, 1 - player_damage_visibility)

# TODO: manage rate of fire
func fire_bullet(dir: Vector2):
	current_weapon_cooldown = weapon_cooldown_time
	
	var b = bullet_scene.instantiate()
	#TODO: need to fire with the collision (center + (0,32)) at your feet
	# with a reduced MUZZLE_OFFSET*dir and then use layers so the bullet's visibility
	# is sensible 
	var muzzle_offset = MUZZLE_OFFSET
	if num_collisions > 0: #(we only know 0 or 1 for num collisions)
		muzzle_offset = 0 
		#(if enough collisions then just fire from base since you can't see
		# where they come from anyway and you can't get dead zones)
		
	var bullet_position = position + muzzle_offset*dir
	if dir.length() > 0:
		b.start(bullet_position, dir.angle(), bullet_scale, mob_pierce, mob_bounce, tombstone_bounce)
	else: 
		b.start(bullet_position, 0.0, bullet_scale, mob_pierce, mob_bounce, tombstone_bounce)
		
	get_tree().root.add_child(b)

func teleport():
	num_teleports = num_teleports - 1
	var new_position = Vector2(position)
	while new_position.distance_to(position) < 100:
		var rng = RandomNumberGenerator.new()
		@warning_ignore("narrowing_conversion")
		var rndX = rng.randi_range(25, player_area.x - 25)
		@warning_ignore("narrowing_conversion")
		var rndY = rng.randi_range(25, player_area.y - 25)
		new_position = Vector2(rndX, rndY)
		
	position.x = new_position.x
	position.y = new_position.y

func _on_collide_with_zombie(zombie_damage):
	if is_dead:
		player_damage_visibility = 1.0
		return
	if player_damage_visibility == 0 && is_dashing == false:
		player_damage_visibility = 1.0
		player_hp = player_hp - zombie_damage

##### BOONS

func boon_increase_health(health_bonus: int):
	if player_hp < max_player_hp:
		player_hp += health_bonus
		return true
	else:
		return false

func boon_increase_max_health(max_health_bonus: int):
	if max_player_hp < MAX_MAX_HP:
		max_player_hp += max_health_bonus
		return true
	else:
		return false
	
func boon_increase_bullet_size(size_increase: float) -> bool:
	if bullet_scale < MAX_BULLET_SCALE:
		bullet_scale += size_increase
		return true
	else:
		return false

func boon_another_teleport() -> bool:
	if num_teleports < MAX_TELEPORTS:
		num_teleports = num_teleports + 1
		return true
	else:
		return false 
		
func boon_faster_weapon(amount: float) -> bool:		
	if weapon_cooldown_time > MIN_WEAPON_COOLDOWN:
		weapon_cooldown_time = weapon_cooldown_time - amount
		return true
	else:
		return false

func boon_zombie_bounces(amount: int) -> bool:
	if mob_bounce < MAX_MOB_BOUNCE: 
		mob_bounce += amount
		return true
	else:
		return false

func boon_tombstone_bounces(amount: int) -> bool:
	if tombstone_bounce < MAX_TOMBSTONE_BOUNCE: 
		tombstone_bounce += amount
		return true
	else:
		return false
