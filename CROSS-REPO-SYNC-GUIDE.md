# 🔄 Cross-Repository VS Code Settings Sync Guide

## 📝 **Your Situation:**
You opened a new VS Code window with another repository and want to ensure any new MCP apps, extensions, or settings used there get reflected in your template repository.

## 🚀 **Quick Solution:**

### **Option 1: Automatic Sync (Recommended)**
When you're done working in the other repository and have installed new MCP apps or extensions:

```bash
# Navigate to your template repository
cd /home/kkk/Apps/ghostty-config-files

# Capture all current VS Code settings and extensions from ANY workspace
./cross-repo-sync.sh capture

# Commit the changes to your template repository
./cross-repo-sync.sh commit
```

### **Option 2: Complete Workflow**
```bash
# Run the complete sync process (capture + apply + commit)
cd /home/kkk/Apps/ghostty-config-files
./cross-repo-sync.sh full /path/to/other/repository
```

### **Option 3: One-Liner for Quick Updates**
```bash
cd /home/kkk/Apps/ghostty-config-files && ./cross-repo-sync.sh capture && ./cross-repo-sync.sh commit
```

## 🔍 **What Gets Captured:**

✅ **All VS Code Extensions** (including new MCP apps)
✅ **Global VS Code Settings** (themes, preferences, etc.)
✅ **MCP-Related Extensions** (Claude Desktop, AI tools, etc.)
✅ **Keybindings and Snippets**
✅ **Any new workspace configurations**

## 🎯 **Workflow Example:**

1. **You're working in another repo** and install a new MCP app like "Claude Desktop Integration"
2. **Run the capture command:**
   ```bash
   cd /home/kkk/Apps/ghostty-config-files
   ./cross-repo-sync.sh capture
   ```
3. **The script will:**
   - Detect the new extension
   - Update your template files
   - Show you what was found
4. **Commit the changes:**
   ```bash
   ./cross-repo-sync.sh commit
   ```
5. **Now ALL your devices** can get the new MCP app when they use your templates!

## 🔄 **Real-Time Sync Strategy:**

### **Daily Workflow:**
```bash
# Morning: Apply latest template to new project
cd /path/to/new/project
wget -c https://raw.githubusercontent.com/kairin/ghostty-config-files/main/quick-setup-wget.sh && chmod +x quick-setup-wget.sh && ./quick-setup-wget.sh quick

# Evening: Capture any new tools you installed
cd /home/kkk/Apps/ghostty-config-files
./cross-repo-sync.sh capture && ./cross-repo-sync.sh commit
```

### **When Installing New MCP Apps:**
```bash
# After installing any new extension or MCP app
cd /home/kkk/Apps/ghostty-config-files
./cross-repo-sync.sh capture
# Review what was captured, then commit
./cross-repo-sync.sh commit
```

## 📱 **Multi-Device Benefits:**

1. **Install MCP app** on your main machine
2. **Run capture** to update template repository
3. **On any other device**, run the wget setup command
4. **Instant access** to the same MCP apps and settings!

## 🔧 **Advanced Usage:**

```bash
# Just capture without committing (to review first)
./cross-repo-sync.sh capture

# Apply template to specific workspace
./cross-repo-sync.sh apply /path/to/other/project

# Sync settings and apply to current directory
./cross-repo-sync.sh sync

# Complete workflow with custom path
./cross-repo-sync.sh full /path/to/project
```

## 🎉 **Result:**

Your template repository becomes a **living sync hub** that automatically captures and distributes:
- New MCP applications
- AI tools and extensions
- Development environment updates
- Settings and configuration changes

**No manual copying required!** 🚀
