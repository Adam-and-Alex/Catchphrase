extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimatedSprite2D.play("front")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#TODO: get velocity based on direcion of player
	#TODO: make sprite depend on direction of travel
	pass
