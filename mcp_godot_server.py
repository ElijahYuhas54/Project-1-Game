#!/usr/bin/env python3
"""
MCP Server for Godot 4 Integration
Provides game development tools and resources via Model Context Protocol
"""

import asyncio
import json
import logging
from typing import Dict, List, Any, Optional
import subprocess
import os
import sys

try:
    from mcp.server import Server
    from mcp.server.stdio import stdio_server
    from mcp.types import Resource, Tool, TextContent
except ImportError as e:
    print(f"Error importing MCP modules: {e}")
    print("Please install MCP with: pip install mcp")
    sys.exit(1)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp-godot-server")

class GodotMCPServer:
    def __init__(self):
        self.server = Server("godot-mcp-server")
        self.godot_project_path = ""
        self.setup_handlers()
    
    def setup_handlers(self):
        """Setup MCP server handlers"""
        
        @self.server.list_resources()
        async def list_resources() -> List[Resource]:
            """List available Godot resources"""
            resources = []
            
            # Project files resource
            resources.append(Resource(
                uri="godot://project-structure",
                name="Godot Project Structure",
                description="Current Godot project file structure",
                mimeType="application/json"
            ))
            
            # Scene files resource
            if self.godot_project_path and os.path.exists(self.godot_project_path):
                resources.append(Resource(
                    uri="godot://scenes",
                    name="Godot Scenes",
                    description="Available .tscn scene files",
                    mimeType="application/json"
                ))
                
                # Script files resource
                resources.append(Resource(
                    uri="godot://scripts",
                    name="GDScript Files",
                    description="Available .gd script files",
                    mimeType="application/json"
                ))
            
            return resources
        
        @self.server.read_resource()
        async def read_resource(uri: str) -> str:
            """Read a specific Godot resource"""
            if uri == "godot://project-structure":
                return self._get_project_structure()
            elif uri == "godot://scenes":
                return self._get_scene_files()
            elif uri == "godot://scripts":
                return self._get_script_files()
            else:
                raise ValueError(f"Unknown resource: {uri}")
        
        @self.server.list_tools()
        async def list_tools() -> List[Tool]:
            """List available Godot development tools"""
            return [
                Tool(
                    name="set_godot_project",
                    description="Set the path to the Godot project",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "path": {
                                "type": "string",
                                "description": "Path to the Godot project directory"
                            }
                        },
                        "required": ["path"]
                    }
                ),
                Tool(
                    name="create_gdscript",
                    description="Create a new GDScript file",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "filename": {
                                "type": "string",
                                "description": "Name of the script file (with .gd extension)"
                            },
                            "content": {
                                "type": "string",
                                "description": "Content of the GDScript"
                            },
                            "path": {
                                "type": "string",
                                "description": "Relative path within project (optional)",
                                "default": ""
                            }
                        },
                        "required": ["filename", "content"]
                    }
                ),
                Tool(
                    name="run_godot_command",
                    description="Execute Godot editor commands",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "command": {
                                "type": "string",
                                "description": "Godot command to execute (e.g., --headless, --export)"
                            },
                            "args": {
                                "type": "array",
                                "items": {"type": "string"},
                                "description": "Additional arguments for the command"
                            }
                        },
                        "required": ["command"]
                    }
                ),
                Tool(
                    name="analyze_scene",
                    description="Analyze a Godot scene file structure",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "scene_path": {
                                "type": "string",
                                "description": "Path to the .tscn file"
                            }
                        },
                        "required": ["scene_path"]
                    }
                ),
                Tool(
                    name="send_to_godot",
                    description="Send data to running Godot instance via HTTP",
                    inputSchema={
                        "type": "object",
                        "properties": {
                            "endpoint": {
                                "type": "string",
                                "description": "HTTP endpoint path",
                                "default": "/mcp-data"
                            },
                            "data": {
                                "type": "object",
                                "description": "JSON data to send to Godot"
                            },
                            "port": {
                                "type": "integer",
                                "description": "Port number for Godot HTTP server",
                                "default": 8080
                            }
                        },
                        "required": ["data"]
                    }
                )
            ]
        
        @self.server.call_tool()
        async def call_tool(name: str, arguments: Dict[str, Any]) -> List[TextContent]:
            """Execute Godot development tools"""
            
            if name == "set_godot_project":
                path = arguments["path"]
                if os.path.exists(path) and os.path.isdir(path):
                    self.godot_project_path = path
                    return [TextContent(
                        type="text", 
                        text=f"Godot project path set to: {path}"
                    )]
                else:
                    return [TextContent(
                        type="text", 
                        text=f"Error: Path {path} does not exist or is not a directory"
                    )]
            
            elif name == "create_gdscript":
                return await self._create_gdscript(arguments)
            
            elif name == "run_godot_command":
                return await self._run_godot_command(arguments)
            
            elif name == "analyze_scene":
                return await self._analyze_scene(arguments)
            
            elif name == "send_to_godot":
                return await self._send_to_godot(arguments)
            
            else:
                return [TextContent(
                    type="text", 
                    text=f"Unknown tool: {name}"
                )]
    
    def _get_project_structure(self) -> str:
        """Get the current project structure as JSON"""
        if not self.godot_project_path:
            return json.dumps({"error": "No project path set"})
        
        structure = {}
        try:
            for root, dirs, files in os.walk(self.godot_project_path):
                rel_path = os.path.relpath(root, self.godot_project_path)
                if rel_path == ".":
                    rel_path = "root"
                structure[rel_path] = {
                    "directories": dirs,
                    "files": files
                }
        except Exception as e:
            return json.dumps({"error": str(e)})
        
        return json.dumps(structure, indent=2)
    
    def _get_scene_files(self) -> str:
        """Get all .tscn scene files"""
        if not self.godot_project_path:
            return json.dumps({"error": "No project path set"})
        
        scenes = []
        try:
            for root, dirs, files in os.walk(self.godot_project_path):
                for file in files:
                    if file.endswith('.tscn'):
                        full_path = os.path.join(root, file)
                        rel_path = os.path.relpath(full_path, self.godot_project_path)
                        scenes.append({
                            "name": file,
                            "path": rel_path,
                            "full_path": full_path
                        })
        except Exception as e:
            return json.dumps({"error": str(e)})
        
        return json.dumps({"scenes": scenes}, indent=2)
    
    def _get_script_files(self) -> str:
        """Get all .gd script files"""
        if not self.godot_project_path:
            return json.dumps({"error": "No project path set"})
        
        scripts = []
        try:
            for root, dirs, files in os.walk(self.godot_project_path):
                for file in files:
                    if file.endswith('.gd'):
                        full_path = os.path.join(root, file)
                        rel_path = os.path.relpath(full_path, self.godot_project_path)
                        scripts.append({
                            "name": file,
                            "path": rel_path,
                            "full_path": full_path
                        })
        except Exception as e:
            return json.dumps({"error": str(e)})
        
        return json.dumps({"scripts": scripts}, indent=2)
    
    async def _create_gdscript(self, arguments: Dict[str, Any]) -> List[TextContent]:
        """Create a new GDScript file"""
        filename = arguments["filename"]
        content = arguments["content"]
        path = arguments.get("path", "")
        
        if not self.godot_project_path:
            return [TextContent(type="text", text="Error: No project path set")]
        
        if not filename.endswith('.gd'):
            filename += '.gd'
        
        full_path = os.path.join(self.godot_project_path, path, filename)
        
        try:
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, 'w') as f:
                f.write(content)
            return [TextContent(
                type="text", 
                text=f"GDScript file created: {full_path}"
            )]
        except Exception as e:
            return [TextContent(type="text", text=f"Error creating file: {str(e)}")]
    
    async def _run_godot_command(self, arguments: Dict[str, Any]) -> List[TextContent]:
        """Execute Godot editor commands"""
        command = arguments["command"]
        args = arguments.get("args", [])
        
        try:
            # Try to find Godot executable
            godot_exec = self._find_godot_executable()
            if not godot_exec:
                return [TextContent(
                    type="text", 
                    text="Error: Godot executable not found in PATH"
                )]
            
            full_command = [godot_exec, command] + args
            if self.godot_project_path:
                full_command.extend(["--path", self.godot_project_path])
            
            result = subprocess.run(
                full_command,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            output = f"Command: {' '.join(full_command)}\n"
            output += f"Return code: {result.returncode}\n"
            output += f"Output: {result.stdout}\n"
            if result.stderr:
                output += f"Error: {result.stderr}\n"
            
            return [TextContent(type="text", text=output)]
            
        except subprocess.TimeoutExpired:
            return [TextContent(type="text", text="Error: Command timed out")]
        except Exception as e:
            return [TextContent(type="text", text=f"Error: {str(e)}")]
    
    async def _analyze_scene(self, arguments: Dict[str, Any]) -> List[TextContent]:
        """Analyze a Godot scene file"""
        scene_path = arguments["scene_path"]
        
        if not self.godot_project_path:
            return [TextContent(type="text", text="Error: No project path set")]
        
        full_path = os.path.join(self.godot_project_path, scene_path)
        
        if not os.path.exists(full_path):
            return [TextContent(type="text", text=f"Error: Scene file not found: {full_path}")]
        
        try:
            with open(full_path, 'r') as f:
                content = f.read()
            
            # Simple scene analysis
            analysis = {
                "file": scene_path,
                "nodes": [],
                "resources": [],
                "connections": []
            }
            
            lines = content.split('\n')
            for line in lines:
                line = line.strip()
                if line.startswith('[node'):
                    analysis["nodes"].append(line)
                elif line.startswith('[resource'):
                    analysis["resources"].append(line)
                elif line.startswith('[connection'):
                    analysis["connections"].append(line)
            
            return [TextContent(
                type="text", 
                text=json.dumps(analysis, indent=2)
            )]
            
        except Exception as e:
            return [TextContent(type="text", text=f"Error analyzing scene: {str(e)}")]
    
    async def _send_to_godot(self, arguments: Dict[str, Any]) -> List[TextContent]:
        """Send data to running Godot instance via HTTP"""
        endpoint = arguments.get("endpoint", "/mcp-data")
        data = arguments["data"]
        port = arguments.get("port", 8080)
        
        try:
            import aiohttp
            
            async with aiohttp.ClientSession() as session:
                url = f"http://localhost:{port}{endpoint}"
                async with session.post(url, json=data) as response:
                    response_text = await response.text()
                    
                    return [TextContent(
                        type="text",
                        text=f"Sent to Godot ({response.status}): {response_text}"
                    )]
                    
        except ImportError:
            return [TextContent(
                type="text",
                text="Error: aiohttp not installed. Run: pip install aiohttp"
            )]
        except Exception as e:
            return [TextContent(
                type="text",
                text=f"Error sending to Godot: {str(e)}"
            )]
    
    def _find_godot_executable(self) -> Optional[str]:
        """Find Godot executable in system PATH"""
        import shutil
        
        # Common Godot executable names
        possible_names = ['godot', 'godot4', 'Godot', 'Godot_v4.0-stable_linux.x86_64']
        
        for name in possible_names:
            path = shutil.which(name)
            if path:
                return path
        
        return None
    
    async def run(self):
        """Run the MCP server"""
        try:
            async with stdio_server() as streams:
                await self.server.run(
                    streams[0], streams[1], 
                    self.server.create_initialization_options()
                )
        except Exception as e:
            logger.error(f"Error running MCP server: {e}")
            raise

async def main():
    """Main entry point"""
    server = GodotMCPServer()
    await server.run()

if __name__ == "__main__":
    asyncio.run(main())
