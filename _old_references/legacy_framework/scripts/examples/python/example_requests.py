#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "requests>=2.31.0",
# ]
# ///
"""Example script using uv inline metadata for dependency management."""

import requests

def fetch_url(url: str) -> dict:
    """Fetch URL and return JSON response."""
    response = requests.get(url)
    response.raise_for_status()
    return response.json()

if __name__ == "__main__":
    result = fetch_url("https://api.github.com/repos/astral-sh/uv")
    print(f"uv repository stars: {result['stargazers_count']}")
