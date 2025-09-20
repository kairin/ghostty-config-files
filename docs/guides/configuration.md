# Configuration Guide

## Ghostty Configuration

### Core Settings
The main Ghostty configuration is located at `~/.config/ghostty/config` and includes:

- **Performance Optimizations**: Linux CGroup single-instance mode
- **Shell Integration**: Auto-detection with enhanced features
- **Theme Management**: Automatic light/dark mode switching
- **Memory Management**: Optimized scrollback limits

### Configuration Files Structure
```
configs/
├── ghostty/
│   ├── config              # Main configuration with 2025 optimizations
│   ├── theme.conf         # Auto-switching themes (Catppuccin)
│   ├── scroll.conf        # Scrollback and memory settings
│   ├── layout.conf        # Font, padding, layout optimizations
│   └── keybindings.conf   # Productivity keybindings
```

### Customization Preservation
All user customizations are automatically preserved during updates through:
- Intelligent diff detection
- Backup creation before changes
- Selective application of new features
- User setting restoration

## Development Configuration

### TypeScript Configuration
- Strict mode enabled for constitutional compliance
- Path mapping for modular architecture
- Performance optimizations enabled

### Astro Configuration
- Static site generation for optimal performance
- Tailwind CSS integration
- TypeScript support with strict validation

### Performance Targets
- Lighthouse Performance: 95+
- JavaScript Bundle: <100KB
- CSS Bundle: <20KB
- Build Time: <30 seconds
