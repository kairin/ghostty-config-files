# Documentation Index

## 📚 Core Documentation

### Getting Started
- [README](../README.md) - Project overview and quick start
- [Development Guide](guides/development.md) - Complete development workflow
- [Configuration Guide](guides/configuration.md) - Configuration management

### Constitutional Framework
- [Constitutional Compliance](constitutional/README.md) - Framework requirements and validation
- [Performance Guide](performance/README.md) - Performance targets and monitoring
- [Deployment Guide](guides/deployment.md) - Zero-cost deployment strategies

### API Documentation
- [Components](api/components/README.md) - TypeScript/Astro component documentation
- [Scripts](api/scripts/README.md) - Python and shell script documentation

## 🛠️ Quick Commands

### Development
```bash
# Start development
./start.sh

# Local CI/CD
./local-infra/runners/gh-workflow-local.sh all

# Generate documentation
python scripts/doc_generator.py
```

### Performance Monitoring
```bash
# Monitor Core Web Vitals
python scripts/performance_monitor.py --url http://localhost:4321

# Run benchmarks
./local-infra/runners/benchmark-runner.sh --full
```

### Constitutional Validation
```bash
# Validate compliance
python scripts/constitutional_automation.py --validate

# Check GitHub Actions usage
gh api user/settings/billing/actions | jq '.total_paid_minutes_used'
```

## 📊 Documentation Metrics

- **Total Pages**: 16
- **Last Generated**: 2025-09-20 12:10:41
- **Generation Time**: 0.00s

## 🏛️ Constitutional Compliance

This documentation is generated with constitutional compliance:
- ✅ Zero GitHub Actions consumption
- ✅ Local generation only
- ✅ Performance monitoring
- ✅ Quality validation

Generated with Constitutional Documentation Generator v2.0
