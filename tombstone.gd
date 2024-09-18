extends CharacterBody2D

# Imports
const zombie_scene: PackedScene = preload("res://zombie.tscn")
const Player = preload("res://player.gd")
const Zombie = preload("res://zombie.gd")
const Game = preload("res://game.gd")
const Tombstone = preload("res://tombstone.gd")
const Bullet = preload("res://bullet.gd")

# Tombstone misc state
var is_resurrecting = false
var is_destroyed = false
var tombstone_hp = 20

# Boon state
var has_boon = false
var GAME_PATH = "/root/Game"
var game: Game
var boon_info: Dictionary

# How long it takes for a zombie to spawn
const max_resurrection_time = 3.0
const min_resurrection_time = 1.0
# Need this to be injected so we can wire up the player_detected signal
# when a zombie gets created
var player: Player

func destroy(from: Node):
	position = from.position
	is_destroyed = true
	$AnimatedSprite2D.play("destroyed")
	$CollisionShape2D.disabled = true

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
	elif is_destroyed:
		$AnimatedSprite2D.play("destroyed")
	else:
		$AnimatedSprite2D.play("dead")
		
	
func _physics_process(_delta):
	pass

func _process(_delta):
	$AnimatedSprite2D.z_index = position.y

func _on_collide_with_player():
	if has_boon:
		has_boon = false
		remove_from_group("boons")
		$AnimatedSprite2D.play("destroyed")
		$CollisionShape2D.disabled = true
		game.receive_boon(boon_info)

func _on_collide_with_zombie(damage: float):
	# If zombies are close to players and then connect with tombstones 
	# they enragedly destroy them!
	# No boon!
	if damage > 0:
		is_destroyed = true
		$AnimatedSprite2D.play("destroyed")
		$CollisionShape2D.disabled = true
		
	# In fact, zombie takes the boon!
	if has_boon:
		remove_from_group("boons")
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
			game = get_node(GAME_PATH) as Game
			if random_chance < game.chance_of_boon:
				has_boon = true
				add_to_group("boons")
				#TODO
				boon_info = pick_boon()
				$AnimatedSprite2D.play("boon_%s" % boon_info["category"])
				$CollisionShape2D.scale = Vector2(2, 1.2) #(x and y are reversed for some reason)
				# TODO: I don't think I need this any more
				#$CollisionShape2D.position.y = $CollisionShape2D.position.y - 5
				# After this, bullets will go through boons
				self.set_collision_layer_value(2, false)
				self.set_collision_layer_value(4, true)
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
		"weight": 50, # 30 is Common
		"category": "health", #health, movement, weapon, environment
		# Boon specific
		"amount": 10,
	},
	"Max_Health": {
		# common keys:
		"key": "Max_Health", 
		"description": "Higher max health", 
		"weight": 20, # rare
		"category": "health",
		# Boon specific
		"amount": 5,
	},
	"Bigger_Bullets":  {
		"key":  "Bigger_Bullets",
		"description": "Increased bullet size",
		"weight": 20, # Common
		"category": "weapon",
		"amount": 0.2,
	},
	"Faster_Bullets":  {
		"key":  "Faster_Bullets",
		"description": "Increased bullet speed",
		"weight": 20, # Rarer
		"category": "weapon",
		"amount": 0.02,
	},
	"More_Bullets":  {
		"key":  "More_Bullets",
		"description": "More bullets per shot",
		"weight": 10, # rare
		"category": "weapon"
	},
	"Teleport":  {
		"key":  "Teleport",
		"description": "Have another teleport",
		"weight": 15, # Rare-ish
		"category": "movement",
	},
	"More_Speed":  {
		"key":  "More_Speed",
		"description": "Go faster",
		"weight": 15, # Rare-ish
		"category": "movement",
		"amount": 50,
	},
	"More_Dashing":  {
		"key":  "More_Dashing",
		"description": "More dashes",
		"weight": 15, # Rare-ish
		"category": "movement",
		"amount": 0.2,
	},
	"Zombie_Bounces": {
		"key": "Zombie_Bounces",
		"description": "Increased bounces off of zombies",
		"weight": 15, #prety rare
		"category": "environment",
		"amount": 1,
	},
	"Tombstone_Bounces": {
		"key": "Tombstone_Bounces",
		"description": "Increased bounces off tombstones",
		"weight": 20,
		"category": "environment",
		"amount": 1,
	},
	"More_Boons": {
		"key": "More_Boons",
		"description": "More boons!",
		"weight": 10, #rare
		"category": "environment",
	}
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
