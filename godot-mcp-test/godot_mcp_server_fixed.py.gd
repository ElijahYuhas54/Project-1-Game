#!/usr/bin/env python3
"""
Fixed HTTP-based MCP Server for Godot 4 Integration
Handles file extensions properly
"""

import asyncio
import json
import logging
import os
from pathlib import Path
from typing import Dict, Any

try:
    from aiohttp import web
except ImportError:
    print("aiohttp not found. Install with: pip install aiohttp")
    exit(1)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("godot-mcp-fixed")

class FixedGodotMCPServer:
    def __init__(self, port: int = 8082):
        self.port = port
        self.godot_project_path = ""
        self.app = web.Application()
        self.setup_routes()
    
    def setup_routes(self):
        """Setup HTTP routes"""
        self.app.router.add_get("/status", self.status)
        self.app.router.add_post("/set-project", self.set_project)
        self.app.router.add_post("/create-file", self.create_file)  # New endpoint
        self.app.router.add_post("/from-godot", self.receive_from_godot)
        self.app.middlewares.append(self.cors_handler)
    
    @web.middleware
    async def cors_handler(self, request, handler):
        """Handle CORS"""
        response = await handler(request)
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type"
        return response
    
    async def status(self, request):
        """Server status"""
        return web.json_response({
            "status": "active",
            "server": "Fixed Godot MCP Server",
            "port": self.port,
            "project_path": self.godot_project_path
        })
    
    async def set_project(self, request):
        """Set project path"""
        data = await request.json()
        path = data.get("path", "")
        
        if os.path.exists(path):
            self.godot_project_path = path
            return web.json_response({"success": True, "message": f"Project set to: {path}"})
        else:
            return web.json_response({"success": False, "error": "Path not found"}, status=400)
    
    async def create_file(self, request):
        """Create file with proper extension"""
        try:
            data = await request.json()
            filename = data.get("filename", "")
            content = data.get("content", "")
            subdir = data.get("path", "")
            
            if not self.godot_project_path:
                return web.json_response({"success": False, "error": "No project path set"}, status=400)
            
            # Create full path
            if subdir:
                full_path = os.path.join(self.godot_project_path, subdir, filename)
                os.makedirs(os.path.join(self.godot_project_path, subdir), exist_ok=True)
            else:
                full_path = os.path.join(self.godot_project_path, filename)
            
            # Write file with exact filename (no extra .gd extension)
            with open(full_path, "w", encoding="utf-8") as f:
                f.write(content)
            
            logger.info(f"Created file: {full_path}")
            return web.json_response({
                "success": True,
                "message": f"File created: {filename}",
                "path": full_path
            })
            
        except Exception as e:
            logger.error(f"Error creating file: {e}")
            return web.json_response({"success": False, "error": str(e)}, status=500)
    
    async def receive_from_godot(self, request):
        """Receive data from Godot"""
        data = await request.json()
        logger.info(f"Received from Godot: {data}")
        return web.json_response({"received": True, "message": "Data processed"})
    
    async def start_server(self):
        """Start the server"""
        runner = web.AppRunner(self.app)
        await runner.setup()
        
        site = web.TCPSite(runner, "localhost", self.port)
        await site.start()
        
        logger.info(f"Fixed Godot MCP Server started on http://localhost:{self.port}")
        return runner

async def main():
    server = FixedGodotMCPServer()
    runner = await server.start_server()
    
    try:
        while True:
            await asyncio.sleep(1)
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        await runner.cleanup()

if __name__ == "__main__":
    asyncio.run(main())
