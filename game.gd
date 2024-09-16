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
const START_ROUND_FOR_BOON_DECAY = 15
const INIT_CHANCE_OF_BOON = 1.0
const BOON_DECAY_RATE = 0.95 #(applies after the first 15 rounds)
var chance_of_boon = INIT_CHANCE_OF_BOON

func build_random_entity_position():
	var rng = RandomNumberGenerator.new()
	@warning_ignore("narrowing_conversion")
	var rndX = rng.randi_range(25, game_area.x - 25)
	@warning_ignore("narrowing_conversion")
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
	$CanPlayerDash.z_index = 1000
	
func start_game():	
	$Instructions.hide()
	
	# Reset state
	time_elapsed = 0.0
	time_since_last_spawn = 0.0
	game_round = 0	
	game_started = true
	chance_of_boon = INIT_CHANCE_OF_BOON
	
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
			
			#TODO: some sort of exit criteria:
			# more than 120s, health goes up (>100) for 5 consecutive rounds
			
		var dash_ability_str = "Dash Cooldown"			
		if $Player.dash_ability:
			dash_ability_str = "RT: Dash!"
		var teleport_ability_str = "No teleports left"
		if $Player.num_teleports == 1:
			teleport_ability_str = "LT: 1 teleport left"
		elif $Player.num_teleports > 1:
			teleport_ability_str = "LT: %d teleports left" % $Player.num_teleports
			
		$CanPlayerDash.text = "%s\n%s" % [ dash_ability_str, teleport_ability_str ]
			
	else:
		$LastBoon.text = ""
		$PlayerHealth.text = "Dead"
		$CanPlayerDash.text = ""	
		game_started = false
		$Instructions.show()
		
	if game_started:
		$TimeElapsed.text = "%.1fs" % time_elapsed
		if time_since_last_spawn > SPAWN_FREQ_S and not $Player.is_dead:
			if game_round > START_ROUND_FOR_BOON_DECAY:
				chance_of_boon = chance_of_boon*BOON_DECAY_RATE
			game_round = game_round + 1
			time_since_last_spawn = 0.0
			for i in range(game_round):
				add_zombie()

##### BOONS
	
func fallback_boon():	
	$LastBoon.text = "Fallback Boon: %s" % "Health"
	if not $Player.boon_increase_health(5.0):
		$LastBoon.text = "Fallback Boon: %s" % "More Max Health"
		if not $Player.boon_increase_max_health(2.0):
			$LastBoon.text = "It was a dud :(" 

func receive_boon(boon_info: Dictionary): 	
	$LastBoon.text = "Last Boon: %s" % boon_info.description
	var recognized_boon = false
	if boon_info.key == "Health":
		recognized_boon = true
		if not $Player.boon_increase_health(boon_info.amount):
			fallback_boon()

	if boon_info.key == "Max_Health":
		recognized_boon = true
		if not $Player.boon_increase_max_health(boon_info.amount):
			fallback_boon()
		
	elif boon_info.key == "Bigger_Bullets":
		recognized_boon = true
		if not $Player.boon_increase_bullet_size(boon_info.amount):
			fallback_boon()

	elif boon_info.key == "Faster_Bullets":
		recognized_boon = true
		if not $Player.boon_faster_weapon(boon_info.amount):
			fallback_boon()
		
	elif boon_info.key == "More_Bullets":
		recognized_boon = true
		if not $Player.boon_more_bullets_per_shot():
			fallback_boon()
		
	elif boon_info.key == "Teleport":
		recognized_boon = true
		if not $Player.boon_another_teleport():
			fallback_boon()

	elif boon_info.key == "More_Speed":
		recognized_boon = true
		if not $Player.boon_more_speed(boon_info.amount):
			fallback_boon()
	
	elif boon_info.key == "More_Dashing":
		recognized_boon = true
		if not $Player.boon_more_dashing(boon_info.amount):
			fallback_boon()
	
	elif boon_info.key == "Zombie_Bounces":
		recognized_boon = true
		if not $Player.boon_zombie_bounces(boon_info.amount):
			fallback_boon()
		
	elif boon_info.key == "Tombstone_Bounces":
		recognized_boon = true
		if not $Player.boon_tombstone_bounces(boon_info.amount):
			fallback_boon()

	elif boon_info.key == "More_Boons":
		recognized_boon = true
		if not boon_increase_boons(boon_info.amount):
			fallback_boon()
	
	if not recognized_boon:
		print_debug("UNRECOGNIZED BOON %s" % boon_info.key)
	else:
		var children_to_delete = get_tree().get_nodes_in_group("boons")
		for child in children_to_delete:
			var tombstone_instance = tombstone_scene.instantiate()
			tombstone_instance.destroy(child)
			child.queue_free()
			add_child(tombstone_instance)

func boon_increase_boons(amount: float) -> bool:
	#TODO: increase the number of boons that persist after you collect one
	return false
