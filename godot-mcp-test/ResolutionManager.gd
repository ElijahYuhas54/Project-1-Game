# ResolutionManager.gd - Global resolution and scaling management
extends Node

# Base resolution for scaling calculations
const BASE_RESOLUTION = Vector2(1152, 648)

# Current resolution settings
var current_resolution: Vector2i
var current_scale_factor: float = 1.0
var is_fullscreen: bool = false

signal resolution_changed(new_resolution: Vector2i, scale_factor: float)

func _ready():
	print("ResolutionManager initialized")
	current_resolution = Vector2i(DisplayServer.window_get_size())
	calculate_scale_factor()

func calculate_scale_factor():
	"""Calculate uniform scale factor to maintain aspect ratio"""
	var scale_x = float(current_resolution.x) / BASE_RESOLUTION.x
	var scale_y = float(current_resolution.y) / BASE_RESOLUTION.y
	current_scale_factor = min(scale_x, scale_y)

func set_resolution(new_size: Vector2i, fullscreen: bool = false):
	"""Set new resolution and apply scaling"""
	current_resolution = new_size
	is_fullscreen = fullscreen
	
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(new_size)
		
		# Center the window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - new_size) / 2
		DisplayServer.window_set_position(window_pos)
	
	# Update viewport
	get_viewport().set_size(new_size)
	
	# Calculate new scale factor
	calculate_scale_factor()
	
	# Emit signal for scenes to update
	resolution_changed.emit(current_resolution, current_scale_factor)
	
	print("Resolution set to: ", new_size, " Scale factor: ", current_scale_factor)

func apply_scaling_to_node(node: Node):
	"""Apply current scaling to a node"""
	if node is Control or node is Node2D:
		node.scale = Vector2(current_scale_factor, current_scale_factor)

func get_current_scale_factor() -> float:
	"""Get the current scale factor"""
	return current_scale_factor

func get_scaled_size(original_size: Vector2) -> Vector2:
	"""Get scaled size based on current scale factor"""
	return original_size * current_scale_factor