# Shadow.gd - Lesser shadow enemy
extends Area2D

var health = 1
var max_health = 1
var is_alive = true
var enemy_name = "Shadow"

@onready var sprite: ColorRect
@onready var shadow_aura: PointLight2D
@onready var name_label: Label

func _ready():
	# Get references to child nodes
	sprite = get_node("ShadowSprite")
	shadow_aura = get_node("ShadowAura")
	name_label = get_node("NameLabel")
	
	# Set initial appearance
	update_appearance()

func take_damage(damage: int = 1):
	"""Take damage from light pulse"""
	if not is_alive:
		return
	
	health -= damage
	if health <= 0:
		defeat_shadow()

func defeat_shadow():
	"""Defeat this shadow enemy"""
	if not is_alive:
		return  # Already defeated
	
	is_alive = false
	print(enemy_name, " has been defeated!")
	
	# Create defeat effect
	create_defeat_effect()
	
	# Notify the main scene
	var scene = get_node("/root/LightbearerScene")
	if scene and scene.has_method("on_shadow_defeated"):
		scene.on_shadow_defeated(enemy_name)
	
	# Remove after a short delay
	await get_tree().create_timer(0.5).timeout
	queue_free()

func create_defeat_effect():
	"""Create visual effect when defeated"""
	# Quick fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_property(shadow_aura, "energy", 0.0, 0.5)
	tween.tween_property(name_label, "modulate:a", 0.0, 0.5)

func update_appearance():
	"""Update shadow appearance based on health"""
	if is_alive:
		# Dark gray appearance
		sprite.color = Color(0.25, 0.25, 0.25, 1)
		shadow_aura.color = Color(0.3, 0.2, 0.3, 1)
		shadow_aura.energy = 0.4
	else:
		# Faded when defeated
		sprite.color = Color(0.25, 0.25, 0.25, 0.2)
		shadow_aura.energy = 0.0