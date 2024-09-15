extends CharacterBody2D

# Imports
const zombie_scene: PackedScene = preload("res://zombie.tscn")
const Player = preload("res://player.gd")
const Zombie = preload("res://zombie.gd")
const Game = preload("res://game.gd")
const Bullet = preload("res://bullet.gd")

# Tombstone misc state
var is_resurrecting = false
var is_destroyed = false
var tombstone_hp = 20

# Boon state
var has_boon = false
var chance_of_boon = 1.0 #0.25
var GAME_PATH = "/root/Game"
var game: Game

# How long it takes for a zombie to spawn
const max_resurrection_time = 3.0
const min_resurrection_time = 1.0
# Need this to be injected so we can wire up the player_detected signal
# when a zombie gets created
var player: Player

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
		game.receive_boon(pick_boon())

func _on_collide_with_zombie(damage: float):
	# If zombies are close to players and then connect with tombstones 
	# they enragedly destroy them!
	# No boon!
	if damage > 0:
		is_destroyed = true
		$AnimatedSprite2D.play("destroyed")
		$CollisionShape2D.disabled = true
		
# Shot with a bullet!
func _on_collide_with_bullet(bullet: Bullet):
	if not is_resurrecting and not is_destroyed:
		#TODO there will be a boon to allow resurrecting tombstones to be one shot
		#(but they will never drop boons)
		tombstone_hp = tombstone_hp - bullet.default_bullet_damage
		if tombstone_hp <= 0:
			is_destroyed = true
			var random_chance = randf()
			if random_chance < chance_of_boon:
				has_boon = true
				game = get_node(GAME_PATH) as Game
				$AnimatedSprite2D.play("boon")
				$CollisionShape2D.scale = Vector2(2, 1.2) #(x and y are reversed for some reason)
				$CollisionShape2D.position.y = $CollisionShape2D.position.y - 5
			else:
				$AnimatedSprite2D.play("destroyed")
				$CollisionShape2D.disabled = true


func _on_resurrection_timer_timeout():
	var zombie_instance: Zombie = zombie_scene.instantiate()
	zombie_instance.position = position
	if player:
		player.player_detected.connect(zombie_instance._on_player_player_detected)
	get_tree().root.add_child(zombie_instance)
	queue_free()
	
##### BOONS

const all_boons = {
	"Health": {
		# common keys:
		"key": "Health", #(include this twice so we can have eg "MinHealth", .. "MaxHealth" top level keys 
		"description": "Healing!", #(this goes in Last Boon text)
		"weight": 30, # 30 is Common
		# Boon specific
		"amount": 10,
	},
	"Bigger_Bullets":  {
		"key":  "Bigger_Bullets",
		"description": "Increased bullet size",
		"weight": 30, # Common
		"amount": 0.2,
	},
}	

func pick_boon() -> Dictionary:
	var total_weights = 0.0
	for boon in all_boons:
		total_weights += all_boons[boon].weight
		
	var rand_score = randf()
	
	var running_weights = 0.0
	for boon in all_boons:
		var this_boon = all_boons[boon]
		running_weights += this_boon.weight
		var threshold = running_weights/total_weights
		if rand_score <= threshold:
			return this_boon
		
	return all_boons["Health"]
