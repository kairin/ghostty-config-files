# 🚀 One-Line VS Code Setup Commands (wget version)

## Quick Commands for Any Device

### **Instant Setup (Current Directory)**
```bash
mkdir -p .vscode && wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/template-settings.json -O .vscode/settings.json && wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/.vscode/extensions.json -O .vscode/extensions.json && echo "✅ VS Code workspace configured!"
```

### **Download Setup Script and Run**
```bash
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/quick-setup-wget.sh && chmod +x quick-setup-wget.sh && ./quick-setup-wget.sh quick
```

### **Setup All Projects in Directory**
```bash
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/quick-setup-wget.sh && chmod +x quick-setup-wget.sh && ./quick-setup-wget.sh setup-all ~/Projects
```

## 🔧 Advanced Options

### **With Progress and Verbose Output**
```bash
# Create .vscode directory
mkdir -p .vscode

# Download settings with progress
wget -c --progress=bar:force https://raw.githubusercontent.com/kairin/ghostty-config-files/main/template-settings.json -O .vscode/settings.json

# Download extensions with progress  
wget -c --progress=bar:force https://raw.githubusercontent.com/kairin/ghostty-config-files/main/.vscode/extensions.json -O .vscode/extensions.json

echo "✅ Setup complete! Open VS Code and install recommended extensions."
```

### **Resume Interrupted Downloads**
If a download is interrupted, just run the same `wget -c` command again - it will resume from where it left off!

### **Download All Template Files**
```bash
# Create templates directory
mkdir -p vscode-templates && cd vscode-templates

# Download all files
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/template-settings.json
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/.vscode/extensions.json
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/sync-workspaces.sh
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/quick-setup-wget.sh
chmod +x *.sh

echo "✅ All templates downloaded to vscode-templates/"
```

## 🌟 Why wget -c?

- **Resume Support**: `-c` continues partial downloads
- **Reliability**: Better handling of network interruptions  
- **Progress**: Shows download progress by default
- **Availability**: Installed on most Linux systems
- **Efficiency**: Only downloads what's needed

## 📋 Copy-Paste Ready Commands

Choose the command that fits your needs:

**Just the essentials:**
```bash
mkdir -p .vscode && wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/template-settings.json -O .vscode/settings.json && wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/.vscode/extensions.json -O .vscode/extensions.json
```

**With automation script:**
```bash
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/quick-setup-wget.sh && chmod +x quick-setup-wget.sh && ./quick-setup-wget.sh quick
```

**For multiple projects:**
```bash
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/quick-setup-wget.sh && chmod +x quick-setup-wget.sh && ./quick-setup-wget.sh setup-all ~/Projects
```
