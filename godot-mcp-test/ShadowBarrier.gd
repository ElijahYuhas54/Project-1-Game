# ShadowBarrier.gd - Blocks passage until all shadows are defeated
extends StaticBody2D

var is_active = true
var player_nearby = false
var label_tween: Tween

@onready var barrier_visual: ColorRect
@onready var barrier_collision: CollisionShape2D
@onready var barrier_effect: PointLight2D
@onready var player_detection: Area2D
@onready var wall_label: Label

func _ready():
	# Get references to nodes
	barrier_visual = get_node("BarrierVisual")
	barrier_collision = get_node("BarrierCollision")
	barrier_effect = get_node("BarrierEffect")
	player_detection = get_node("PlayerDetection")
	wall_label = get_node("WallLabel")
	
	# Connect player detection signals
	player_detection.body_entered.connect(_on_player_entered)
	player_detection.body_exited.connect(_on_player_exited)
	
	# Add to group so main scene can find all barriers
	add_to_group("shadow_barriers")
	
	# Start with barrier active
	update_barrier_state()

func _on_player_entered(body):
	"""Player approached the barrier"""
	if body.name == "Kael" and is_active:
		player_nearby = true
		show_barrier_message()

func _on_player_exited(body):
	"""Player left the barrier area"""
	if body.name == "Kael":
		player_nearby = false
		hide_barrier_message()

func show_barrier_message():
	"""Show the barrier message with fade-in effect"""
	if label_tween:
		label_tween.kill()
	
	label_tween = create_tween()
	label_tween.tween_property(wall_label, "modulate:a", 1.0, 0.3)

func hide_barrier_message():
	"""Hide the barrier message with fade-out effect"""
	if label_tween:
		label_tween.kill()
	
	label_tween = create_tween()
	label_tween.tween_property(wall_label, "modulate:a", 0.0, 0.3)

func remove_barrier():
	"""Remove the barrier when conditions are met"""
	if not is_active:
		return  # Already removed
	
	is_active = false
	print("Shadow Barrier dissolving... the path is now clear!")
	
	# Show barrier lifted message to player
	show_global_message("The shadow barrier has been lifted!")
	
	# Create dissolve effect
	create_dissolve_effect()
	
	# Remove collision immediately
	barrier_collision.set_deferred("disabled", true)
	
	# Hide message if player is nearby
	if player_nearby:
		hide_barrier_message()

func show_global_message(message: String):
	"""Show a global message to the player"""
	var scene = get_node("/root/LightbearerScene")
	if scene and scene.has_method("show_temporary_message"):
		scene.show_temporary_message(message)

func create_dissolve_effect():
	"""Visual effect for barrier removal"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out visual elements
	tween.tween_property(barrier_visual, "modulate:a", 0.0, 1.5)
	tween.tween_property(barrier_effect, "energy", 0.0, 1.5)
	
	# Remove completely after effect
	tween.tween_callback(queue_free).set_delay(1.5)

func update_barrier_state():
	"""Update barrier appearance based on state"""
	if is_active:
		barrier_visual.modulate.a = 0.9
		barrier_effect.energy = 1.5
	else:
		barrier_visual.modulate.a = 0.0
		barrier_effect.energy = 0.0