extends Node2D

@export var player_scene: PackedScene

func build_random_entity_position():
	var rng = RandomNumberGenerator.new()
	var screenSize = get_viewport().get_visible_rect().size
	var rndX = rng.randi_range(25, screenSize.x - 25)
	var rndY = rng.randi_range(25, screenSize.y - 25)	
	var starting_position = Vector2(rndX, rndY)
	return starting_position	

func _ready():
	$Player.position = build_random_entity_position()
	var zombie_scene = preload("res://zombie.tscn")
	for i in range(5):
		var zombie_instance = zombie_scene.instantiate()
		$Player.player_detected.connect(zombie_instance._on_player_player_detected)
		zombie_instance.position = build_random_entity_position()
		add_child(zombie_instance)
