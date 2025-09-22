#!/usr/bin/env python3
"""
Simple MCP Test Server for Godot Integration
Tests basic MCP functionality
"""

import asyncio
import json
import sys
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("simple-mcp-test")

def test_imports():
    """Test if MCP imports work"""
    try:
        import mcp
        print(f"✓ MCP package found: {mcp.__version__ if hasattr(mcp, '__version__') else 'unknown version'}")
    except ImportError:
        print("✗ MCP package not found. Install with: pip install mcp")
        return False
    
    try:
        from mcp.server import Server
        print("✓ MCP Server import successful")
    except ImportError as e:
        print(f"✗ MCP Server import failed: {e}")
        return False
    
    try:
        from mcp.server.stdio import stdio_server
        print("✓ MCP stdio_server import successful")
    except ImportError as e:
        print(f"✗ MCP stdio_server import failed: {e}")
        return False
    
    try:
        from mcp.types import Resource, Tool, TextContent
        print("✓ MCP types import successful")
    except ImportError as e:
        print(f"✗ MCP types import failed: {e}")
        return False
    
    return True

def test_basic_functionality():
    """Test basic MCP server creation"""
    try:
        from mcp.server import Server
        server = Server("test-server")
        print("✓ MCP Server creation successful")
        return True
    except Exception as e:
        print(f"✗ MCP Server creation failed: {e}")
        return False

async def simple_mcp_server():
    """Simple MCP server for testing"""
    try:
        from mcp.server import Server
        from mcp.server.stdio import stdio_server
        from mcp.types import Tool, TextContent
        
        server = Server("simple-godot-mcp")
        
        @server.list_tools()
        async def list_tools():
            return [
                Tool(
                    name="hello",
                    description="Say hello from MCP server",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "name": {
                                "type": "string",
                                "description": "Name to greet"
                            }
                        },
                        "required": ["name"]
                    }
                )
            ]
        
        @server.call_tool()
        async def call_tool(name: str, arguments: dict):
            if name == "hello":
                user_name = arguments.get("name", "World")
                return [TextContent(
                    type="text",
                    text=f"Hello {user_name} from MCP Godot server!"
                )]
            else:
                return [TextContent(
                    type="text",
                    text=f"Unknown tool: {name}"
                )]
        
        print("Starting simple MCP server...")
        async with stdio_server() as streams:
            await server.run(
                streams[0], streams[1],
                server.create_initialization_options()
            )
    
    except Exception as e:
        print(f"Error running MCP server: {e}")
        return False

def main():
    """Main function"""
    print("=== MCP Installation Test ===")
    
    # Test imports
    if not test_imports():
        print("\n❌ MCP imports failed!")
        print("\nTo fix this, run:")
        print("pip install mcp")
        print("# or")
        print("pip install git+https://github.com/modelcontextprotocol/python-sdk.git")
        return
    
    # Test basic functionality
    if not test_basic_functionality():
        print("\n❌ Basic MCP functionality test failed!")
        return
    
    print("\n✅ All tests passed!")
    print("\nStarting simple MCP server (Press Ctrl+C to stop)...")
    
    try:
        asyncio.run(simple_mcp_server())
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user")
    except Exception as e:
        print(f"\n❌ Server error: {e}")

if __name__ == "__main__":
    main()
