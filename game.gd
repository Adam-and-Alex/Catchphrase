extends Node2D


# Entities
const tombstone_scene: PackedScene = preload("res://tombstone.tscn")
const zombie_scene: PackedScene = preload("res://zombie.tscn")
const Zombie = preload("res://zombie.gd")
const Tombstone = preload("res://tombstone.gd")

# Constants
const NUM_ZOMBIES = 5
const SPAWN_FREQ_S = 5.0

# Game state
var game_started = false
var time_elapsed = 0.0
var time_since_last_spawn = 0.0
var game_round = 0
var game_area: Vector2

func build_random_entity_position():
	var rng = RandomNumberGenerator.new()
	var rndX = rng.randi_range(25, game_area.x - 25)
	var rndY = rng.randi_range(25, game_area.y - 25)	
	var starting_position = Vector2(rndX, rndY)
	return starting_position	

func add_zombie():
	var add_tombstone = true
	if add_tombstone:
		var tombstone_instance = tombstone_scene.instantiate()
		tombstone_instance.position = build_random_entity_position()
		tombstone_instance.resurrect($Player)
		add_child(tombstone_instance)
	else:
		var zombie_instance = zombie_scene.instantiate()
		$Player.player_detected.connect(zombie_instance._on_player_player_detected)
		zombie_instance.position = build_random_entity_position()
		add_child(zombie_instance)

func _ready():
	game_area = get_viewport().get_visible_rect().size
	$PlayerHealth.z_index = 1000
	$CanPlayerDash.z_index = 1000
	$TimeElapsed.z_index = 1000
	$Instructions.z_index = 1000
	
func start_game():	
	$Instructions.hide()
	
	# Reset state
	time_elapsed = 0.0
	time_since_last_spawn = 0.0
	game_round = 0	
	game_started = true
	
	$Player.position = build_random_entity_position()
	$Player.start_game(game_area)
	
	var children_to_delete = get_tree().get_nodes_in_group("clear_on_start")
	for child in children_to_delete:
		child.queue_free()
		
	add_child($Player)		
	for i in range(NUM_ZOMBIES):
		add_zombie()

func _process(delta):
	if not game_started:
		if Input.is_action_pressed("start_game"):
			start_game()
		
	if not $Player.is_dead:
		if game_started:
			time_elapsed += delta
			time_since_last_spawn += delta
			$PlayerHealth.text = "%d" % $Player.player_hp
		if $Player.dash_ability:			
			$CanPlayerDash.text = "RT: Dash!\nTeleport Disabled"
		else:
			$CanPlayerDash.text = "Dash Cooldown\nTeleport Disabled"
	else:
		$LastBoon.text = ""
		$PlayerHealth.text = "Dead"
		$CanPlayerDash.text = ""	
		game_started = false
		$Instructions.show()
		
	if game_started:
		$TimeElapsed.text = "%.1fs" % time_elapsed
		if time_since_last_spawn > SPAWN_FREQ_S and not $Player.is_dead:
			game_round = game_round + 1
			time_since_last_spawn = 0.0
			for i in range(game_round):
				add_zombie()

##### BOONS
	
func fallback_boon():	
	$LastBoon.text = "Fallback Boon: %s" % "Health :("
	$Player.boon_increase_health(10)

func receive_boon(boon_info: Dictionary): 	
	$LastBoon.text = "Last Boon: %s" % boon_info.description
	if boon_info.key == "Health":
		$Player.boon_increase_health(boon_info.amount)
		
	elif boon_info.key == "Bigger_Bullets":
		if not $Player.boon_increase_bullet_size(boon_info.amount):\
			fallback_boon()
		
