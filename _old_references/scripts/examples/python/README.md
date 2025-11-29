# Python Automation Examples with uv

This directory contains example Python scripts demonstrating uv package manager usage.

## Quick Start

```bash
# Run single-file script (auto-manages dependencies)
uv run example_requests.py

# Initialize project environment
uv sync

# Add new dependency
uv add pandas

# Run with specific Python version
uv run --python 3.12 example_requests.py
```

## Examples

1. **example_requests.py** - Single-file script with inline dependencies
2. **pyproject.toml** - Multi-file project configuration

## Best Practices

- Use inline script metadata for standalone scripts
- Use pyproject.toml for multi-file projects
- Specify exact Python version requirements
- Use uv.lock for reproducible environments

## Documentation

Official uv docs: https://docs.astral.sh/uv/
