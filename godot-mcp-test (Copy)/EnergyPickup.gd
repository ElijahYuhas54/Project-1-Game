# EnergyPickup.gd - Energy restoration pickup
extends Area2D

var energy_amount = 25.0
var is_collected = false
var initial_position: Vector2

@onready var sprite: ColorRect
@onready var energy_glow: PointLight2D

func _ready():
	# Get references to child nodes
	sprite = get_node("PickupSprite")
	energy_glow = get_node("EnergyGlow")
	
	# Store initial position for floating animation
	initial_position = position
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	
	# Start floating animation
	start_floating_animation()

func start_floating_animation():
	"""Create gentle floating motion"""
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", initial_position.y - 10, 1.5)
	tween.tween_property(self, "position:y", initial_position.y + 10, 1.5)

func _on_body_entered(body):
	"""Handle when player touches pickup"""
	if is_collected:
		return
	
	if body.name == "Kael" and body.has_method("restore_energy"):
		is_collected = true
		
		# Restore energy to Kael
		body.restore_energy(energy_amount)
		
		# Create collection effect
		create_collection_effect()
		
		# Remove pickup
		queue_free()

func create_collection_effect():
	"""Visual effect when collected"""
	# Quick flash and fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(energy_glow, "energy", 2.0, 0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(energy_glow, "energy", 0.0, 0.3)