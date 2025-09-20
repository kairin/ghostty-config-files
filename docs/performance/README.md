# Performance Guide

## Constitutional Performance Targets

### Core Web Vitals
- **First Contentful Paint (FCP)**: <1.8 seconds
- **Largest Contentful Paint (LCP)**: <2.5 seconds
- **Cumulative Layout Shift (CLS)**: <0.1
- **First Input Delay (FID)**: <100 milliseconds

### Build Performance
- **Build Time**: <30 seconds
- **JavaScript Bundle**: <100KB (gzipped)
- **CSS Bundle**: <20KB (gzipped)
- **Lighthouse Performance**: 95+

### System Performance
- **Ghostty Startup**: <500ms
- **Memory Usage**: <100MB baseline
- **CI/CD Execution**: <2 minutes complete workflow

## Performance Monitoring

### Automated Monitoring
```bash
# Monitor Core Web Vitals
python scripts/performance_monitor.py --url http://localhost:4321

# Run performance benchmarks
./local-infra/runners/benchmark-runner.sh --full

# Monitor system performance
./local-infra/runners/performance-monitor.sh --continuous
```

### Performance Reports
Performance reports are automatically generated and stored in:
- `local-infra/logs/performance-*.json` - System performance metrics
- `docs/performance/reports/` - Historical performance data
- `local-infra/logs/benchmark-*.json` - Benchmark results

## Optimization Strategies

### Frontend Optimizations
- Tree-shaking enabled for minimal bundle sizes
- CSS purging for unused styles
- Image optimization and lazy loading
- Component-level code splitting

### Build Optimizations
- Incremental TypeScript compilation
- Astro static site generation
- Tailwind CSS JIT compilation
- Asset compression and minification

### System Optimizations
- Ghostty CGroup single-instance mode
- Memory-mapped file access
- Optimized scrollback management
- Hardware acceleration utilization
