# Machine Profiles

This directory contains hardware profiles and configuration notes for various machines running this configuration.

## Purpose

- Document hardware-specific quirks and solutions
- Track what driver versions work for each GPU
- Preserve troubleshooting knowledge across reinstalls
- Quick reference when setting up or fixing machines

## Machine Index

| Hostname | Location | Primary GPU | Status |
|----------|----------|-------------|--------|
| [kkksrv](kkksrv.md) | Home | RTX 5090 | Active |

## Adding a New Machine

1. Copy the template below or an existing profile
2. Name the file `{hostname}.md`
3. Fill in hardware details
4. Document any issues encountered and their solutions

### Quick Info Gathering Commands

```bash
# Hostname
hostname

# Motherboard
cat /sys/class/dmi/id/board_name /sys/class/dmi/id/board_vendor

# CPU
lscpu | grep "Model name"

# GPU(s)
lspci | grep -E "VGA|3D"

# Memory
free -h

# OS/Kernel
lsb_release -d && uname -r

# NVIDIA driver (if applicable)
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv
```

## Template

```markdown
# {hostname} - {description}

> Last Updated: YYYY-MM-DD

## Hardware

| Component | Model | Notes |
|-----------|-------|-------|
| **Motherboard** | | |
| **CPU** | | |
| **GPU** | | |
| **RAM** | | |

## Operating System

- **OS**:
- **Kernel**:
- **Desktop**:

## GPU Configuration

{Document driver requirements, display setup, etc.}

## Known Issues & Solutions

{Document any problems and fixes}
```
