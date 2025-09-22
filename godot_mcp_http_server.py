#!/usr/bin/env python3
"""
HTTP-based MCP Server for Godot 4 Integration
Provides a REST API interface for Godot to communicate with MCP functionality
"""

import asyncio
import json
import logging
import os
import subprocess
import sys
from typing import Dict, List, Any, Optional
from pathlib import Path

try:
    from aiohttp import web, ClientSession
    from aiohttp.web import Request, Response, json_response
except ImportError:
    print("aiohttp not found. Install with: pip install aiohttp")
    sys.exit(1)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("godot-mcp-http-server")

class GodotMCPHTTPServer:
    def __init__(self, port: int = 8081):
        self.port = port
        self.godot_project_path = ""
        self.app = web.Application()
        self.setup_routes()
    
    def setup_routes(self):
        """Setup HTTP routes"""
        self.app.router.add_get('/status', self.status)
        self.app.router.add_post('/set-project', self.set_project)
        self.app.router.add_get('/project-structure', self.get_project_structure)
        self.app.router.add_get('/scenes', self.get_scenes)
        self.app.router.add_get('/scripts', self.get_scripts)
        self.app.router.add_post('/create-script', self.create_script)
        self.app.router.add_post('/run-godot', self.run_godot_command)
        self.app.router.add_post('/analyze-scene', self.analyze_scene)
        self.app.router.add_post('/from-godot', self.receive_from_godot)
        
        # CORS middleware
        self.app.middlewares.append(self.cors_handler)
    
    @web.middleware
    async def cors_handler(self, request: Request, handler):
        """Handle CORS for web requests"""
        response = await handler(request)
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
        return response
    
    async def status(self, request: Request) -> Response:
        """Server status endpoint"""
        return json_response({
            "status": "active",
            "server": "Godot MCP HTTP Server",
            "project_path": self.godot_project_path,
            "has_project": bool(self.godot_project_path and os.path.exists(self.godot_project_path))
        })
    
    async def set_project(self, request: Request) -> Response:
        """Set Godot project path"""
        try:
            data = await request.json()
            path = data.get("path", "")
            
            if os.path.exists(path) and os.path.isdir(path):
                self.godot_project_path = path
                logger.info(f"Project path set to: {path}")
                return json_response({
                    "success": True,
                    "message": f"Project path set to: {path}"
                })
            else:
                return json_response({
                    "success": False,
                    "error": f"Path does not exist: {path}"
                }, status=400)
                
        except Exception as e:
            logger.error(f"Error setting project path: {e}")
            return json_response({
                "success": False,
                "error": str(e)
            }, status=500)
    
    async def get_project_structure(self, request: Request) -> Response:
        """Get project file structure"""
        if not self.godot_project_path:
            return json_response({
                "error": "No project path set"
            }, status=400)
        
        try:
            structure = {}
            for root, dirs, files in os.walk(self.godot_project_path):
                # Skip hidden directories and common ignore patterns
                dirs[:] = [d for d in dirs if not d.startswith('.') and d != '__pycache__']
                
                rel_path = os.path.relpath(root, self.godot_project_path)
                if rel_path == ".":
                    rel_path = "root"
                    
                structure[rel_path] = {
                    "directories": dirs,
                    "files": [f for f in files if not f.startswith('.')]
                }
            
            return json_response({
                "success": True,
                "structure": structure
            })
            
        except Exception as e:
            logger.error(f"Error getting project structure: {e}")
            return json_response({
                "success": False,
                "error": str(e)
            }, status=500)
    
    async def get_scenes(self, request: Request) -> Response:
        """Get all .tscn scene files"""
        if not self.godot_project_path:
            return json_response({
                "error": "No project path set"
            }, status=400)
        
        try:
            scenes = []
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
            
            return json_response({
                "success": True,
                "scenes": scenes
            })
            
        except Exception as e:
            return json_response({
                "success": False,
                "error": str(e)
            }, status=500)
    
    async def get_scripts(self, request: Request) -> Response:
        """Get all .gd script files"""
        if not self.godot_project_path:
            return json_response({
                "error": "No project path set"
            }, status=400)
        
        try:
            scripts = []
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
            
            return json_response({
                "success": True,
                "scripts": scripts
            })
            
        except Exception as e:
            return json_response({
                "success": False,
                "error": str(e)
            }, status=500)
    
    async def create_script(self, request: Request) -> Response:
        """Create a new GDScript file"""
        try:
            data = await request.json()
            filename = data.get("filename", "")
            content = data.get("content", "")
            path = data.get("path", "")
            
            if not self.godot_project_path:
                return json_response({
                    "success": False,
                    "error": "No project path set"
                }, status=400)
            
            if not filename.endswith('.gd'):
                filename += '.gd'
            
            full_path = os.path.join(self.godot_project_path, path, filename)
            
            # Create directory if it doesn't exist
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            
            with open(full_path, 'w') as f:
                f.write(content)
            
            logger.info(f"Created GDScript file: {full_path}")
            return json_response({
                "success": True,
                "message": f"GDScript file created: {full_path}",
                "path": full_path
            })
            
        except Exception as e:
            logger.error(f"Error creating script: {e}")
            return json_response({
                "success": False,
                "error": str(e)
            }, status=500)
    
    async def run_godot_command(self, request: Request) -> Response:
        """Execute Godot editor commands"""
        try:
            data = await request.json()
            command = data.get("command", "")
            args = data.get("args", [])
            
            # Find Godot executable
            godot_exec = self._find_godot_executable()
            if not godot_exec:
                return json_response({
                    "success": False,
                    "error": "Godot executable not found in PATH"
                }, status=404)
            
            full_command = [godot_exec, command] + args
            if self.godot_project_path:
                full_command.extend(["--path", self.godot_project_path])
            
            # Run command with timeout
            process = await asyncio.create_subprocess_exec(
                *full_command,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(), timeout=30.0
                )
            except asyncio.TimeoutError:
                process.kill()
                return json_response({
                    "success": False,
                    "error": "Command timed out"
                }, status=408)
            
            result = {
                "success": True,
                "command": ' '.join(full_command),
                "return_code": process.returncode,
                "stdout": stdout.decode('utf-8') if stdout else "",
                "stderr": stderr.decode('utf-8') if stderr else ""
            }
            
            return json_response(result)
            
        except Exception as e:
            logger.error(f"Error running Godot command: {e}")
            return json_response({
                "success": False,
                "error": str(e)
            }, status=500)
    
    async def analyze_scene(self, request: Request) -> Response:
        """Analyze a Godot scene file"""
        try:
            data = await request.json()
            scene_path = data.get("scene_path", "")
            
            if not self.godot_project_path:
                return json_response({
                    "success": False,
                    "error": "No project path set"
                }, status=400)
            
            full_path = os.path.join(self.godot_project_path, scene_path)
            
            if not os.path.exists(full_path):
                return json_response({
                    "success": False,
                    "error": f"Scene file not found: {full_path}"
                }, status=404)
            
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
            
            return json_response({
                "success": True,
                "analysis": analysis
            })
            
        except Exception as e:
            logger.error(f"Error analyzing scene: {e}")
            return json_response({
                "success": False,
                "error": str(e)
            }, status=500)
    
    async def receive_from_godot(self, request: Request) -> Response:
        """Receive data from Godot game"""
        try:
            data = await request.json()
            logger.info(f"Received from Godot: {data}")
            
            # Process the data based on type
            response_data = {"received": True}
            
            if data.get("type") == "game_event":
                response_data["message"] = "Game event processed"
            elif data.get("type") == "player_action":
                response_data["message"] = "Player action processed"
            elif data.get("type") == "ai_request":
                # This is where you could integrate with AI/LLM
                response_data["ai_response"] = "AI processing not yet implemented"
            
            return json_response(response_data)
            
        except Exception as e:
            logger.error(f"Error processing Godot data: {e}")
            return json_response({
                "success": False,
                "error": str(e)
            }, status=500)
    
    def _find_godot_executable(self) -> Optional[str]:
        """Find Godot executable in system PATH"""
        import shutil
        
        possible_names = ['godot', 'godot4', 'Godot', 'Godot_v4.0-stable_linux.x86_64']
        
        for name in possible_names:
            path = shutil.which(name)
            if path:
                return path
        
        return None
    
    async def start_server(self):
        """Start the HTTP server"""
        runner = web.AppRunner(self.app)
        await runner.setup()
        
        site = web.TCPSite(runner, 'localhost', self.port)
        await site.start()
        
        logger.info(f"Godot MCP HTTP Server started on http://localhost:{self.port}")
        logger.info("Available endpoints:")
        logger.info("  GET  /status - Server status")
        logger.info("  POST /set-project - Set Godot project path")
        logger.info("  GET  /project-structure - Get project structure")
        logger.info("  GET  /scenes - Get scene files")
        logger.info("  GET  /scripts - Get script files")
        logger.info("  POST /create-script - Create new GDScript")
        logger.info("  POST /run-godot - Run Godot commands")
        logger.info("  POST /analyze-scene - Analyze scene file")
        logger.info("  POST /from-godot - Receive data from Godot")
        
        return runner

async def main():
    """Main entry point"""
    server = GodotMCPHTTPServer()
    runner = await server.start_server()
    
    try:
        # Keep server running
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        logger.info("Shutting down server...")
        await runner.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
