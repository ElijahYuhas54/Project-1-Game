# MCPClient.gd - MCP integration for Godot
extends Node

var http_request: HTTPRequest
var mcp_server_url = "http://localhost:8082"
var request_queue = []
var is_requesting = false

func _ready():
	print("MCP Client initializing...")
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	call_deferred("test_connection")

func test_connection():
	print("Testing MCP connection...")
	make_request("/status", {})

func notify_game_event(event_data: Dictionary):
	make_request("/from-godot", event_data)

func make_request(endpoint: String, data: Dictionary = {}):
	var request_info = {"endpoint": endpoint, "data": data}
	request_queue.append(request_info)
	process_queue()

func process_queue():
	if is_requesting or request_queue.is_empty():
		return
	
	is_requesting = true
	var request_info = request_queue.pop_front()
	
	var headers = ["Content-Type: application/json"]
	var url = mcp_server_url + request_info.endpoint
	
	if request_info.data.is_empty():
		http_request.request(url, headers)
	else:
		var json_string = JSON.stringify(request_info.data)
		http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	var response = body.get_string_from_utf8()
	print("MCP Response (", response_code, "): ", response)
	
	is_requesting = false
	call_deferred("process_queue")  # Process next request in queue