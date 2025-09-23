# GameManager.gd - Global game state manager
extends Node

# Game state tracking
var game_started = false
var game_time = 0.0
var is_paused = false

func _ready():
	# This is already added as autoload, no need to add to tree again
	print("GameManager initialized as autoload singleton")
	
	# Don't start game timer until play is pressed
	game_started = false

func start_game():
	"""Called when play button is pressed"""
	game_started = true
	game_time = 0.0
	print("Game started! Timer beginning...")

func _process(delta):
	"""Update game timer only when game has started"""
	if game_started and not is_paused:
		game_time += delta

func get_game_time() -> float:
	"""Get current game time"""
	return game_time

func pause_game():
	"""Pause the game timer"""
	is_paused = true

func unpause_game():
	"""Unpause the game timer"""
	is_paused = false