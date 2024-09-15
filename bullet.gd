extends CharacterBody2D

# Imports:
const Zombie = preload("res://zombie.gd")
const Tombstone = preload("res://tombstone.gd")
const bullet_scene = preload("res://bullet.tscn")

var BULLET_SPEED = 1400
var BULLET_KNOCKBACK = 150

# Bullet damage
var default_bullet_damage = 10
var bullet_scale = 1
# (A bullet fragment created by hitting a tombstone does nothing to other tombstones)
var ignore_tombstones = false

#TODO: all sorts of fun params here and in player
# fire rate, max in flight, bounce %, split chars, knockback, (set on fire), makes scatter

func start(_position: Vector2, _direction: float, _scale : float):
	rotation = _direction
	position = _position
	velocity = Vector2(BULLET_SPEED, 0).rotated(rotation)
	bullet_scale = _scale
	$AnimatedSprite2D.scale = Vector2(bullet_scale, bullet_scale)
	$CollisionShape2D.scale = Vector2(bullet_scale, bullet_scale)
	self.rotate(_direction)


func _physics_process(delta):
	var collision_info = move_and_collide(velocity*delta)
	if collision_info:
		var collider = collision_info.get_collider()
		if collider is Zombie:
			var colliding_zombie = collider as Zombie
			colliding_zombie._on_collide_with_bullet(self)
		elif collider is Tombstone and not ignore_tombstones:
			var bullet_dir_offset = randf()*2.0*PI
			var colliding_tombstone = collider as Tombstone
			colliding_tombstone._on_collide_with_bullet(self)
			# In addition to causing damage, every time you hit a tombstone bullet fragments bounce off
			for i in range(2):
				var b = bullet_scene.instantiate()
				b.ignore_tombstones = true
				b.start(position, bullet_dir_offset + PI*i, bullet_scale)
				get_tree().root.add_child(b)
		
		queue_free() 
		

# TODO: really should be when it reaches the end of the player area not screen?
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
