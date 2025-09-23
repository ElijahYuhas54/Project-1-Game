# LightbearerScene.gd - Extended journey-based game scene
extends Node2D

var villagers_cleansed = 0
var total_villagers = 3
var shadows_defeated = 0
var total_shadows = 0

@onready var kael: CharacterBody2D
@onready var energy_bar: ProgressBar
@onready var villager_counter: Label
@onready var progress_counter: Label
@onready var villagers_node: Node2D
@onready var background: ColorRect
@onready var ground_rect: ColorRect
@onready var ui_scene: CanvasLayer
@onready var enemies_node: Node2D

# Preload scenes
const ShadowMonarchScene = preload("res://ShadowMonarch.tscn")
const ShadowScene = preload("res://Shadow.tscn")
const EnergyPickupScene = preload("res://EnergyPickup.tscn")

func _ready():
	print("=== LIGHTBEARER: RISE OF THE EMBER ===")
	print("Kael discovers the ancient ember in the village ruins!")
	print("The villagers are trapped in shadow at the far end of this cursed land...")
	print("Fight through the shadows to reach the village and save them!")
	print("Use Light Pulse (Z) to defeat enemies and collect energy pickups!")
	
	# Get references to nodes
	kael = get_node("GameWorld/Characters/Kael")
	ui_scene = get_node("UI")
	energy_bar = get_node("UI/EnergyPanel/EnergyVBox/EnergyBar")
	villager_counter = get_node("UI/ProgressPanel/ProgressVBox/VillagerCounter")
	progress_counter = get_node("UI/ProgressPanel/ProgressVBox/ProgressCounter")
	villagers_node = get_node("GameWorld/Villagers")
	enemies_node = get_node("GameWorld/Enemies")
	background = get_node("GameWorld/Background")
	ground_rect = get_node("GameWorld/Ground/GroundRect")
	
	# Connect Kaels energy signal
	if kael:
		kael.energy_changed.connect(_on_kael_energy_changed)
	
	# Initialize villager names
	setup_villagers()
	
	# Count existing enemies
	total_shadows = enemies_node.get_child_count()
	
	# Update initial UI
	update_ui()
	
	# Add scene to group for villagers to find
	add_to_group("lightbearer_scene")
	
	# Notify MCP that game started
	if has_node("/root/MCPClient"):
		get_node("/root/MCPClient").notify_game_event({
			"type": "game_started",
			"scene": "lightbearer_journey",
			"total_villagers": total_villagers,
			"objective": "Journey east, defeat shadows, and save the villagers"
		})

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
	
	# Notify MCP of progress
	if has_node("/root/MCPClient"):
		get_node("/root/MCPClient").notify_game_event({
			"type": "villager_cleansed",
			"villager_name": villager_name,
			"total_cleansed": villagers_cleansed,
			"remaining": total_villagers - villagers_cleansed,
			"progress_percentage": (float(villagers_cleansed) / total_villagers) * 100
		})

func on_shadow_defeated(shadow_name: String):
	"""Called when a shadow enemy is defeated"""
	shadows_defeated += 1
	var remaining_shadows = total_shadows - shadows_defeated
	
	print("Shadow defeated: ", shadow_name)
	print("Shadows remaining: ", remaining_shadows)
	
	# Give progress feedback
	if remaining_shadows == 0:
		print("All shadows have been defeated! The path to the village is clear!")
	elif remaining_shadows <= 3:
		print("Almost there! Only a few shadows remain!")
	elif remaining_shadows <= 6:
		print("Good progress! About halfway through the shadow army!")

func _on_kael_energy_changed(new_energy: float):
	"""Update energy bar when Kaels energy changes"""
	if energy_bar:
		energy_bar.value = new_energy

func update_ui():
	"""Update all UI elements"""
	if villager_counter:
		villager_counter.text = "Villagers Cleansed: " + str(villagers_cleansed) + " / " + str(total_villagers)
	
	if progress_counter:
		var kael_pos = kael.global_position.x if kael else 0
		if kael_pos < 500:
			progress_counter.text = "Journey east to reach the village!"
		elif kael_pos < 1500:
			progress_counter.text = "Fighting through the shadow army..."
		elif kael_pos < 2500:
			progress_counter.text = "Village is near! Defeat the remaining shadows!"
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
		
		# Victory notification to MCP
		if has_node("/root/MCPClient"):
			get_node("/root/MCPClient").notify_game_event({
				"type": "victory_achieved",
				"message": "Journey complete - All villagers saved!",
				"final_score": villagers_cleansed,
				"shadows_defeated": shadows_defeated
			})

func _input(event):
	"""Handle any additional input if needed"""
	pass