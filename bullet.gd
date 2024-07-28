extends CharacterBody2D

# Imports:
const Zombie = preload("res://zombie.gd")

var BULLET_SPEED = 1400
var BULLET_KNOCKBACK = 150

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
			colliding_zombie._on_collide_with_bullet(velocity, BULLET_KNOCKBACK)
		queue_free() 
		

# TODO: really should be when it reaches the end of the player area not screen?
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
