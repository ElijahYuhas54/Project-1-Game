# Kael - The Lightbearer protagonist
# Handles movement, light abilities, and character progression
extends CharacterBody2D

# Movement constants
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 400.0
const DASH_DURATION = 0.2

# Light abilities
var light_dash_unlocked = false
var light_pulse_unlocked = true
var ember_power = 50.0

# Animation and visuals
@onready var animated_sprite: AnimatedSprite2D
@onready var light_aura: Light2D
@onready var dash_timer: Timer

# Character state
var is_dashing = false
var facing_direction = 1

signal light_ability_used(ability_name: String, energy_cost: float)
signal ember_energy_changed(new_energy: float)

func _ready():
	print("Kael initialized - From outcast to Lightbearer")
	
	# Setup dash timer
	dash_timer = Timer.new()
	add_child(dash_timer)
	dash_timer.wait_time = DASH_DURATION
	dash_timer.one_shot = true
	dash_timer.timeout.connect(_on_dash_timeout)
	
	# Initialize visual effects
	update_light_aura()

func _physics_process(delta):
	# Handle gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	# Handle movement input
	handle_movement_input()
	
	# Handle light ability input
	handle_ability_input()
	
	# Move character
	move_and_slide()

func handle_movement_input():
	"""Process movement input with light-enhanced abilities"""
	if is_dashing:
		return  # No input during dash
	
	# Horizontal movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = direction * SPEED
		facing_direction = sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		print("🦘 Kael jumps!")
	
	# Light Dash (if unlocked)
	if Input.is_action_just_pressed("dash") and light_dash_unlocked and ember_power >= 15:
		perform_light_dash()

func handle_ability_input():
	"""Process light ability input"""
	if Input.is_action_just_pressed("light_pulse") and light_pulse_unlocked:
		use_light_pulse()
	
	if Input.is_action_just_pressed("interact"):
		interact_with_environment()

func perform_light_dash():
	"""Perform light-enhanced dash movement"""
	if is_dashing or ember_power < 15:
		return
	
	print("✨ Kael performs Light Dash!")
	is_dashing = true
	velocity.x = facing_direction * DASH_SPEED
	velocity.y = 0  # Reset vertical velocity
	
	# Consume ember energy
	update_ember_energy(ember_power - 15)
	
	# Start dash timer
	dash_timer.start()
	
	# Emit signal
	emit_signal("light_ability_used", "Light Dash", 15.0)
	
	# Visual effect (light trail)
	create_light_trail()

func use_light_pulse():
	"""Use light pulse to interact with environment"""
	if ember_power < 10:
		print("💡 Not enough ember energy for Light Pulse!")
		return
	
	print("💫 Kael uses Light Pulse!")
	update_ember_energy(ember_power - 10)
	
	# Create light pulse effect
	create_light_pulse_effect()
	
	# Emit signal
	emit_signal("light_ability_used", "Light Pulse", 10.0)
	
	# Check for nearby shadow creatures or puzzles
	check_light_interactions()

func interact_with_environment():
	"""Interact with NPCs, objects, or puzzle elements"""
	print("🤝 Kael reaches out to help...")
	# This will trigger empowerment mechanics in the main scene

func create_light_trail():
	"""Visual effect for light dash"""
	print("🌟 Light trail created behind Kael")
	# Add particle system or light effects

func create_light_pulse_effect():
	"""Visual effect for light pulse"""
	print("💫 Light pulse radiates from Kael")
	# Add expanding light effect

func check_light_interactions():
	"""Check for light-based interactions with environment"""
	# Detect shadow creatures that flee from light
	# Activate light-based puzzle elements
	# Reveal hidden paths or secrets
	pass

func update_ember_energy(new_energy: float):
	"""Update Kaels ember energy"""
	ember_power = clamp(new_energy, 0.0, 100.0)
	emit_signal("ember_energy_changed", ember_power)
	update_light_aura()

func update_light_aura():
	"""Update visual light aura based on ember power"""
	if light_aura:
		light_aura.energy = ember_power / 100.0
		# Change color based on power level
		if ember_power > 70:
			light_aura.color = Color.GOLD
		elif ember_power > 30:
			light_aura.color = Color.ORANGE
		else:
			light_aura.color = Color.RED

func unlock_ability(ability_name: String):
	"""Unlock new light abilities as Kael progresses"""
	match ability_name:
		"Light Dash":
			light_dash_unlocked = true
			print("🚀 Light Dash unlocked!")
		"Advanced Pulse":
			# Upgrade existing abilities
			print("⚡ Light Pulse upgraded!")
		"Ember Burst":
			print("💥 Ember Burst unlocked!")

func _on_dash_timeout():
	"""End dash state"""
	is_dashing = false
	velocity.x = move_toward(velocity.x, 0, SPEED)

func gain_ember_energy(amount: float):
	"""Restore ember energy (from light sources, empowered NPCs, etc.)"""
	update_ember_energy(ember_power + amount)
	print("✨ Ember energy restored: +", amount)
