# Kael.gd - The Lightbearer character controller with directional arrow
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const LightPulseScene = preload("res://LightPulse.tscn")

var ember_energy = 100.0
var max_ember_energy = 100.0
var light_pulse_cost = 15.0
var facing_direction = 1  # 1 for right, -1 for left

signal energy_changed(new_energy)
signal light_pulse_used(kael_position)

@onready var light_aura: PointLight2D
@onready var camera: Camera2D
@onready var direction_arrow: Polygon2D

func _ready():
	print("Kael - The Lightbearer awakens!")
	print("Controls: Arrow/WASD=Move, Space=Jump, Z=Light Pulse")
	print("Journey eastward to reach the village and save the villagers!")
	
	light_aura = get_node("LightAura")
	camera = get_node("Camera2D")
	direction_arrow = get_node("DirectionArrow")
	update_light_aura()
	update_direction_arrow()

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	# Handle movement with custom actions
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		# Update facing direction
		if direction > 0:
			facing_direction = 1  # Moving right
		elif direction < 0:
			facing_direction = -1  # Moving left
		update_direction_arrow()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Handle jumping with custom action - no output
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle light pulse with custom action (Z key)
	if Input.is_action_just_pressed("light_pulse"):
		use_light_pulse()
	
	move_and_slide()
	
	# Update camera to follow Kael
	update_camera()

func update_direction_arrow():
	"""Update arrow direction based on movement"""
	if direction_arrow:
		if facing_direction == 1:  # Facing right
			# Right-pointing arrow: tip at (6,0), base from (-6,-3) to (-6,3)
			direction_arrow.polygon = PackedVector2Array([Vector2(6, 0), Vector2(-6, -3), Vector2(-3, -3), Vector2(-3, 3), Vector2(-6, 3)])
		else:  # Facing left
			# Left-pointing arrow: tip at (-6,0), base from (6,-3) to (6,3)
			direction_arrow.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(6, -3), Vector2(3, -3), Vector2(3, 3), Vector2(6, 3)])
		
		# Show arrow when moving, fade when idle
		var is_moving = abs(velocity.x) > 10
		var target_alpha = 0.8 if is_moving else 0.3
		direction_arrow.color.a = target_alpha

func update_camera():
	"""Make camera follow Kael within limits"""
	if camera:
		camera.global_position.x = global_position.x
		camera.global_position.y = 324  # Keep Y position fixed

func use_light_pulse():
	if ember_energy >= light_pulse_cost:
		ember_energy -= light_pulse_cost
		ember_energy = max(ember_energy, 0.0)
		
		# Emit signals
		emit_signal("energy_changed", ember_energy)
		emit_signal("light_pulse_used", global_position)
		
		# Only show energy usage info
		print("Light Pulse used! Energy: ", ember_energy, "/", max_ember_energy)
		
		# Create visual pulse effect
		create_pulse_effect()
		
		# Visual effect - strengthen light aura temporarily
		if light_aura:
			light_aura.energy = 3.0
			create_tween().tween_property(light_aura, "energy", 1.5, 0.5)
		
		# Update light aura based on remaining energy
		update_light_aura()
		
		# Notify MCP of ability use
		if has_node("/root/MCPClient"):
			get_node("/root/MCPClient").notify_game_event({
				"type": "light_pulse_used",
				"position": {"x": global_position.x, "y": global_position.y},
				"energy_remaining": ember_energy,
				"energy_percentage": (ember_energy / max_ember_energy) * 100
			})
	else:
		print("Not enough ember energy! Need: ", light_pulse_cost, ", Current: ", ember_energy)

func create_pulse_effect():
	"""Create the visual expanding pulse effect"""
	var pulse_instance = LightPulseScene.instantiate()
	pulse_instance.global_position = global_position
	
	# Add to scene tree (parent scene)
	get_parent().get_parent().add_child(pulse_instance)

func update_light_aura():
	"""Update light aura based on current ember energy"""
	if light_aura:
		# Scale aura intensity with energy level
		var energy_ratio = ember_energy / max_ember_energy
		light_aura.energy = 1.0 + (energy_ratio * 0.5)
		
		# Change color based on energy level
		if energy_ratio > 0.7:
			light_aura.color = Color(1.0, 0.9, 0.6, 1)
		elif energy_ratio > 0.3:
			light_aura.color = Color(1.0, 0.7, 0.4, 1)
		else:
			light_aura.color = Color(1.0, 0.5, 0.3, 1)

func restore_energy(amount: float):
	"""Restore ember energy (called by energy pickups)"""
	var old_energy = ember_energy
	ember_energy = min(ember_energy + amount, max_ember_energy)
	var actual_restored = ember_energy - old_energy
	
	emit_signal("energy_changed", ember_energy)
	update_light_aura()
	
	# Console output for energy pickup
	print("Energy picked up! +", actual_restored, " energy")
	print("Current energy: ", ember_energy, "/", max_ember_energy)