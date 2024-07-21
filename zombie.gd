extends CharacterBody2D

var speed = randi_range(150, 250)
var starting_position: Vector2 = Vector2.ZERO
var zombie_velocity = Vector2.ZERO

# Every CONFUSION_PERIOD we add an error to the direction of movement
var CONFUSION_PERIOD = 5.0 #(seconds)
var last_confusion_time = CONFUSION_PERIOD
var MAX_CONFUSION_ANGLE = PI/2.0 #(radians)
var confusion_angle = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("front")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Handles collisions
func _physics_process(delta):
	move_and_collide(velocity * delta)

func _on_player_player_detected(player_position: Vector2, delta):
	if (player_position.y < position.y):
		$AnimatedSprite2D.play("back")
	elif (player_position.x > position.x):
		$AnimatedSprite2D.play("right")
	elif (player_position.x < position.x):
		$AnimatedSprite2D.play("left")
	else:
		$AnimatedSprite2D.play("front")
	
	last_confusion_time += delta
	if last_confusion_time > CONFUSION_PERIOD:
		last_confusion_time = 0.0
		confusion_angle = randf_range(-MAX_CONFUSION_ANGLE, MAX_CONFUSION_ANGLE)
	
	zombie_velocity = player_position - position
	if zombie_velocity.length() > 0:
		var angle_to_player = zombie_velocity.angle()
		zombie_velocity = Vector2.from_angle(angle_to_player + confusion_angle)
		zombie_velocity = zombie_velocity.normalized() * speed
		position += zombie_velocity * delta
