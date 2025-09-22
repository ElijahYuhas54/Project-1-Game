# ShadowMonarch.gd - Stronger shadow enemy with multiple health points
extends Area2D

var health = 3
var max_health = 3
var is_alive = true
var enemy_name = "Shadow Monarch"

@onready var sprite: ColorRect
@onready var dark_aura: PointLight2D
@onready var name_label: Label

func _ready():
	# Get references to child nodes
	sprite = get_node("ShadowSprite")
	dark_aura = get_node("DarkAura")
	name_label = get_node("NameLabel")
	
	# Set initial dark appearance
	update_appearance()

func take_damage(damage: int = 1):
	"""Take damage from light pulse"""
	if not is_alive:
		return
	
	health -= damage
	print(enemy_name, " takes damage! Health: ", health, "/", max_health)
	
	# Visual damage feedback
	create_damage_effect()
	
	if health <= 0:
		defeat_shadow()
	else:
		update_appearance()

func create_damage_effect():
	"""Flash effect when taking damage"""
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func defeat_shadow():
	"""Defeat this shadow enemy"""
	if not is_alive:
		return  # Already defeated
	
	is_alive = false
	print(enemy_name, " has been defeated by the light!")
	print("\"The darkness cannot withstand the power of the ember!\"")
	
	# Create defeat effect
	create_defeat_effect()
	
	# Notify the main scene
	var scene = get_node("/root/LightbearerScene")
	if scene and scene.has_method("on_shadow_defeated"):
		scene.on_shadow_defeated(enemy_name)
	
	# Remove after a delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

func create_defeat_effect():
	"""Create visual effect when defeated"""
	# Fade out the sprite
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tween.tween_property(dark_aura, "energy", 0.0, 1.0)
	tween.tween_property(name_label, "modulate:a", 0.0, 1.0)

func update_appearance():
	"""Update shadow monarch appearance based on health"""
	if is_alive:
		# Color changes based on health
		var health_ratio = float(health) / max_health
		if health_ratio > 0.66:
			sprite.color = Color(0.15, 0.15, 0.15, 1)  # Very dark
		elif health_ratio > 0.33:
			sprite.color = Color(0.2, 0.2, 0.2, 1)    # Slightly lighter
		else:
			sprite.color = Color(0.25, 0.25, 0.25, 1) # Lighter when damaged
		
		dark_aura.color = Color(0.2, 0.1, 0.2, 1)
		dark_aura.energy = 0.3 + (health_ratio * 0.2)
	else:
		# Faded when defeated
		sprite.color = Color(0.15, 0.15, 0.15, 0.3)
		dark_aura.energy = 0.0