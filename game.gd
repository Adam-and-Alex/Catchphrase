extends Node2D

var time_elapsed = 0.0

@export var player_scene: PackedScene

var zombie_scene: PackedScene
var NUM_ZOMBIES = 20
var time_since_last_spawn = 0.0
var round = 0

func build_random_entity_position():
	var rng = RandomNumberGenerator.new()
	var screenSize = get_viewport().get_visible_rect().size
	var rndX = rng.randi_range(25, screenSize.x - 25)
	var rndY = rng.randi_range(25, screenSize.y - 25)	
	var starting_position = Vector2(rndX, rndY)
	return starting_position	

func add_zombie():
	var zombie_instance = zombie_scene.instantiate()
	$Player.player_detected.connect(zombie_instance._on_player_player_detected)
	zombie_instance.position = build_random_entity_position()
	add_child(zombie_instance)

func _ready():
	$Player.position = build_random_entity_position()
	zombie_scene = preload("res://zombie.tscn")
	for i in range(NUM_ZOMBIES):
		add_zombie()

func _process(delta):
	if $Player:
		time_elapsed += delta
		time_since_last_spawn += delta
		$PlayerHealth.text = "%d" % $Player.player_hp
	else:
		$PlayerHealth.text = "Dead"
		
	$TimeElapsed.text = "%.1fs" % time_elapsed
	if time_since_last_spawn > 5.0:
		round = round + 1
		time_since_last_spawn = 0.0
		for i in range(round):
			add_zombie()
	
