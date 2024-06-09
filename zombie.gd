extends RigidBody2D

var starting_position: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("front")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_player_player_detected(player_position: Vector2):
	if (player_position.y < position.y):
		$AnimatedSprite2D.play("back")
	elif (player_position.x > position.x):
		$AnimatedSprite2D.play("right")
	elif (player_position.x < position.x):
		$AnimatedSprite2D.play("left")
	else:
		$AnimatedSprite2D.play("front")
