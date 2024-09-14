extends Node2D

var time_elapsed = 0.0

@export var player_scene: PackedScene

const tombstone_scene: PackedScene = preload("res://tombstone.tscn")
const zombie_scene: PackedScene = preload("res://zombie.tscn")
const NUM_ZOMBIES = 20
var time_since_last_spawn = 0.0
const SPAWN_FREQ_S = 5.0
var game_round = 0

func build_random_entity_position():
	var rng = RandomNumberGenerator.new()
	var screenSize = get_viewport().get_visible_rect().size
	var rndX = rng.randi_range(25, screenSize.x - 25)
	var rndY = rng.randi_range(25, screenSize.y - 25)	
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
	$Player.position = build_random_entity_position()
	for i in range(NUM_ZOMBIES):
		add_zombie()

func _process(delta):
	if not $Player.is_dead:
		time_elapsed += delta
		time_since_last_spawn += delta
		$PlayerHealth.text = "%d" % $Player.player_hp
		if $Player.dash_ability:			
			$CanPlayerDash.text = "Dash!"
		else:
			$CanPlayerDash.text = ""
	else:
		$PlayerHealth.text = "Dead"
		$CanPlayerDash.text = ""		
		
	$TimeElapsed.text = "%.1fs" % time_elapsed
	if time_since_last_spawn > SPAWN_FREQ_S and not $Player.is_dead:
		game_round = game_round + 1
		time_since_last_spawn = 0.0
		for i in range(game_round):
			add_zombie()
	
