# MCPClient.gd
# Godot 4 script for communicating with MCP Python server
extends Node

# HTTP client for sending requests to MCP server
var http_request: HTTPRequest
var mcp_server_url = "http://localhost:8081"

# MCP data storage
var mcp_data: Dictionary = {}

signal mcp_data_received(data: Dictionary)
signal mcp_connection_status(connected: bool)

func _ready():
	print("MCP Client initializing...")
	
	# Create HTTP request node for outgoing requests
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# Test connection to MCP server
	call_deferred("test_mcp_connection")

func test_mcp_connection():
	"""Test connection to MCP server"""
	print("Testing MCP server connection...")
	request_mcp_data("status", {})

func request_mcp_data(endpoint: String, data: Dictionary = {}):
	"""Send GET request to MCP server"""
	var url = mcp_server_url + "/" + endpoint
	var headers = ["Content-Type: application/json"]
	
	if data.is_empty():
		# GET request
		var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
		if error != OK:
			print("Error making GET request: ", error)
	else:
		# POST request
		var json_string = JSON.stringify(data)
		var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
		if error != OK:
			print("Error making POST request: ", error)

func send_to_mcp(endpoint: String, data: Dictionary):
	"""Send POST request to MCP server"""
	var url = mcp_server_url + "/" + endpoint
	var json_string = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		print("Error sending to MCP server: ", error)
		emit_signal("mcp_connection_status", false)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handle HTTP request completion"""
	var response_text = body.get_string_from_utf8()
	
	if response_code == 200:
		print("MCP Server Response (", response_code, "): ", response_text)
		
		# Try to parse JSON response
		var json = JSON.new()
		var parse_result = json.parse(response_text)
		
		if parse_result == OK:
			var data = json.data
			mcp_data = data
			emit_signal("mcp_data_received", data)
			emit_signal("mcp_connection_status", true)
		else:
			print("Failed to parse JSON from MCP server")
	else:
		print("MCP Server Error (", response_code, "): ", response_text)
		emit_signal("mcp_connection_status", false)

# Public API methods
func create_script(filename: String, content: String, path: String = ""):
	"""Request MCP server to create a script"""
	var data = {
		"filename": filename,
		"content": content,
		"path": path
	}
	send_to_mcp("create-script", data)

func get_project_info():
	"""Get project structure from MCP server"""
	request_mcp_data("project-structure")

func notify_game_event(event_data: Dictionary):
	"""Notify MCP server of game events"""
	send_to_mcp("from-godot", event_data)
