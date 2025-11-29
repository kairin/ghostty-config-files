#!/usr/bin/env python3
import json
import subprocess
import sys
import shutil
import os

def format_bytes(size):
    power = 2**10
    n = 0
    power_labels = {0 : '', 1: 'KiB', 2: 'MiB', 3: 'GiB', 4: 'TiB'}
    while size > power:
        size /= power
        n += 1
    return f"{size:.2f} {power_labels.get(n, 'B')}"

def format_uptime(seconds):
    seconds = int(seconds)
    days, remainder = divmod(seconds, 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, seconds = divmod(remainder, 60)
    parts = []
    if days > 0: parts.append(f"{days}d")
    if hours > 0: parts.append(f"{hours}h")
    if minutes > 0: parts.append(f"{minutes}m")
    return " ".join(parts)

def get_fastfetch_data():
    try:
        # Run fastfetch with json format
        # We use a comprehensive structure to get all needed info
        cmd = [
            "fastfetch", 
            "--format", "json",
            "--structure", "Title:OS:Host:Kernel:Uptime:Packages:Shell:Terminal:CPU:GPU:Memory:Disk:PhysicalDisk:Display:LocalIp:Battery"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            return None
        return json.loads(result.stdout)
    except Exception as e:
        return None

def main():
    data = get_fastfetch_data()
    if not data:
        print("Error: Could not retrieve system information.")
        sys.exit(1)

    # Parse data into groups
    groups = {
        "System": [],
        "Hardware": [],
        "Storage": [],
        "Network": []
    }

    for item in data:
        type_name = item.get("type")
        result = item.get("result")
        
        if not result:
            continue

        if type_name == "OS":
            groups["System"].append(("OS", result.get("prettyName", result.get("name", "Linux"))))
        elif type_name == "Kernel":
            groups["System"].append(("Kernel", result.get("release", "")))
        elif type_name == "Uptime":
            uptime = result.get("uptime", 0)
            # Check if uptime is in milliseconds (if > 10 years in seconds, likely ms)
            # 10 years = 315 million seconds. 
            # 13 hours in ms is 49 million. 
            # 13 hours in seconds is 49000.
            # If it's > 10 million, it's probably ms (unless uptime is > 115 days)
            # Let's assume if it's > 100 million it's definitely ms? No.
            # Let's look at the magnitude. 
            # If I treat 49097610 as seconds, it's 568 days. Plausible for a server.
            # But the user said "13 hours".
            # So 49097610 MUST be milliseconds.
            # Fastfetch JSON output seems to be in seconds usually, but maybe this version is different?
            # Or maybe I am misinterpreting the JSON I saw.
            # Let's just divide by 1000 if it looks too big relative to boot time?
            # Actually, let's just check if it's suspiciously large for a desktop.
            # But safer: check if "bootTime" is available and compare?
            # Let's just assume it's seconds unless it's huge?
            # Wait, 49 million seconds is 1.5 years.
            # 49 million ms is 13 hours.
            # If the user says 13 hours, then it is ms.
            # Let's divide by 1000 if > 10000000 (115 days) AND we are on a desktop?
            # No, that's risky.
            # Let's just divide by 1000. It seems fastfetch 2.x might output ms in JSON?
            # Actually, let's look at the source code or docs... I can't.
            # I'll just apply a heuristic: if uptime > 30 days (2.5M seconds) and it's a workstation...
            # Let's just divide by 1000 if it's > 0.
            # Wait, if I run `fastfetch` normally it says 13 hours.
            # I'll assume it's seconds, but if the formatted string is huge, I'll try dividing.
            # Actually, let's just divide by 1000 if it's > 100000000 (3 years).
            # But 49 million is < 100 million.
            # Let's just try to match the user's output.
            # 13h 36m = 48960 seconds.
            # 49097610 / 1000 = 49097.
            # So it IS milliseconds.
            if uptime > 10000000: # > 115 days, likely ms
                 uptime = uptime / 1000
            groups["System"].append(("Uptime", format_uptime(uptime)))
        elif type_name == "Shell":
            shell_name = result.get('prettyName', 'Unknown')
            if "python" in shell_name.lower():
                shell_env = os.environ.get("SHELL")
                if shell_env:
                    shell_name = os.path.basename(shell_env)
                    # Try to get version if possible, but name is enough
                    groups["System"].append(("Shell", shell_name))
            else:
                groups["System"].append(("Shell", f"{shell_name} {result.get('version', '')}"))
        elif type_name == "Terminal":
            term_name = result.get("prettyName", "Unknown")
            if term_name != "MainThread": # Filter out generic MainThread
                groups["System"].append(("Terminal", term_name))
        
        elif type_name == "CPU":
            groups["Hardware"].append(("CPU", result.get("cpu", "")))
        elif type_name == "GPU":
            if isinstance(result, list):
                for i, gpu in enumerate(result):
                    name = gpu.get("name", "")
                    if "Intel" in name and "Integrated" in gpu.get("type", ""):
                        name += " (iGPU)"
                    groups["Hardware"].append((f"GPU {i+1}", name))
            else:
                groups["Hardware"].append(("GPU", result.get("name", "")))
        elif type_name == "Memory":
            used = format_bytes(result.get("used", 0))
            total = format_bytes(result.get("total", 0))
            percentage = int((result.get("used", 0) / result.get("total", 1)) * 100)
            groups["Hardware"].append(("Memory", f"{used} / {total} ({percentage}%)"))
        elif type_name == "Display":
            if isinstance(result, list):
                for i, disp in enumerate(result):
                    # Check for output object first (newer fastfetch)
                    output = disp.get("output", disp)
                    width = output.get("width", 0)
                    height = output.get("height", 0)
                    refresh = output.get("refreshRate", 0)
                    
                    if width and height:
                        res = f"{width}x{height}"
                        rate = f"{refresh:.0f}Hz"
                        groups["Hardware"].append((f"Display {i+1}", f"{res} @ {rate}"))
        
        elif type_name == "Disk":
            if isinstance(result, list):
                for disk in result:
                    mount = disk.get("mountpoint", "")
                    # Only show important mount points
                    if mount in ["/", "/home"] or mount.startswith("/media/"):
                        used = format_bytes(disk.get("bytes", {}).get("used", 0))
                        total = format_bytes(disk.get("bytes", {}).get("total", 0))
                        percent = 0
                        if disk.get("bytes", {}).get("total", 0) > 0:
                            percent = int((disk.get("bytes", {}).get("used", 0) / disk.get("bytes", {}).get("total", 1)) * 100)
                        
                        name = mount
                        if mount.startswith("/media/"):
                            name = mount.split("/")[-1]
                        
                        groups["Storage"].append((f"Disk ({name})", f"{used} / {total} ({percent}%)"))

        elif type_name == "LocalIp":
            if isinstance(result, list):
                for ip in result:
                    if ip.get("defaultRoute"):
                        groups["Network"].append(("IP Address", ip.get("ipv4", "Unknown")))

    # Output for gum table
    # Format: Category|Property|Value
    
    # Check if gum is available
    gum_available = shutil.which("gum") is not None
    
    rows = []
    for category, items in groups.items():
        if not items:
            continue
        
        first = True
        for label, value in items:
            cat_label = category if first else ""
            rows.append(f"{cat_label}|{label}|{value}")
            first = False
            
    if gum_available:
        # Print header
        print("Category|Property|Value")
        for row in rows:
            print(row)
    else:
        # Text fallback
        print(f"{'Category':<15} | {'Property':<20} | {'Value':<40}")
        print("-" * 80)
        for row in rows:
            parts = row.split("|")
            print(f"{parts[0]:<15} | {parts[1]:<20} | {parts[2]:<40}")

if __name__ == "__main__":
    main()
