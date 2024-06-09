extends Area2D
var speed = 400

# Each frame, the player entity advertizes its location
# (nice thing is that mobs out of eyesight could ignore it)
signal player_detected(player_position)

# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("down_walk")	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var velocity = Vector2.ZERO #Player Movement Vector
	if Input.is_action_pressed("move_up"):
		velocity.y -= 5
		$AnimatedSprite2D.play("up_walk")
	if Input.is_action_pressed("move_down"):
		velocity.y += 5
		$AnimatedSprite2D.play("down_walk")
	if Input.is_action_pressed("move_right"):
		velocity.x += 5
		$AnimatedSprite2D.play("right_walk")
	if Input.is_action_pressed("move_left"):
		velocity.x -= 5
		$AnimatedSprite2D.play("left_walk")
	if Input.is_action_pressed("move_up") && Input.is_action_pressed("move_left"):
		$AnimatedSprite2D.play("up_walk")
	if Input.is_action_pressed("move_up") && Input.is_action_pressed("move_right"):
		$AnimatedSprite2D.play("up_walk")
		
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		position += velocity * delta

	# I say where my position is every frame, move or not		
	player_detected.emit(position)
