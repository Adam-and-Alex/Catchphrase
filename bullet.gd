extends CharacterBody2D

var BULLET_SPEED = 1400

func start(_position, _direction):
	rotation = _direction
	position = _position
	velocity = Vector2(BULLET_SPEED, 0).rotated(rotation)


func _physics_process(delta):
	# TODO: this doesn't really work because the bullet to be a mid "height" not "foot height"
	var collision_info = move_and_collide(velocity*delta)
	if collision_info:
		queue_free() #TODO: handle bullet player collisions (once position is correct shouldn't be an issue?)
		var collider = collision_info.get_collider()
		if collider.has_method("_on_collide_with_bullet"):
			collider._on_collide_with_bullet()
		

func _on_VisibilityNotifier2D_screen_exited():
	print("NOT SURE HOW TO WIRE THIS UP")
	queue_free()
