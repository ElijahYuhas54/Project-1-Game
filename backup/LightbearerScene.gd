# Lightbearer: Rise of the Ember - Main Game Scene
# Kael starts as an outcast and discovers the ancient ember
extends Node2D

# Game state
var light_energy: float = 50.0
var max_light_energy: float = 100.0
var npcs_empowered: int = 0

# References
@onready var kael: CharacterBody2D
@onready var ui_layer: CanvasLayer
@onready var light_meter: ProgressBar
@onready var ember_light: Light2D

signal npc_empowered(npc_name: String)
signal light_energy_changed(new_value: float)

func _ready():
	print("Lightbearer: Rise of the Ember - Scene Started")
	# Connect to MCP client for AI assistance
	if has_node("/root/MCPClient"):
		var mcp = get_node("/root/MCPClient")
		mcp.notify_game_event({
			"type": "game_event",
			"event": "scene_started",
			"scene": "lightbearer_main",
			"player": "Kael"
		})
	
	setup_scene()

func setup_scene():
	"""Initialize the opening scene"""
	# Set initial light energy
	update_light_energy(light_energy)
	
	# Start narrative introduction
	call_deferred("start_opening_sequence")

func start_opening_sequence():
	"""Play opening sequence where Kael discovers the ember"""
	print("=== LIGHTBEARER: RISE OF THE EMBER ===")
	print("Kael wanders through the shadow-consumed village...")
	
	# Simulate discovery of ember
	await get_tree().create_timer(2.0).timeout
	discover_ember()

func discover_ember():
	"""Kael finds the ancient ember"""
	print("✨ Kael discovers a glowing ember in the ruins!")
	print("💫 The ember grants him the power to manipulate light!")
	
	# Grant initial light abilities
	gain_light_power("Light Pulse")
	update_light_energy(100.0)
	
	# Notify MCP of story progression
	if has_node("/root/MCPClient"):
		var mcp = get_node("/root/MCPClient")
		mcp.notify_game_event({
			"type": "story_progression",
			"event": "ember_discovered",
			"character": "Kael",
			"new_ability": "Light Pulse"
		})

func gain_light_power(power_name: String):
	"""Kael gains a new light-based ability"""
	print("🌟 New Light Power Gained: ", power_name)
	# Add visual effects, unlock mechanics, etc.

func update_light_energy(new_value: float):
	"""Update light energy meter"""
	light_energy = clamp(new_value, 0.0, max_light_energy)
	emit_signal("light_energy_changed", light_energy)
	
	if light_meter:
		light_meter.value = light_energy

func empower_npc(npc_name: String):
	"""Empower an NPC, restoring their abilities/memories"""
	npcs_empowered += 1
	print("💪 ", npc_name, " has been empowered! Total empowered: ", npcs_empowered)
	
	emit_signal("npc_empowered", npc_name)
	
	# Use light energy to empower others
	update_light_energy(light_energy - 20.0)
	
	# Notify MCP for AI story generation
	if has_node("/root/MCPClient"):
		var mcp = get_node("/root/MCPClient")
		mcp.notify_game_event({
			"type": "npc_empowered",
			"npc_name": npc_name,
			"total_empowered": npcs_empowered,
			"remaining_light": light_energy
		})

func _input(event):
	"""Handle player input for light abilities"""
	if event.is_action_pressed("light_pulse"):
		use_light_pulse()
	elif event.is_action_pressed("interact"):
		interact_with_nearby()

func use_light_pulse():
	"""Use light pulse ability"""
	if light_energy >= 10.0:
		print("💫 Kael uses Light Pulse!")
		update_light_energy(light_energy - 10.0)
		# Add light pulse effects, enemy interactions, etc.
	else:
		print("⚡ Not enough light energy!")

func interact_with_nearby():
	"""Interact with nearby NPCs or objects"""
	print("🤝 Kael reaches out to help...")
	# Simulate empowering an NPC
	call_deferred("empower_npc", "Village Elder")

# Light-based puzzle mechanics
func activate_light_switch(switch_id: String):
	"""Activate light-based puzzle elements"""
	print("🔆 Light switch activated: ", switch_id)

func reflect_light_beam(angle: float):
	"""Reflect light beams for puzzle solving"""
	print("🪞 Light beam reflected at angle: ", angle)

# Shadow creature interactions
func encounter_shadow_creature(creature_type: String):
	"""Handle encounters with shadow creatures"""
	print("👹 Shadow creature encountered: ", creature_type)
	
	match creature_type:
		"Fleeing Shadow":
			print("💨 The shadow flees from Kaels light!")
		"Aggressive Shade":
			print("⚔️ The shade attacks! Kael must use light defensively!")
		"Lost Soul":
			print("😢 A lost soul... perhaps it can be redeemed with light?")
