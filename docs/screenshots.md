---
title: "Screenshots Gallery"
description: "Complete visual documentation of the Ghostty installation process"
layout: default
---

# 📸 Screenshots Gallery

Complete visual documentation of the Ghostty terminal installation and configuration process. All screenshots are captured as SVG files, preserving text clarity and enabling perfect scaling.

## 🎯 Why SVG Screenshots?

Our screenshots use SVG (Scalable Vector Graphics) format because:

- **📝 Text Preservation**: All terminal text remains selectable and searchable
- **🎨 Perfect Quality**: Vector graphics scale without any quality loss
- **♿ Accessibility**: Screen readers can access all text content
- **🔍 Searchable**: Find specific commands or output in screenshots
- **📱 Responsive**: Perfect display on any device or zoom level

## 📋 Installation Stages

*This gallery will be automatically populated with screenshots captured during your installation.*

<!-- Screenshots will be dynamically inserted here by the screenshot capture system -->

<div id="screenshots-gallery">
  <p style="text-align: center; padding: 2rem; background: #f8f9fa; border-radius: 8px; margin: 2rem 0;">
    📸 Screenshots will appear here after running the installation script.<br>
    <strong>Run <code>./start.sh</code> to generate your installation gallery!</strong>
  </p>
</div>

## 🔧 Manual Screenshot Capture

You can also capture screenshots manually during your installation:

```bash
# Capture a single screenshot
./scripts/svg_screenshot_capture.sh capture "Stage Name" "Description"

# Capture both screenshot and terminal state
./scripts/svg_screenshot_capture.sh both "Build Process" "Zig compilation in progress"

# Generate documentation after manual captures
./scripts/svg_screenshot_capture.sh generate-docs
```

## 📊 Technical Details

### Screenshot Specifications

- **Format**: SVG (Scalable Vector Graphics)
- **Text Preservation**: 100% of terminal text retained as selectable elements
- **Quality**: Lossless vector graphics
- **Compatibility**: Works in all modern browsers and documentation systems
- **File Size**: Typically 50-200KB per screenshot (much smaller than equivalent PNGs)

### Capture Process

1. **Stage Detection**: Automatic identification of installation stages
2. **Display Stabilization**: 2-3 second delay for visual stability
3. **Content Capture**: Terminal output converted to SVG with preserved formatting
4. **Metadata Generation**: JSON metadata for each screenshot including timestamps
5. **Documentation Integration**: Automatic integration into GitHub Pages

### Supported Capture Tools

The system automatically detects and uses available tools:

- **termtosvg** - Native SVG terminal recording (preferred)
- **asciinema + svg-term** - Terminal session to SVG conversion
- **gnome-screenshot + conversion** - Fallback PNG to SVG embedding
- **Custom terminal-to-SVG** - Built-in text-based SVG generation

## 📁 Asset Organization

Screenshots are organized in the following structure:

```
docs/assets/screenshots/
├── YYYYMMDD-HHMMSS/          # Session timestamp
│   ├── screenshot_001_*.svg   # Ordered screenshots
│   ├── screenshot_002_*.svg
│   ├── metadata.json         # Screenshot index and metadata
│   └── terminal_state_*.txt  # Terminal state captures
├── latest/                   # Symlink to most recent session
└── index.json               # Global screenshots index
```

## 🔗 Integration with GitHub Pages

Screenshots are automatically integrated into:

- **Installation Guide**: Step-by-step visual walkthrough
- **This Gallery**: Complete screenshot collection
- **README.md**: Key screenshots embedded in repository documentation
- **GitHub Releases**: Screenshot assets attached to releases

## 📱 Responsive Design

Screenshots automatically adapt to different screen sizes:

- **Desktop**: Full-size display with modal zoom
- **Tablet**: Optimized grid layout
- **Mobile**: Single-column responsive layout
- **Print**: High-quality vector output

## 🎬 Animation Support

For dynamic content, the system can capture:

- **Static SVG**: Single moment captures (default)
- **Animated SVG**: Multi-frame animations for build processes
- **Terminal Sessions**: Complete interaction recordings

---

<div style="text-align: center; margin: 2rem 0;">
  <strong>Ready to generate your installation gallery?</strong><br>
  <a href="../installation/" style="display: inline-block; margin-top: 1rem; padding: 0.75rem 1.5rem; background: #007bff; color: white; text-decoration: none; border-radius: 6px;">🚀 Start Installation</a>
</div>

<style>
/* Gallery-specific styles */
.screenshots-gallery {
  margin: 2rem 0;
}

.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 2rem;
  margin: 2rem 0;
}

.gallery-item {
  background: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 12px;
  padding: 1.5rem;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.gallery-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.1);
}

.screenshot-container {
  margin: 1rem 0;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  cursor: zoom-in;
}

.screenshot-container img,
.screenshot-container svg {
  width: 100%;
  height: auto;
  display: block;
}

.screenshot-meta {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #dee2e6;
  font-size: 0.9rem;
  color: #6c757d;
}

.screenshot-meta strong {
  color: #495057;
}

@media (max-width: 768px) {
  .gallery-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .gallery-item {
    padding: 1rem;
  }
}
</style>
