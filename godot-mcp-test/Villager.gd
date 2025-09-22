# Villager.gd - Individual villager with shadow cleansing mechanics
extends Area2D

var is_shadowed = true
var villager_name = "Villager"

@onready var sprite: ColorRect
@onready var shadow_aura: PointLight2D
@onready var name_label: Label

func _ready():
	# Get references to child nodes
	sprite = get_node("VillagerSprite")
	shadow_aura = get_node("ShadowAura")
	name_label = get_node("NameLabel")
	
	# Set initial shadowed state
	update_appearance()

func cleanse_shadows():
	"""Cleanse this villager of shadows"""
	if not is_shadowed:
		return  # Already cleansed
	
	is_shadowed = false
	update_appearance()
	
	print(villager_name, " has been cleansed of shadows!")
	print("\"" + get_cleansed_message() + "\"")
	
	# Notify the main scene
	var scene = get_node("/root/LightbearerScene")
	if scene and scene.has_method("on_villager_cleansed"):
		scene.on_villager_cleansed(villager_name)

func update_appearance():
	"""Update villager appearance based on shadow state"""
	if is_shadowed:
		# Shadowed: Grey with dark purple aura
		sprite.color = Color(0.3, 0.3, 0.3, 1)  # Dark grey
		shadow_aura.color = Color(0.4, 0.2, 0.4, 1)  # Purple shadow
		shadow_aura.energy = 0.3
	else:
		# Cleansed: Green with warm golden aura
		sprite.color = Color(0.2, 0.8, 0.3, 1)  # Vibrant green
		shadow_aura.color = Color(1.0, 0.9, 0.6, 1)  # Warm golden light
		shadow_aura.energy = 0.8

func get_cleansed_message() -> String:
	"""Get a personalized message when cleansed"""
	var messages = [
		"The darkness lifts from my soul! Thank you, Lightbearer!",
		"I can see clearly now! The shadows have released me!",
		"Light has returned to my heart! I am free!",
		"The warmth of hope fills me again!",
		"I remember who I was before the shadows took me!"
	]
	return messages[randi() % messages.size()]

func set_villager_name(new_name: String):
	"""Set the villagers name"""
	villager_name = new_name
	if name_label:
		name_label.text = villager_name