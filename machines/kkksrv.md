# kkksrv - Home Desktop (AI Workstation)

> Last Updated: 2025-12-17

## Hardware

| Component | Model | Notes |
|-----------|-------|-------|
| **Motherboard** | MSI MAG B650 TOMAHAWK WIFI (MS-7D75) | AM5 socket |
| **CPU** | AMD Ryzen 7 7700 (8C/16T @ 5.39GHz) | Zen 4, integrated GPU |
| **GPU (Discrete)** | NVIDIA GeForce RTX 5090 (32GB) | Blackwell GB202, 600W TDP |
| **GPU (Integrated)** | AMD Raphael | Handles display output |
| **RAM** | 64GB DDR5 | ~61GB usable |
| **Storage** | Multiple drives | See `lsblk` for current layout |

## Operating System

- **OS**: Ubuntu 25.10 (Questing Quokka)
- **Kernel**: 6.17.0-8-generic
- **Desktop**: GNOME 49.0 (Wayland via Mutter)

## GPU Configuration

### Display Setup
- **Primary display**: AMD Raphael iGPU (amdgpu driver)
- **NVIDIA GPU**: Dedicated to compute only (no display attached)
- **Reason**: 100% of RTX 5090 VRAM/compute for AI workloads

### NVIDIA Driver (CRITICAL)

**RTX 5090 (Blackwell) REQUIRES open-source kernel modules!**

| Package | Version | Status |
|---------|---------|--------|
| `nvidia-driver-580-open` | 580.95.05 | Required |
| `nvidia-dkms-580-open` | 580.95.05 | Required |

**DO NOT USE**: `nvidia-dkms-580` (closed-source) - Will fail with error:
```
NVRM: installed in this system requires use of the NVIDIA open kernel modules.
NVRM: GPU 0000:01:00.0: RmInitAdapter failed! (0x22:0x56:884)
```

### Verification Commands
```bash
# Check nvidia-smi works
nvidia-smi

# Verify open modules (should show "Dual MIT/GPL", NOT "NVIDIA")
modinfo nvidia | grep license

# Verify display on AMD
glxinfo | grep "OpenGL renderer"
```

## Known Issues & Solutions

### Issue: nvidia-smi says "No devices found"

**Symptom**: GPU visible in `lspci` and `fastfetch` but nvidia-smi fails

**Cause**: Closed-source nvidia modules installed instead of open-source

**Solution**:
```bash
# Remove closed-source modules
sudo apt remove nvidia-dkms-580

# Install open-source modules
sudo apt install nvidia-dkms-580-open nvidia-driver-580-open

# Reboot
sudo reboot
```

### Issue: AWS kernel packages pulled in during nvidia install

**Symptom**: `linux-modules-nvidia-580-6.17.0-*-aws` packages fail to configure

**Cause**: APT dependency resolution pulls unnecessary AWS kernel variants

**Solution**:
```bash
# Remove all AWS kernel packages
sudo apt remove --purge linux-modules-nvidia-580-aws \
    linux-modules-nvidia-580-6.17.0-*-aws \
    linux-objects-nvidia-580-6.17.0-*-aws \
    linux-image-6.17.0-*-aws \
    linux-modules-6.17.0-*-aws

# Fix dpkg state
sudo dpkg --configure -a
```

## AI/ML Environment

### CUDA
- **Version**: 13.0
- **Compute Capability**: (check with `nvidia-smi --query-gpu=compute_cap --format=csv`)

### Environment Variables (recommended for ~/.zshrc)
```bash
export CUDA_VISIBLE_DEVICES=0
```

## Maintenance Notes

- Keep `nvidia-driver-580-open` packages updated
- After kernel updates, verify DKMS rebuilds nvidia modules: `dkms status | grep nvidia`
- Monitor with: `nvidia-smi --query-gpu=temperature.gpu,power.draw,memory.used --format=csv -l 1`
