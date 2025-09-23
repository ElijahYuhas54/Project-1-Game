# LightbearerScene.gd - Extended journey-based game scene with enhanced UI and scaling
extends Node2D

var villagers_cleansed = 0
var total_villagers = 3
var shadows_defeated = 0
var total_shadows = 0
var barriers_removed = false

@onready var kael: CharacterBody2D
@onready var energy_bar: ProgressBar
@onready var energy_counter: Label
@onready var villager_counter: Label
@onready var progress_counter: Label
@onready var villagers_node: Node2D
@onready var ground_rect: ColorRect
@onready var ui_scene: CanvasLayer
@onready var enemies_node: Node2D
@onready var global_message: PanelContainer
@onready var message_label: Label
@onready var villager_message: PanelContainer
@onready var villager_message_label: Label

# Preload scenes
const ShadowMonarchScene = preload("res://ShadowMonarch.tscn")
const ShadowScene = preload("res://Shadow.tscn")
const EnergyPickupScene = preload("res://EnergyPickup.tscn")

func _ready():
	# Signal that the game has started
	if GameManager:
		GameManager.start_game()
	
	print("=== LIGHTBEARER: RISE OF THE EMBER ===")
	print("Kael discovers the ancient ember in the village ruins!")
	print("The villagers are trapped in shadow at the far end of this cursed land...")
	print("Fight through the shadows to reach the village and save them!")
	print("Use Light Pulse (Z) to defeat enemies and collect energy pickups!")
	
	# Get references to nodes
	kael = get_node("GameWorld/Characters/Kael")
	ui_scene = get_node("UI")
	energy_bar = get_node("UI/EnergyPanel/EnergyVBox/EnergyBar")
	energy_counter = get_node("UI/EnergyPanel/EnergyVBox/EnergyCounter")
	villager_counter = get_node("UI/ProgressPanel/ProgressVBox/VillagerCounter")
	progress_counter = get_node("UI/ProgressPanel/ProgressVBox/ProgressCounter")
	global_message = get_node("UI/GlobalMessage")
	message_label = get_node("UI/GlobalMessage/MessageLabel")
	villager_message = get_node("UI/VillagerMessage")
	villager_message_label = get_node("UI/VillagerMessage/VillagerMessageLabel")
	villagers_node = get_node("GameWorld/Villagers")
	enemies_node = get_node("GameWorld/Enemies")
	ground_rect = get_node("GameWorld/Ground/GroundRect")
	
	# Connect Kaels energy signal
	if kael:
		kael.energy_changed.connect(_on_kael_energy_changed)
	
	# Connect to resolution manager for scaling
	if ResolutionManager:
		ResolutionManager.resolution_changed.connect(_on_resolution_changed)
		# Apply current scaling immediately
		ResolutionManager.apply_scaling_to_node(self)
	
	# Initialize villager names
	setup_villagers()
	
	# Count existing enemies
	total_shadows = enemies_node.get_child_count()
	print("Total shadows to defeat: ", total_shadows)
	
	# Update initial UI
	update_ui()
	
	# Add scene to group for villagers to find
	add_to_group("lightbearer_scene")

func _on_resolution_changed(new_resolution: Vector2i, scale_factor: float):
	"""Handle resolution change from ResolutionManager"""
	print("Game scene applying scale factor: ", scale_factor)
	scale = Vector2(scale_factor, scale_factor)

func show_temporary_message(message: String, duration: float = 3.0):
	"""Show a temporary message to the player"""
	message_label.text = message
	
	var tween = create_tween()
	tween.tween_property(global_message, "modulate:a", 1.0, 0.3)
	tween.tween_property(global_message, "modulate:a", 1.0, duration - 0.6)
	tween.tween_property(global_message, "modulate:a", 0.0, 0.3)

func show_villager_message(message: String, duration: float = 4.0):
	"""Show a villager message when cleansed"""
	villager_message_label.text = message
	
	var tween = create_tween()
	tween.tween_property(villager_message, "modulate:a", 1.0, 0.3)
	tween.tween_property(villager_message, "modulate:a", 1.0, duration - 0.6)
	tween.tween_property(villager_message, "modulate:a", 0.0, 0.3)

func setup_villagers():
	"""Setup individual villager names and properties"""
	var villager_names = ["Elder Tom", "Sarah", "Marcus"]
	
	for i in range(villagers_node.get_child_count()):
		var villager = villagers_node.get_child(i)
		if villager.has_method("set_villager_name") and i < villager_names.size():
			villager.set_villager_name(villager_names[i])

func on_villager_cleansed(villager_name: String):
	"""Called when a villager is cleansed of shadows"""
	villagers_cleansed += 1
	
	# Only output remaining villagers count
	var remaining = total_villagers - villagers_cleansed
	if remaining > 0:
		print(str(remaining) + " villagers still need cleansing")
	else:
		print("All villagers have been cleansed!")
	
	update_ui()
	check_victory_condition()

func on_villager_message(message: String):
	"""Called to display villager cleanse message"""
	show_villager_message(message)

func on_shadow_defeated(shadow_name: String):
	"""Called when a shadow enemy is defeated"""
	shadows_defeated += 1
	var remaining_shadows = total_shadows - shadows_defeated
	
	print("Shadow defeated: ", shadow_name)
	print("Shadows remaining: ", remaining_shadows)
	
	# Check if all shadows are defeated
	if remaining_shadows == 0 and not barriers_removed:
		remove_shadow_barriers()
	
	# Give progress feedback
	if remaining_shadows == 0:
		print("All shadows have been defeated! The path to the village is clear!")
	elif remaining_shadows <= 3:
		print("Almost there! Only a few shadows remain!")
	elif remaining_shadows <= 6:
		print("Good progress! About halfway through the shadow army!")

func remove_shadow_barriers():
	"""Remove all shadow barriers when conditions are met"""
	barriers_removed = true
	print("All shadows defeated! The shadow barriers are dissolving...")
	
	# Find and remove all barriers
	var barriers = get_tree().get_nodes_in_group("shadow_barriers")
	for barrier in barriers:
		if barrier.has_method("remove_barrier"):
			barrier.remove_barrier()

func _on_kael_energy_changed(new_energy: float):
	"""Update energy bar and counter when Kaels energy changes"""
	if energy_bar:
		energy_bar.value = new_energy
	if energy_counter:
		energy_counter.text = str(int(new_energy)) + " / 100"

func update_ui():
	"""Update all UI elements"""
	if villager_counter:
		villager_counter.text = "Villagers Cleansed: " + str(villagers_cleansed) + " / " + str(total_villagers)
	
	if progress_counter:
		var kael_pos = kael.global_position.x if kael else 0
		var remaining_shadows = total_shadows - shadows_defeated
		
		if remaining_shadows > 0:
			progress_counter.text = "Defeat all shadows to reach the village! (" + str(remaining_shadows) + " remaining)"
		elif kael_pos < 2500 and not barriers_removed:
			progress_counter.text = "Shadow barriers are dissolving..."
		elif villagers_cleansed == 0:
			progress_counter.text = "You have reached the village! Save the villagers!"
		elif villagers_cleansed < total_villagers:
			progress_counter.text = str(total_villagers - villagers_cleansed) + " villagers still need your light!"
		else:
			progress_counter.text = "All villagers have been freed from shadow!"

func check_victory_condition():
	"""Check if all villagers have been cleansed"""
	if villagers_cleansed >= total_villagers:
		print("VICTORY! Light has triumphed over shadow!")
		print("Kael has completed his journey and saved the village!")
		show_temporary_message("VICTORY! All villagers saved!", 5.0)

func _input(event):
	"""Handle any additional input if needed"""
	pass