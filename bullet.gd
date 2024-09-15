extends CharacterBody2D

# Imports:
const Zombie = preload("res://zombie.gd")
const Tombstone = preload("res://tombstone.gd")
const bullet_scene = preload("res://bullet.tscn")

var BULLET_SPEED = 1400
var BULLET_KNOCKBACK = 150

var default_bullet_damage = 10

var ignore_tombstones = false

#TODO: all sorts of fun params here and in player
# fire rate, max in flight, bounce %, split chars, knockback, (set on fire), makes scatter

func start(_position: Vector2, _direction: float):
	rotation = _direction
	position = _position
	velocity = Vector2(BULLET_SPEED, 0).rotated(rotation)
	self.rotate(_direction)


func _physics_process(delta):
	var collision_info = move_and_collide(velocity*delta)
	if collision_info:
		var collider = collision_info.get_collider()
		if collider is Zombie:
			var colliding_zombie = collider as Zombie
			colliding_zombie._on_collide_with_bullet(velocity, BULLET_KNOCKBACK, default_bullet_damage)
		elif collider is Tombstone and not ignore_tombstones:
			var bullet_dir_offset = randf()*2.0*PI
			var colliding_tombstone = collider as Tombstone
			colliding_tombstone._on_collide_with_bullet(default_bullet_damage)
			# In addition to causing damage, every time you hit a tombstone bullet fragments bounce off
			for i in range(2):
				var b = bullet_scene.instantiate()
				b.ignore_tombstones = true
				b.start(position, bullet_dir_offset + PI*i)
				get_tree().root.add_child(b)
		
		queue_free() 
		

# TODO: really should be when it reaches the end of the player area not screen?
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
