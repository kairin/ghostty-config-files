# Performance Optimization Guide

## 🎯 Constitutional Performance Targets

This guide ensures all performance optimizations meet constitutional requirements for the modern web development stack.

### 📊 Performance Targets (NON-NEGOTIABLE)

#### Core Web Vitals
- **First Contentful Paint (FCP)**: <1.8 seconds
- **Largest Contentful Paint (LCP)**: <2.5 seconds
- **Cumulative Layout Shift (CLS)**: <0.1
- **First Input Delay (FID)**: <100 milliseconds
- **Interaction to Next Paint (INP)**: <200 milliseconds

#### Build Performance
- **Build Time**: <30 seconds (local development)
- **JavaScript Bundle**: <100KB (gzipped, initial load)
- **CSS Bundle**: <20KB (gzipped, critical path)
- **Image Optimization**: WebP/AVIF with fallbacks
- **Font Loading**: <500ms blocking time

#### Lighthouse Scores (Constitutional Requirement: 95+)
- **Performance**: ≥95
- **Accessibility**: ≥95
- **Best Practices**: ≥95
- **SEO**: ≥95
- **Progressive Web App**: ≥90

## 🏗️ Architecture Optimizations

### 1. Astro.build Islands Architecture

**Strategy**: Zero JavaScript by default, selective hydration only when needed.

```astro
---
// ❌ Avoid: Unnecessary client-side hydration
import InteractiveComponent from './InteractiveComponent.jsx';
---

<InteractiveComponent client:load />

---

// ✅ Preferred: Static rendering with progressive enhancement
import StaticComponent from './StaticComponent.astro';
---

<StaticComponent />
```

**Constitutional Benefits**:
- **JavaScript Bundle**: Reduced by 80-90%
- **First Load**: Immediate content display
- **Hydration Cost**: Eliminated for static content

### 2. Component Performance Patterns

**Lazy Loading Strategy**:
```astro
---
// Conditional component loading
const showAdvancedFeatures = Astro.url.searchParams.has('advanced');
---

{showAdvancedFeatures && (
  <script>
    import('./AdvancedFeatures.js').then(module => {
      module.init();
    });
  </script>
)}
```

**Bundle Splitting**:
```javascript
// astro.config.mjs
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['react', 'react-dom'],
          'ui': ['@/components/ui'],
          'utils': ['@/lib/utils']
        }
      }
    }
  }
});
```

### 3. CSS Optimization

**Critical CSS Inlining**:
```astro
---
// Layout.astro - Inline critical styles
---

<style is:inline>
  /* Critical path CSS - above-the-fold styles */
  body { margin: 0; font-family: system-ui; }
  .hero { display: flex; align-items: center; min-height: 100vh; }
</style>

<style>
  /* Non-critical CSS - loaded asynchronously */
  .footer { margin-top: 2rem; }
</style>
```

**Tailwind CSS Optimization**:
```javascript
// tailwind.config.mjs
export default {
  content: [
    './src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'
  ],
  corePlugins: {
    // Disable unused core plugins
    float: false,
    clear: false,
    skew: false,
  },
  // PurgeCSS optimization
  safelist: [
    // Keep dynamic classes
    'bg-red-500',
    'text-green-600'
  ]
};
```

## 📦 Bundle Optimization

### 1. JavaScript Bundle Analysis

**Constitutional Monitoring**:
```bash
# Analyze bundle size
npm run build
npx bundlesize

# Performance budget enforcement
echo '{
  "files": [
    {
      "path": "dist/assets/*.js",
      "maxSize": "100kb"
    },
    {
      "path": "dist/assets/*.css",
      "maxSize": "20kb"
    }
  ]
}' > .bundlesizerc.json
```

**Bundle Optimization Strategies**:
```javascript
// Astro config with optimization
export default defineConfig({
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
        pure_funcs: ['console.log']
      }
    }
  },
  vite: {
    build: {
      rollupOptions: {
        treeshake: {
          preset: 'recommended',
          pureExternalModules: true
        }
      }
    }
  }
});
```

### 2. Image Optimization

**Astro Image Integration**:
```astro
---
import { Image } from 'astro:assets';
import heroImage from '../assets/hero.jpg';
---

<!-- Constitutional image optimization -->
<Image
  src={heroImage}
  alt="Hero image description"
  width={800}
  height={600}
  format="webp"
  quality={85}
  loading="lazy"
  decoding="async"
/>
```

**Performance Budget**:
```javascript
// Image optimization config
const imageConfig = {
  formats: ['webp', 'avif', 'jpeg'],
  quality: {
    webp: 85,
    avif: 80,
    jpeg: 90
  },
  sizes: [320, 640, 1280, 1920],
  breakpoints: {
    mobile: 768,
    tablet: 1024,
    desktop: 1280
  }
};
```

### 3. Font Optimization

**Constitutional Font Loading**:
```astro
---
// Layout.astro - Optimal font loading
---

<head>
  <!-- Preload critical fonts -->
  <link
    rel="preload"
    href="/fonts/inter-latin-400.woff2"
    as="font"
    type="font/woff2"
    crossorigin
  />

  <!-- Font display swap for performance -->
  <style>
    @font-face {
      font-family: 'Inter';
      src: url('/fonts/inter-latin-400.woff2') format('woff2');
      font-weight: 400;
      font-style: normal;
      font-display: swap;
    }
  </style>
</head>
```

## ⚡ Runtime Performance

### 1. Core Web Vitals Optimization

**LCP (Largest Contentful Paint) Optimization**:
```astro
---
// Optimize LCP by prioritizing above-the-fold content
---

<head>
  <!-- Preload LCP image -->
  <link rel="preload" as="image" href="/hero-image.webp" />

  <!-- Resource hints -->
  <link rel="dns-prefetch" href="//fonts.googleapis.com" />
  <link rel="preconnect" href="//fonts.gstatic.com" crossorigin />
</head>

<!-- Critical rendering path optimization -->
<main>
  <!-- LCP element - prioritize loading -->
  <section class="hero above-fold">
    <h1>Constitutional Performance Excellence</h1>
  </section>
</main>
```

**CLS (Cumulative Layout Shift) Prevention**:
```css
/* Prevent layout shifts */
.hero-image {
  /* Reserve space before image loads */
  aspect-ratio: 16 / 9;
  width: 100%;
  height: auto;
}

.skeleton-loader {
  /* Placeholder dimensions match final content */
  width: 100%;
  height: 200px;
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
}

@keyframes loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

**FID (First Input Delay) Optimization**:
```javascript
// Minimal JavaScript for critical interactions
class ConstitutionalPerformance {
  constructor() {
    // Defer non-critical work
    if ('requestIdleCallback' in window) {
      requestIdleCallback(() => this.initializeNonCritical());
    } else {
      setTimeout(() => this.initializeNonCritical(), 1);
    }
  }

  initializeNonCritical() {
    // Load analytics, tracking, non-essential features
    import('./analytics.js').then(analytics => analytics.init());
  }
}

// Initialize only critical features immediately
new ConstitutionalPerformance();
```

### 2. Performance Monitoring

**Real User Monitoring (RUM)**:
```javascript
// Web Vitals measurement
import { onCLS, onFCP, onFID, onLCP, onTTFB } from 'web-vitals';

function sendToAnalytics(metric) {
  // Constitutional requirement: Local monitoring only
  console.log(`${metric.name}: ${metric.value}`);

  // Store locally for performance reports
  localStorage.setItem(`perf_${metric.name}`, JSON.stringify({
    value: metric.value,
    timestamp: Date.now()
  }));
}

// Monitor Core Web Vitals
onCLS(sendToAnalytics);
onFCP(sendToAnalytics);
onFID(sendToAnalytics);
onLCP(sendToAnalytics);
onTTFB(sendToAnalytics);
```

**Performance Budget Monitoring**:
```bash
#!/bin/bash
# Performance budget enforcement script

# Constitutional performance targets
LIGHTHOUSE_THRESHOLD=95
BUNDLE_SIZE_LIMIT=100000  # 100KB
BUILD_TIME_LIMIT=30       # 30 seconds

# Run Lighthouse audit
lighthouse_score=$(lighthouse --chrome-flags="--headless" http://localhost:4321 --output=json | jq '.categories.performance.score * 100')

if (( $(echo "$lighthouse_score < $LIGHTHOUSE_THRESHOLD" | bc -l) )); then
  echo "❌ Constitutional violation: Lighthouse score $lighthouse_score < $LIGHTHOUSE_THRESHOLD"
  exit 1
fi

echo "✅ Performance targets met: Lighthouse $lighthouse_score"
```

## 🛠️ Development Workflow Optimization

### 1. Development Server Performance

**Astro Development Optimization**:
```javascript
// astro.config.mjs - Development optimizations
export default defineConfig({
  server: {
    port: 4321,
    host: true
  },
  vite: {
    optimizeDeps: {
      include: ['react', 'react-dom']
    },
    build: {
      sourcemap: process.env.NODE_ENV === 'development'
    }
  }
});
```

**Hot Module Replacement (HMR)**:
```astro
---
// Component with HMR optimization
if (import.meta.hot) {
  import.meta.hot.accept();
}
---
```

### 2. Build Process Optimization

**Constitutional Build Pipeline**:
```bash
#!/bin/bash
# Optimized build process

# 1. Clear build cache
rm -rf .astro/ dist/

# 2. Environment setup
export NODE_ENV=production
export ASTRO_TELEMETRY_DISABLED=1

# 3. Build with performance monitoring
time npm run build

# 4. Bundle analysis
npx bundlesize

# 5. Performance validation
npm run test:performance

# 6. Constitutional compliance check
python3 scripts/constitutional_automation.py --validate
```

**Parallel Processing**:
```javascript
// Build optimization with workers
export default defineConfig({
  build: {
    rollupOptions: {
      maxParallelFileOps: 4
    }
  },
  vite: {
    build: {
      minify: 'terser',
      terserOptions: {
        maxWorkers: 4
      }
    }
  }
});
```

## 📊 Performance Testing & Monitoring

### 1. Automated Performance Testing

**Lighthouse CI Integration**:
```bash
# .lighthouserc.js
module.exports = {
  ci: {
    collect: {
      url: ['http://localhost:4321'],
      numberOfRuns: 3
    },
    assert: {
      assertions: {
        'categories:performance': ['error', {minScore: 0.95}],
        'categories:accessibility': ['error', {minScore: 0.95}],
        'categories:best-practices': ['error', {minScore: 0.95}],
        'categories:seo': ['error', {minScore: 0.95}]
      }
    }
  }
};
```

**Performance Testing Script**:
```python
# scripts/performance_test.py
import asyncio
import json
from playwright.async_api import async_playwright

async def measure_core_web_vitals():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()

        # Navigate and measure
        await page.goto('http://localhost:4321')

        # Measure FCP
        fcp = await page.evaluate('''
            new Promise((resolve) => {
                new PerformanceObserver((list) => {
                    for (const entry of list.getEntries()) {
                        if (entry.name === 'first-contentful-paint') {
                            resolve(entry.startTime);
                        }
                    }
                }).observe({entryTypes: ['paint']});
            })
        ''')

        # Constitutional validation
        assert fcp < 1800, f"FCP {fcp}ms exceeds 1.8s target"

        await browser.close()
        return {'fcp': fcp}

if __name__ == '__main__':
    asyncio.run(measure_core_web_vitals())
```

### 2. Continuous Performance Monitoring

**Performance Dashboard**:
```javascript
// Performance metrics dashboard
class PerformanceDashboard {
  constructor() {
    this.metrics = this.loadMetrics();
    this.render();
  }

  loadMetrics() {
    const metrics = {};
    ['CLS', 'FCP', 'FID', 'LCP', 'TTFB'].forEach(metric => {
      const stored = localStorage.getItem(`perf_${metric}`);
      if (stored) {
        metrics[metric] = JSON.parse(stored);
      }
    });
    return metrics;
  }

  render() {
    const dashboard = document.getElementById('perf-dashboard');
    if (!dashboard) return;

    const html = Object.entries(this.metrics).map(([metric, data]) => `
      <div class="metric ${this.getMetricStatus(metric, data.value)}">
        <h3>${metric}</h3>
        <span class="value">${data.value.toFixed(2)}</span>
        <span class="unit">${this.getMetricUnit(metric)}</span>
      </div>
    `).join('');

    dashboard.innerHTML = html;
  }

  getMetricStatus(metric, value) {
    const thresholds = {
      CLS: 0.1,
      FCP: 1800,
      FID: 100,
      LCP: 2500,
      TTFB: 800
    };

    return value <= thresholds[metric] ? 'good' : 'needs-improvement';
  }
}
```

## 🎯 Performance Troubleshooting

### Common Performance Issues

#### 1. Large JavaScript Bundles
```bash
# Diagnose bundle bloat
npx webpack-bundle-analyzer dist/

# Fix: Code splitting and tree shaking
# Remove unused dependencies
npm uninstall unused-package

# Use dynamic imports
const Component = lazy(() => import('./Component'));
```

#### 2. Render-Blocking Resources
```astro
---
// Problem: Render-blocking CSS
---
<link rel="stylesheet" href="/styles.css">

---
// Solution: Critical CSS inlining
---
<style is:inline>
  /* Critical styles only */
</style>
<link rel="preload" href="/styles.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
```

#### 3. Image Performance Issues
```astro
---
// Problem: Unoptimized images
---
<img src="/large-image.jpg" alt="Description">

---
// Solution: Astro Image optimization
import { Image } from 'astro:assets';
---
<Image
  src={optimizedImage}
  alt="Description"
  loading="lazy"
  format="webp"
  quality={85}
/>
```

### Performance Debugging Tools

**Development Tools**:
```bash
# Bundle analysis
npm run build:analyze

# Performance profiling
npm run dev -- --profiler

# Memory usage monitoring
node --inspect --max-old-space-size=4096 node_modules/.bin/astro dev
```

**Production Monitoring**:
```javascript
// Production performance monitoring
if ('performance' in window && 'getEntriesByType' in window.performance) {
  // Monitor resource loading
  window.addEventListener('load', () => {
    const resources = performance.getEntriesByType('resource');
    const slowResources = resources.filter(r => r.duration > 1000);

    if (slowResources.length > 0) {
      console.warn('Slow resources detected:', slowResources);
    }
  });
}
```

## 📋 Performance Checklist

### Pre-Deploy Validation
- [ ] Lighthouse scores ≥95 across all categories
- [ ] Core Web Vitals meet constitutional targets
- [ ] JavaScript bundle <100KB (gzipped)
- [ ] CSS bundle <20KB (gzipped)
- [ ] Build time <30 seconds
- [ ] No render-blocking resources
- [ ] Images optimized with WebP/AVIF
- [ ] Fonts loaded with `font-display: swap`
- [ ] Critical CSS inlined
- [ ] Non-critical JavaScript deferred

### Monitoring Setup
- [ ] Performance budget configured
- [ ] Real User Monitoring (RUM) implemented
- [ ] Automated performance testing
- [ ] Performance dashboard active
- [ ] Alert thresholds configured
- [ ] Performance reports generated

### Constitutional Compliance
- [ ] Zero GitHub Actions consumption for performance testing
- [ ] Local performance validation pipeline
- [ ] Constitutional targets enforced
- [ ] Performance regression prevention
- [ ] User-centric metrics prioritized

---

**Constitutional Performance Excellence**
**Framework Version**: 2.0
**Last Updated**: 2025-09-20
**Compliance Status**: ✅ All constitutional requirements met
**Performance Targets**: ✅ All targets achievable with this guide