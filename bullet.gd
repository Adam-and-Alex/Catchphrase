extends CharacterBody2D

# Imports:
const Bullet = preload("res://bullet.gd")
const Zombie = preload("res://zombie.gd")
const Tombstone = preload("res://tombstone.gd")
const bullet_scene = preload("res://bullet.tscn")

var BULLET_SPEED = 1400
var BULLET_KNOCKBACK = 150

# Bullet damage
var default_bullet_damage = 10

# Bullet size
var bullet_scale = 1
# (A bullet fragment created by hitting a tombstone does nothing to other tombstones)
var ignore_tombstones = false

# Bounce and pierce
var mob_bounce = 0.0 #(on mob die, spawns extra bullets)
var tombstone_bounce = 0.0 #(every tombstone hit, spawns extra bullets)
var mob_pierce = 0.0

#TODO: all sorts of fun params here and in player
# fire rate, max in flight, bounce %, split chars, knockback, (set on fire), makes scatter

func start(_position: Vector2, _direction: float, _scale: float, _pierce, _mob_bounce, _tombstone_bounce):
	rotation = _direction
	position = _position
	velocity = Vector2(BULLET_SPEED, 0).rotated(rotation)
	bullet_scale = _scale
	$AnimatedSprite2D.scale = Vector2(bullet_scale, bullet_scale)
	# The shape of the mask should be skewed when shooting horizontal
	# and normal when shooting vertical
	var verticality = abs(cos(_direction))
	var x_scale = 0.7*verticality + 1.0*(1 - verticality)
	var y_scale = 1.4*verticality + 1.0*(1 - verticality)
	$CollisionShape2D.scale.x = bullet_scale*x_scale #(these should sync with the init scales)
	$CollisionShape2D.scale.y = bullet_scale*y_scale
	self.rotate(_direction)
	mob_bounce = _mob_bounce
	tombstone_bounce = _tombstone_bounce
	mob_pierce = _pierce
	

func make_bounce(orig: Bullet, direction_offset: float, is_tombstone_bounce: bool = false):
	var angle = orig.rotation
	if is_tombstone_bounce:
		angle = 2.0*PI - angle
	start(orig.position, angle + direction_offset, orig.bullet_scale, orig.mob_pierce - 1, orig.mob_bounce - 1, orig.tombstone_bounce - 1)
	# This is just a hack to stop a bullet colliding with its first tombstone a gazillion times
	ignore_tombstones = is_tombstone_bounce
	

func pierce(b: Bullet):
	# TODO needs to "teleport to other side of mob"
	start(b.position, b.direction, b.bullet_scale, mob_pierce - 1, mob_bounce - 1, tombstone_bounce - 1)

func _physics_process(delta):
	var collision_info = move_and_collide(velocity*delta)
	if collision_info:
		var collider = collision_info.get_collider()
		if collider is Zombie:
			var colliding_zombie = collider as Zombie
			colliding_zombie._on_collide_with_bullet(self)
		elif collider is Tombstone and not ignore_tombstones:
			var bullet_dir_offset = randf()*0.5*PI #(small offset)
			var colliding_tombstone = collider as Tombstone
			colliding_tombstone._on_collide_with_bullet(self)
			# In addition to causing damage, every time you hit a tombstone bullet fragments bounce off
			for i in range(tombstone_bounce):
				var b = bullet_scene.instantiate()
				b.make_bounce(self, bullet_dir_offset + PI*i/tombstone_bounce, true)
				get_tree().root.add_child(b)
		
		queue_free() 
		

# TODO: really should be when it reaches the end of the player area not screen?
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
