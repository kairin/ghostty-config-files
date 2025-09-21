#!/usr/bin/env python3
"""
Simple static server that mounts the repository `docs/` directory
at the path prefix `/ghostty-config-files` so local preview matches
the GitHub Pages base path.

Usage: python3 scripts/serve_with_base.py [port]
"""
import sys
import os
from http.server import SimpleHTTPRequestHandler, HTTPServer
from functools import partial


class BasePathHandler(SimpleHTTPRequestHandler):
    # Inherit behavior from SimpleHTTPRequestHandler; we'll set directory via partial
    def translate_path(self, path):
        # Map requests starting with /ghostty-config-files to files under the docs/ directory
        base_prefix = '/ghostty-config-files'
        if path == '/' or path == '':
            # Redirect root to the base prefix index
            path = base_prefix + '/'
        if path.startswith(base_prefix):
            rel = path[len(base_prefix):]
            if rel == '' or rel == '/':
                rel = '/index.html'
        else:
            # For any other path, serve a 404 by mapping to a non-existent file
            rel = '/__not_found__'

        # Use the handler's directory attribute (set via partial) as the docs root
        docs_root = os.path.abspath(self.directory)
        # Prevent path traversal
        rel_path = os.path.normpath(rel).lstrip(os.sep)
        full_path = os.path.join(docs_root, rel_path)
        return full_path


def run(port=3000):
    docs_dir = os.path.join(os.getcwd(), 'docs')
    if not os.path.isdir(docs_dir):
        print(f"Error: docs/ directory not found at {docs_dir}")
        sys.exit(1)

    handler_class = partial(BasePathHandler, directory=docs_dir)
    server = HTTPServer(('0.0.0.0', port), handler_class)
    print(f"Serving docs/ at http://0.0.0.0:{port}/ghostty-config-files/")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Shutting down server")
        server.server_close()


if __name__ == '__main__':
    port = 3000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            pass
    run(port)
