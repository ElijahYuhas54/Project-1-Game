# TitleScreen.gd - Main menu and settings screen with proper scaling
extends Control

@onready var main_menu: VBoxContainer
@onready var settings_menu: Control
@onready var play_button: Button
@onready var settings_button: Button
@onready var quit_button: Button
@onready var back_button: Button

# Resolution buttons
@onready var resolution1: Button
@onready var resolution2: Button
@onready var resolution3: Button
@onready var resolution4: Button
@onready var resolution5: Button
@onready var fullscreen_button: Button

# Resolution presets
var resolutions = {
	"1920x1080": Vector2i(1920, 1080),
	"1366x768": Vector2i(1366, 768),
	"1280x720": Vector2i(1280, 720),
	"1152x648": Vector2i(1152, 648),
	"1024x576": Vector2i(1024, 576)
}

func _ready():
	print("=== LIGHTBEARER: RISE OF THE EMBER - TITLE SCREEN ===")
	print("Game timer will not start until Play Game is pressed")
	
	# Ensure GameManager exists and game is not started yet
	if GameManager:
		GameManager.game_started = false
	
	# Get node references
	main_menu = get_node("MainMenu")
	settings_menu = get_node("SettingsMenu")
	play_button = get_node("MainMenu/PlayButton")
	settings_button = get_node("MainMenu/SettingsButton")
	quit_button = get_node("MainMenu/QuitButton")
	back_button = get_node("SettingsMenu/SettingsPanel/BackButton")
	
	# Resolution buttons
	resolution1 = get_node("SettingsMenu/SettingsPanel/ResolutionOptions/Resolution1")
	resolution2 = get_node("SettingsMenu/SettingsPanel/ResolutionOptions/Resolution2")
	resolution3 = get_node("SettingsMenu/SettingsPanel/ResolutionOptions/Resolution3")
	resolution4 = get_node("SettingsMenu/SettingsPanel/ResolutionOptions/Resolution4")
	resolution5 = get_node("SettingsMenu/SettingsPanel/ResolutionOptions/Resolution5")
	fullscreen_button = get_node("SettingsMenu/SettingsPanel/ResolutionOptions/FullscreenButton")
	
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect resolution buttons
	resolution1.pressed.connect(_on_resolution_pressed.bind("1920x1080"))
	resolution2.pressed.connect(_on_resolution_pressed.bind("1366x768"))
	resolution3.pressed.connect(_on_resolution_pressed.bind("1280x720"))
	resolution4.pressed.connect(_on_resolution_pressed.bind("1152x648"))
	resolution5.pressed.connect(_on_resolution_pressed.bind("1024x576"))
	fullscreen_button.pressed.connect(_on_fullscreen_pressed)
	
	# Connect to resolution manager signals
	if ResolutionManager:
		ResolutionManager.resolution_changed.connect(_on_resolution_changed)
		# Apply current scaling immediately
		ResolutionManager.apply_scaling_to_node(self)
	
	# Start with main menu visible
	show_main_menu()

func _on_resolution_changed(new_resolution: Vector2i, scale_factor: float):
	"""Handle resolution change from ResolutionManager"""
	print("Title screen applying scale factor: ", scale_factor)
	scale = Vector2(scale_factor, scale_factor)

func _on_play_pressed():
	"""Start the game - this is when the game timer begins"""
	print("Starting game...")
	print("Game timer will now begin!")
	
	# The GameManager will be notified when LightbearerScene loads
	get_tree().change_scene_to_file("res://LightbearerScene.tscn")

func _on_settings_pressed():
	"""Show settings menu"""
	show_settings_menu()

func _on_quit_pressed():
	"""Quit the game - closes the entire application"""
	print("Quitting game...")
	print("Thank you for playing Lightbearer: Rise of the Ember!")
	get_tree().quit()

func _on_back_pressed():
	"""Return to main menu"""
	show_main_menu()

func _on_resolution_pressed(resolution_key: String):
	"""Change window resolution using ResolutionManager"""
	var new_size = resolutions[resolution_key]
	print("Changing resolution to: ", resolution_key)
	
	if ResolutionManager:
		ResolutionManager.set_resolution(new_size, false)

func _on_fullscreen_pressed():
	"""Toggle fullscreen mode using ResolutionManager"""
	print("Switching to fullscreen...")
	
	if ResolutionManager:
		var screen_size = DisplayServer.screen_get_size()
		ResolutionManager.set_resolution(Vector2i(screen_size.x, screen_size.y), true)

func show_main_menu():
	"""Show the main menu"""
	main_menu.visible = true
	settings_menu.visible = false

func show_settings_menu():
	"""Show the settings menu"""
	main_menu.visible = false
	settings_menu.visible = true

func _input(event):
	"""Handle input events"""
	# Allow ESC to go back in settings
	if event.is_action_pressed("ui_cancel") and settings_menu.visible:
		show_main_menu()