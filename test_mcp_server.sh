#!/bin/bash

# Test script for MCP HTTP Server
echo "=== Testing MCP HTTP Server ==="
echo

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_URL="http://localhost:8081"

test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "${BLUE}Testing: $description${NC}"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" $SERVER_URL$endpoint)
    else
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X $method \
            -H "Content-Type: application/json" \
            -d "$data" \
            $SERVER_URL$endpoint)
    fi
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_CODE:")
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ SUCCESS${NC}"
        echo "Response: $body"
    else
        echo -e "${RED}✗ FAILED (HTTP $http_code)${NC}"
        echo "Response: $body"
    fi
    echo "----------------------------------------"
}

echo "Testing server..."
echo

# Test 1: Server Status
test_endpoint "GET" "/status" "" "Server Status Check"

# Test 2: Set Project Path
PROJECT_PATH="$HOME/mcp-godot-integration/godot-mcp-test"
test_endpoint "POST" "/set-project" "{\"path\": \"$PROJECT_PATH\"}" "Set Project Path"

# Test 3: Create a Test Script
SCRIPT_CONTENT="extends Node\\n\\nfunc _ready():\\n\\tprint(\\\"Hello from MCP!\\\")"
test_endpoint "POST" "/create-script" "{\"filename\": \"mcp_test.gd\", \"content\": \"$SCRIPT_CONTENT\"}" "Create Test Script"

echo -e "${BLUE}=== Testing Complete ===${NC}"
