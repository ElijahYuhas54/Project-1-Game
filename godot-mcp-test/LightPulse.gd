# LightPulse.gd - Visual effect for light pulse ability
extends Node2D

var pulse_radius = 0.0
var max_radius = 120.0
var pulse_speed = 300.0
var fade_duration = 0.8

@onready var pulse_light: PointLight2D
@onready var pulse_area: Area2D
@onready var pulse_collision: CollisionShape2D

signal pulse_hit_villager(villager)
signal pulse_hit_shadow(shadow)

func _ready():
	# Create the visual light effect
	pulse_light = PointLight2D.new()
	pulse_light.color = Color(1.0, 0.9, 0.6, 0.8)
	pulse_light.energy = 2.0
	pulse_light.texture_scale = 0.1
	add_child(pulse_light)
	
	# Create area for collision detection
	pulse_area = Area2D.new()
	pulse_collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	pulse_collision.shape = circle_shape
	pulse_area.add_child(pulse_collision)
	add_child(pulse_area)
	
	# Connect area signals
	pulse_area.area_entered.connect(_on_area_entered)
	
	# Start the pulse animation
	start_pulse()

func start_pulse():
	"""Start the expanding pulse effect"""
	pulse_radius = 0.0
	
	# Animate the pulse expansion
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Expand the radius
	tween.tween_method(update_pulse_radius, 0.0, max_radius, fade_duration)
	
	# Fade out the light
	tween.tween_property(pulse_light, "energy", 0.0, fade_duration)
	
	# Remove after animation
	tween.tween_callback(queue_free).set_delay(fade_duration)

func update_pulse_radius(new_radius: float):
	"""Update the visual pulse radius"""
	pulse_radius = new_radius
	
	# Update visual scale
	if pulse_light:
		pulse_light.texture_scale = pulse_radius / 60.0  # Scale factor
	
	# Update collision shape
	if pulse_collision and pulse_collision.shape:
		pulse_collision.shape.radius = pulse_radius

func _on_area_entered(area: Area2D):
	"""Handle when pulse hits an area"""
	# Check for villagers
	if area.has_method("cleanse_shadows"):
		area.cleanse_shadows()
		emit_signal("pulse_hit_villager", area)
	
	# Check for shadow enemies (both types)
	if area.has_method("take_damage"):
		area.take_damage(1)
		emit_signal("pulse_hit_shadow", area)
	elif area.has_method("defeat_shadow"):
		area.defeat_shadow()
		emit_signal("pulse_hit_shadow", area)

func _draw():
	"""Draw the pulse ring effect"""
	if pulse_radius > 0:
		# Draw a faint ring effect
		var ring_color = Color(1.0, 0.9, 0.6, 0.3)
		var ring_thickness = 8.0
		
		# Draw outer ring
		draw_arc(Vector2.ZERO, pulse_radius, 0, TAU, 64, ring_color, ring_thickness)
		
		# Draw inner filled circle with transparency
		var fill_color = Color(1.0, 0.9, 0.6, 0.1)
		draw_circle(Vector2.ZERO, pulse_radius, fill_color)

func _process(_delta):
	"""Trigger redraw for animation"""
	queue_redraw()