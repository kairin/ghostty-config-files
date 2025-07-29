# VS Code Profile Fix Instructions

## Problem
You mentioned that sync settings restored an old version and functions are gone. This usually happens when:
- Multiple profiles exist and sync is confused
- Wrong account is being used for sync
- Sync data got corrupted

## Solution: Reset to Single Default Profile

### Step 1: Check Current Profiles
1. Open VS Code
2. Press `Ctrl+Shift+P`
3. Type "Profiles: Show Profiles"
4. Note how many profiles you have

### Step 2: Reset to Default Profile
1. Press `Ctrl+Shift+P`
2. Type "Profiles: Switch Profile"
3. Select "Default"
4. Delete any other profiles you don't need

### Step 3: Reset Settings Sync
1. Press `Ctrl+Shift+P`
2. Type "Settings Sync: Turn Off"
3. Confirm to turn off
4. Type "Settings Sync: Turn On"
5. Sign in with your preferred account
6. Choose "Replace Local" to get cloud settings OR "Merge" to combine

### Step 4: Verify Sync Settings
1. Press `Ctrl+Shift+P`
2. Type "Settings Sync: Show Settings"
3. Ensure ALL items are checked:
   - ✅ Settings
   - ✅ Keybindings
   - ✅ Extensions
   - ✅ User Snippets
   - ✅ UI State

### Step 5: Force Sync
1. Make a small change (like change theme)
2. Press `Ctrl+Shift+P`
3. Type "Settings Sync: Sync Now"
4. Verify sync works

## If Sync Still Has Issues

### Option A: Manual Restore
1. Use the extracted settings from this tool
2. Copy `merged-complete-settings.json` to `.vscode/settings.json`
3. Install extensions from `complete-extensions.json`

### Option B: Fresh Start
1. Turn off Settings Sync
2. Backup your current settings (this tool does that)
3. Reset VS Code settings to default
4. Turn on Settings Sync as fresh start
5. Manually restore important settings
