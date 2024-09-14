extends CharacterBody2D

const zombie_scene: PackedScene = preload("res://zombie.tscn")
const Player = preload("res://player.gd")
var player: Player

var is_resurrecting = false
const max_resurrection_time = 3.0
const min_resurrection_time = 1.0

func resurrect(_player: Player):
	player = _player
	# Causes zombie to "rise" from tombstone
	is_resurrecting = true
	
# Called when the node enters the scene tree for the first time.
func _ready():
	if is_resurrecting:
		$ResurrectionTimer.start(
			min_resurrection_time + (max_resurrection_time - min_resurrection_time)*randf()
		)
		$AnimatedSprite2D.play("resurrecting")
	else:
		$AnimatedSprite2D.play("dead")
		
	
func _physics_process(delta):
	pass


func _on_resurrection_timer_timeout():
	var zombie_instance = zombie_scene.instantiate()
	zombie_instance.position = position
	if player:
		player.player_detected.connect(zombie_instance._on_player_player_detected)
	get_tree().root.add_child(zombie_instance)
	queue_free()
	
