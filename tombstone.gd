extends CharacterBody2D

const zombie_scene: PackedScene = preload("res://zombie.tscn")
const Player = preload("res://player.gd")
var player: Player

# Tombstone state
var is_resurrecting = false
var has_boon = false
var is_destroyed = false
var tombstone_hp = 20
var chance_of_boon = 0.25

# Resurrection control
const max_resurrection_time = 3.0
const min_resurrection_time = 1.0

func resurrect(_player: Player):
	player = _player
	# Causes zombie to "rise" from tombstone
	is_resurrecting = true
	
# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("clear_on_start")
	if is_resurrecting:
		$ResurrectionTimer.start(
			min_resurrection_time + (max_resurrection_time - min_resurrection_time)*randf()
		)
		$AnimatedSprite2D.play("resurrecting")
	else:
		$AnimatedSprite2D.play("dead")
		
	
func _physics_process(delta):
	pass

func _process(delta):
	$AnimatedSprite2D.z_index = position.y

func _on_collide_with_player():
	if has_boon:
		has_boon = false
		$AnimatedSprite2D.play("destroyed")
		$CollisionShape2D.disabled = true

func _on_collide_with_zombie():
	# Experimented with zombies causing damage but destroyed them too quickly
	# Maybe need an decent invulnerability timer
	pass
		
# Shot with a bullet!
func _on_collide_with_bullet(bullet_damage: float):
	if not is_resurrecting and not is_destroyed:
		#TODO there will be a boon to allow resurrecting tombstones to be one shot
		#(but they will never drop boons)
		tombstone_hp = tombstone_hp - bullet_damage
		if tombstone_hp <= 0:
			is_destroyed = true
			var random_chance = randf()
			if random_chance < chance_of_boon:
				has_boon = true
				$AnimatedSprite2D.play("boon")
			else:
				$AnimatedSprite2D.play("destroyed")
				$CollisionShape2D.disabled = true


func _on_resurrection_timer_timeout():
	var zombie_instance = zombie_scene.instantiate()
	zombie_instance.position = position
	if player:
		player.player_detected.connect(zombie_instance._on_player_player_detected)
	get_tree().root.add_child(zombie_instance)
	queue_free()
	
