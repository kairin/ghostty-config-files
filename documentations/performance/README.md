# Performance Benchmarking Dashboard

**Priority 4 Enhancement** | **Context7 MCP Validated** | **Constitutional Compliance: Active**

---

## Overview

The Performance Benchmarking Dashboard provides comprehensive performance tracking and visualization for the Ghostty Configuration Files project. It monitors Lighthouse scores, build performance, bundle sizes, and CI/CD metrics over time.

**Dashboard Location**: `./dashboard.html` (generated after first benchmark run)

---

## Quick Start

### Run Complete Benchmark

```bash
# From repository root
./.runners-local/workflows/performance-dashboard.sh benchmark

# Dashboard will be generated and opened automatically
```

### View Existing Dashboard

```bash
./.runners-local/workflows/performance-dashboard.sh view

# Or open manually:
# file:///home/kkk/Apps/ghostty-config-files/documentations/performance/dashboard.html
```

---

## Features

### 📊 Metrics Tracked

1. **Lighthouse Scores**
   - Performance (target: 95+)
   - Accessibility (target: 95+)
   - Best Practices (target: 95+)
   - SEO (target: 95+)

2. **Core Web Vitals**
   - First Contentful Paint (FCP) - target: <1.5s
   - Largest Contentful Paint (LCP) - target: <2.5s
   - Cumulative Layout Shift (CLS) - target: <0.1

3. **Build Performance**
   - Astro build time - target: <30 seconds
   - Hot reload time - target: <1 second

4. **Bundle Sizes**
   - JavaScript initial bundle - target: <100KB

5. **CI/CD Performance**
   - Complete workflow time - target: <2 minutes
   - Failed steps count

### 📈 Visualizations

- **Lighthouse Scores Trend**: Line chart showing score evolution over time
- **Build Performance Trend**: Bar chart showing build time variations
- **Bundle Size Trend**: Line chart tracking JavaScript bundle size
- **Real-time Metrics**: Current values with target comparison
- **Status Indicators**: Visual pass/warning/fail indicators

---

## Commands

```bash
# Complete benchmark suite (recommended)
./.runners-local/workflows/performance-dashboard.sh benchmark

# Individual metric collection
./.runners-local/workflows/performance-dashboard.sh lighthouse  # Lighthouse only
./.runners-local/workflows/performance-dashboard.sh build      # Build metrics only
./.runners-local/workflows/performance-dashboard.sh cicd       # CI/CD metrics only

# Dashboard management
./.runners-local/workflows/performance-dashboard.sh dashboard  # Regenerate dashboard
./.runners-local/workflows/performance-dashboard.sh view       # Open in browser
./.runners-local/workflows/performance-dashboard.sh help       # Show help
```

---

## Data Storage

### Metrics Database

**Location**: `./metrics-database.json`

**Structure**:
```json
{
  "created": "2025-11-10T06:00:00Z",
  "last_updated": "2025-11-10T12:00:00Z",
  "constitutional_targets": {
    "lighthouse": { "performance": 95, "accessibility": 95, ... },
    "core_web_vitals": { "fcp": 1.5, "lcp": 2.5, "cls": 0.1 },
    "build_performance": { "astro_build_seconds": 30, ... },
    "bundle_size": { "initial_js_kb": 100 },
    "ci_cd_performance": { "workflow_duration_seconds": 120 }
  },
  "metrics": [
    {
      "timestamp": "2025-11-10T12:00:00Z",
      "type": "lighthouse",
      "data": { "performance": 96, "accessibility": 98, ... }
    },
    ...
  ]
}
```

### Lighthouse Reports

**Location**: `./lighthouse-reports/`

Individual Lighthouse JSON reports stored with timestamps:
- `lighthouse-20251110-120000.json`
- `lighthouse-20251110-130000.json`

### Historical Data

The dashboard maintains up to 20 most recent data points for each metric type, providing trend analysis while keeping file sizes manageable.

---

## Constitutional Targets

All targets are defined in the project constitution (AGENTS.md):

| Metric | Target | Source |
|--------|--------|--------|
| Lighthouse Performance | ≥95 | Constitutional Principle |
| Lighthouse Accessibility | ≥95 | Constitutional Principle |
| Lighthouse Best Practices | ≥95 | Constitutional Principle |
| Lighthouse SEO | ≥95 | Constitutional Principle |
| FCP | <1.5s | Core Web Vitals |
| LCP | <2.5s | Core Web Vitals |
| CLS | <0.1 | Core Web Vitals |
| Astro Build Time | <30s | Constitutional Requirement |
| Hot Reload Time | <1s | Constitutional Requirement |
| JavaScript Bundle | <100KB | Constitutional Requirement |
| CI/CD Complete Workflow | <2min | Constitutional Requirement |

---

## Integration Points

### Local CI/CD Integration

The performance dashboard integrates with the local CI/CD workflow:

```bash
# Enhanced local workflow now includes performance tracking
./.runners-local/workflows/gh-workflow-local.sh all

# Optionally run benchmark after workflow
./.runners-local/workflows/performance-dashboard.sh benchmark
```

### Automated Tracking

Add to `.git/hooks/post-commit` for automatic benchmarking:

```bash
#!/bin/bash
# Run benchmark after significant commits
if git log -1 --pretty=%B | grep -qE "feat:|fix:|perf:"; then
    ./.runners-local/workflows/performance-dashboard.sh build
fi
```

### Context7 MCP Validation

The dashboard metrics are validated against Context7 MCP best practices:

```bash
# Context7 validation includes performance metrics
./.runners-local/workflows/gh-workflow-local.sh context7
```

---

## Dashboard Features

### Visual Design

- **Gradient Background**: Purple gradient for modern aesthetic
- **Card-Based Layout**: Responsive grid for metrics
- **Chart.js Integration**: Interactive, animated charts
- **Color-Coded Status**: Green (pass), Yellow (warning), Red (fail)
- **Hover Effects**: Cards lift on hover for better UX

### Real-time Updates

The dashboard is static HTML but can be regenerated at any time:

```bash
# Regenerate with latest data
./.runners-local/workflows/performance-dashboard.sh dashboard
```

### Mobile Responsive

The dashboard is fully responsive and works on:
- Desktop browsers (Chrome, Firefox, Safari, Edge)
- Tablet devices
- Mobile phones (landscape recommended for charts)

---

## Troubleshooting

### Lighthouse Not Available

**Issue**: `lighthouse: command not found`

**Solution**:
```bash
# Install Lighthouse globally
npm install -g lighthouse

# Verify installation
lighthouse --version
```

### Build Output Missing

**Issue**: `No Astro build output found`

**Solution**:
```bash
# Run Astro build first
npm run build

# Then run benchmark
./.runners-local/workflows/performance-dashboard.sh benchmark
```

### Preview Server Fails

**Issue**: `npm run preview` fails or times out

**Solution**:
```bash
# Check if Astro is installed
npm install

# Verify package.json has preview script
grep "preview" package.json

# Manually start preview for testing
npm run preview
```

### jq Not Available

**Issue**: `jq not available, skipping database update`

**Solution**:
```bash
# Install jq
sudo apt install jq  # Ubuntu/Debian
brew install jq      # macOS

# Verify installation
jq --version
```

### Dashboard Won't Open

**Issue**: `view` command doesn't open browser

**Solution**:
```bash
# Open manually
xdg-open documentations/performance/dashboard.html  # Linux
open documentations/performance/dashboard.html      # macOS

# Or copy path and paste in browser
echo "file://$(pwd)/documentations/performance/dashboard.html"
```

---

## Best Practices

### When to Run Benchmarks

1. **After Major Changes**
   - New features added
   - Performance optimizations implemented
   - Dependencies updated

2. **Before Releases**
   - Verify targets are met
   - Document performance regressions
   - Validate optimizations

3. **Weekly Baseline**
   - Track trends over time
   - Identify gradual degradation
   - Establish performance baselines

4. **After CI/CD Updates**
   - Verify workflow performance
   - Validate build optimizations
   - Check for regressions

### Interpreting Results

**Lighthouse Scores**:
- **95-100**: Excellent, meets constitutional targets
- **80-94**: Good, but room for improvement
- **<80**: Needs attention, investigate issues

**Build Times**:
- **<30s**: Excellent, on target
- **30-60s**: Acceptable, consider optimization
- **>60s**: Slow, needs investigation

**Bundle Sizes**:
- **<100KB**: Excellent, on target
- **100-200KB**: Acceptable, monitor growth
- **>200KB**: Large, consider code splitting

**CI/CD Performance**:
- **<2min**: Excellent, on target
- **2-5min**: Acceptable for complex workflows
- **>5min**: Slow, investigate bottlenecks

---

## Future Enhancements

### Planned Features

1. **Automated Alerts**
   - Email/Slack notifications for target misses
   - GitHub commit status checks
   - Automatic issue creation for regressions

2. **Comparative Analysis**
   - Compare current vs baseline
   - Branch-to-branch comparison
   - Pre/post deployment diff

3. **Historical Trends**
   - Extended time ranges (30/60/90 days)
   - Seasonal pattern detection
   - Predictive analysis

4. **Custom Metrics**
   - User-defined performance targets
   - Custom chart configurations
   - Plugin system for additional metrics

5. **Export Capabilities**
   - PDF report generation
   - CSV data export
   - Integration with monitoring tools

---

## References

- **Constitutional Requirements**: See AGENTS.md "Performance Targets"
- **Lighthouse Documentation**: https://developers.google.com/web/tools/lighthouse
- **Core Web Vitals**: https://web.dev/vitals/
- **Chart.js Documentation**: https://www.chartjs.org/docs/latest/
- **Astro Performance**: https://docs.astro.build/en/guides/performance/

---

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review script logs in `.runners-local/logs/workflows/`
3. Verify constitutional requirements in AGENTS.md
4. Open GitHub issue with dashboard screenshot

---

**Document Version**: 1.0
**Last Updated**: 2025-11-10
**Maintained By**: Project Contributors
**Context7 Validated**: ✅ Yes
**Constitutional Compliance**: ✅ Yes
