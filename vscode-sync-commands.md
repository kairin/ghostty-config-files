# VS Code Settings Sync Commands Reference

## Setup Commands (Run in Command Palette Ctrl+Shift+P):

### Initial Setup:
1. `Settings Sync: Turn Off` - Reset sync completely
2. `Profiles: Show Profiles` - Check/delete extra profiles
3. `Settings Sync: Turn On` - Enable sync with GitHub
4. `Settings Sync: Configure` - Choose what to sync

### Daily Use:
- `Settings Sync: Sync Now` - Force sync
- `Settings Sync: Show Settings` - Check sync status
- `Settings Sync: Show Log` - View sync activity

### Troubleshooting:
- `Settings Sync: Reset Local` - Clear local sync data
- `Settings Sync: Reset Remote` - Clear cloud sync data
- `Developer: Reload Window` - Restart VS Code

## Settings to Enable in Configure:
✅ Settings (user settings.json)
✅ Keybindings (custom shortcuts)  
✅ Extensions (all installed extensions)
✅ User Snippets (code templates)
✅ UI State (workbench layout)

## Key Settings (add to settings.json):
```json
{
    "settingsSync.keybindingsPerPlatform": false,
    "settingsSync.ignoredExtensions": [],
    "settingsSync.ignoredSettings": [],
    "extensions.autoUpdate": true
}
```
