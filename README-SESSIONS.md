# 📋 Session Management & Screenshot Tracking

The Ghostty installation system now includes comprehensive session tracking that synchronizes logs and screenshots across multiple executions.

## 🎯 Key Features

### ✅ **Fully Automatic Operation**
- User only needs to run: `./start.sh`
- No flags, environment variables, or manual setup required
- All dependencies managed automatically via uv + system packages

### 🔄 **Multi-Execution Tracking**
- Each run gets a unique session ID: `YYYYMMDD-HHMMSS-TERMINAL-install`
- Terminal auto-detection (ghostty, ptyxis, gnome-terminal, etc.)
- Perfect log-to-screenshot mapping
- Cross-session comparison and management

### 📸 **Synchronized Assets**
- Screenshots and logs use identical session IDs
- Organized in proper subfolders for GitHub Pages
- SVG format preserves text, emojis, and formatting
- Automatic documentation website generation

## 📁 File Organization

```
Installation Data Structure:
├── /tmp/ghostty-start-logs/                    # All session logs
│   ├── 20250921-143000-ghostty-install.log     # Human-readable log
│   ├── 20250921-143000-ghostty-install.json    # Structured JSON log
│   ├── 20250921-143000-ghostty-install-errors.log
│   ├── 20250921-143000-ghostty-install-performance.json
│   └── 20250921-143000-ghostty-install-manifest.json  # Complete session metadata
│
└── docs/assets/screenshots/                    # All session screenshots
    ├── 20250921-143000-ghostty-install/        # Screenshots for specific session
    │   ├── screenshot_001_initial_desktop.svg
    │   ├── screenshot_002_system_check.svg
    │   ├── metadata.json                       # Screenshot index
    │   └── ... (12+ installation stage screenshots)
    │
    └── 20250921-150000-ptyxis-install/         # Different session/terminal
        ├── screenshot_001_initial_desktop.svg
        └── ...
```

## 🏷️ Session ID Format

**Pattern:** `YYYYMMDD-HHMMSS-TERMINAL-install`

**Terminal Detection:**
- `ghostty` - Running in Ghostty terminal
- `ptyxis` - Running in Ptyxis terminal
- `gnome-terminal` - Running in GNOME Terminal
- `konsole` - Running in KDE Konsole
- `generic` - Other/unknown terminal

**Examples:**
- `20250921-143000-ghostty-install` - Ghostty terminal at 2:30 PM
- `20250921-150000-ptyxis-install` - Ptyxis terminal at 3:00 PM

## 🛠️ Session Management Commands

### List All Sessions
```bash
./scripts/session_manager.sh list
```

### View Session Details
```bash
./scripts/session_manager.sh show 20250921-143000-ghostty-install
```

### Compare Sessions
```bash
./scripts/session_manager.sh compare
```

### Clean Up Old Sessions (keep last 5)
```bash
./scripts/session_manager.sh cleanup 5
```

### Export Session Data
```bash
./scripts/session_manager.sh export 20250921-143000-ghostty-install
```

## 📊 Session Manifest Example

Each session generates a complete manifest with metadata:

```json
{
  "session_id": "20250921-143000-ghostty-install",
  "datetime": "20250921-143000",
  "terminal_detected": "ghostty",
  "session_type": "install",
  "created": "2025-09-21T14:30:00Z",
  "machine_info": {
    "hostname": "ubuntu-desktop",
    "user": "developer",
    "os": "Ubuntu 25.04 LTS",
    "kernel": "6.14.0-29-generic",
    "shell": "/bin/zsh",
    "display": ":0",
    "wayland": "wayland-0"
  },
  "terminal_environment": {
    "detected_terminal": "ghostty",
    "term_program": "ghostty",
    "ghostty_resources": "/usr/local/share/ghostty"
  },
  "statistics": {
    "total_stages": 12,
    "screenshots_captured": 12,
    "errors_encountered": 0,
    "duration_seconds": 247
  },
  "stages": [
    {
      "name": "Initial Desktop",
      "type": "installation",
      "timestamp": "2025-09-21T14:30:15Z",
      "screenshot_expected": true
    }
  ]
}
```

## 🎯 Usage Scenarios

### **Scenario 1: Regular Installation**
```bash
# User runs installation
./start.sh

# System automatically:
# ✅ Detects running in Ghostty terminal
# ✅ Creates session: 20250921-143000-ghostty-install
# ✅ Captures 12+ screenshots at key stages
# ✅ Generates synchronized logs
# ✅ Builds documentation website
```

### **Scenario 2: Multiple Executions**
```bash
# First run in Ghostty
./start.sh  # → 20250921-143000-ghostty-install

# Later run in Ptyxis
./start.sh  # → 20250921-150000-ptyxis-install

# View all sessions
./scripts/session_manager.sh list

# Compare performance
./scripts/session_manager.sh compare
```

### **Scenario 3: Troubleshooting**
```bash
# Installation had issues
./scripts/session_manager.sh show 20250921-143000-ghostty-install

# View specific logs
cat /tmp/ghostty-start-logs/20250921-143000-ghostty-install-errors.log

# View screenshots
ls docs/assets/screenshots/20250921-143000-ghostty-install/
```

## 📸 Screenshot Features

### **SVG Format Benefits:**
- **📝 Text Preservation**: All terminal text remains selectable and searchable
- **🎨 Perfect Quality**: Vector graphics scale without quality loss
- **♿ Accessibility**: Screen readers can access all text content
- **🔍 Searchable**: Find specific commands or output in screenshots
- **📱 Responsive**: Perfect display on any device

### **Automatic Capture Stages:**
1. Initial Desktop
2. System Check
3. Dependencies Installation
4. ZSH Setup
5. Modern Tools
6. Zig Compiler
7. Ghostty Build
8. Configuration
9. Context Menu
10. AI Tools Integration
11. Verification
12. Completion

## 🌐 GitHub Pages Integration

All sessions automatically contribute to the documentation website:

- **Homepage**: Overview and quick start
- **Installation Guide**: Step-by-step with screenshots
- **Screenshots Gallery**: All captured sessions
- **Session Browser**: Navigate between different executions

## 🔧 Technical Implementation

### **Dependencies (Automatic)**
- **uv**: Python package management for screenshot tools
- **Node.js**: Astro.build website generation
- **System Tools**: gnome-screenshot, scrot, imagemagick, librsvg2-bin
- **Python Tools**: termtosvg, asciinema, svg-term, jinja2

### **Zero Configuration**
- Auto-detects GUI environment
- Auto-installs all dependencies via uv
- Auto-creates proper directory structure
- Auto-generates documentation website
- Auto-maps logs to screenshots

---

**🎯 Bottom Line**: Just run `./start.sh` and get complete visual documentation automatically!