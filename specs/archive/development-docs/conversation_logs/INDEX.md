# Conversation Logs Index

This index provides a searchable, organized view of all conversation logs in the ghostty-config-files repository.

## Overview

All conversation logs are stored in this directory following the naming convention:
```
CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md
```

Logs are organized chronologically and indexed below for easy discovery and reference.

## How to Use This Index

### Finding Logs by Date
- Logs are organized by ISO 8601 dates (YYYYMMDD)
- Most recent logs appear first in the "Active Logs" section below
- Use Ctrl+F to search for specific dates

### Finding Logs by Topic
- Topic tags are listed in the "Topic Index" section
- Search by feature name, fix description, or technology
- Multiple tags may apply to a single log

### Searching All Logs
```bash
# List all conversation logs
ls -lrt documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Search logs by topic
grep -l "pattern" documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Search log content
grep -r "search term" documentations/development/conversation_logs/

# Count logs in a month
ls documentations/development/conversation_logs/CONVERSATION_LOG_202511*.md 2>/dev/null | wc -l
```

---

## Active Logs (Current Month)

> **November 2025**: Conversation logs created in the current month

### Most Recent Logs

| Date | File | Topic | Status |
|------|------|-------|--------|
| [To be populated] | | | |

---

## Historical Logs by Month

### October 2025
[Logs from October 2025, if any]

### Earlier Months
[Logs from earlier periods, if any]

---

## Topic Index

Use this index to find logs related to specific areas of work.

### Infrastructure & Architecture
- Conversation logs infrastructure setup
- Directory structure and organization
- System architecture documentation
- Repository health assessment

### Configuration Management
- Ghostty configuration optimization
- Performance tuning
- Theme configuration
- Shell integration

### AI Tool Integration
- Claude Code setup and integration
- Gemini CLI integration
- Context7 MCP configuration
- GitHub MCP setup

### Local CI/CD
- GitHub Actions local simulation
- Build and deployment workflows
- Performance monitoring
- Testing and validation

### Documentation
- Documentation generation and maintenance
- Specification writing
- README and guide updates
- Technical writing

### Features & Enhancements
- New feature implementation
- Performance optimization
- Bug fixes
- User experience improvements

---

## Template for Adding New Logs

When you create a new conversation log, add an entry to this index:

```markdown
| YYYYMMDD | [CONVERSATION_LOG_YYYYMMDD_description.md](./CONVERSATION_LOG_YYYYMMDD_description.md) | Brief description | Status |
```

Update the appropriate month section and topic tags.

---

## Statistics

### Overall Activity
- Total conversation logs: [To be updated]
- Logs this month: [To be updated]
- Logs this year: [To be updated]

### By Category
- Infrastructure: [0]
- Configuration: [0]
- AI Tools: [0]
- CI/CD: [0]
- Documentation: [0]
- Features: [0]

### Average Log Size
- By word count: [To be updated]
- By section count: [To be updated]
- Average CI/CD execution time: [To be updated]

---

## Quality Metrics

### Compliance Tracking
- Logs with complete headers: [To be tracked]
- Logs with quality gates checklist: [To be tracked]
- Logs with CI/CD results: [To be tracked]
- Logs with system state capture: [To be tracked]

### Content Coverage
- Executive summaries: [To be tracked]
- Implementation details: [To be tracked]
- Testing & validation: [To be tracked]
- References to specs: [To be tracked]

---

## Related Documentation

### Core References
- **README.md** - Infrastructure overview and setup guide
- **CONVERSATION_LOG_TEMPLATE.md** - Template for creating new logs
- **LLM_LOGGING_QUICK_GUIDE.md** - Quick reference for AI assistants
- **SECURITY.md** - Guidelines for protecting sensitive data

### Constitutional Documents
- **CLAUDE.md** - LLM instructions and requirements
- **GEMINI.md** - Gemini CLI integration details

### Infrastructure
- **documentations/developer/recent-improvements.md** - Recent changes
- **documentations/specifications/** - Active feature specifications
- **.runners-local/workflows/** - Local CI/CD execution

---

## How to Contribute

### Creating a New Conversation Log

1. Complete your work following CLAUDE.md guidelines
2. Save conversation log with proper naming: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
3. Fill in all required sections (use CONVERSATION_LOG_TEMPLATE.md)
4. Verify no sensitive data (see SECURITY.md)
5. Commit to git: `git add documentations/development/conversation_logs/`
6. Update this INDEX.md with new entry
7. Commit: `git commit -m "Add conversation log for [description]"`

### Updating This Index

When a new conversation log is created:

1. Add entry to "Most Recent Logs" table with date, filename, topic, status
2. Add topic tags to relevant sections in "Topic Index"
3. Update "Statistics" section with new counts
4. Update monthly section if in new month

---

## Archival & Maintenance

### When to Archive Logs
- Logs older than 90 days MAY be archived
- Archive decision based on activity frequency
- Historical logs remain searchable and referenced

### Archival Location
```
documentations/archive/conversation_logs/
```

### Archival Process
1. Move old logs to archive directory
2. Create symlink for backward compatibility (optional)
3. Update this index with archive reference
4. Commit: `git commit -m "Archive old conversation logs"`

---

## Search Examples

### Find logs about specific features
```bash
grep -l "ghostty-optimization\|performance" documentations/development/conversation_logs/*.md
```

### Find logs by assistant
```bash
grep -l "Claude\|Gemini" documentations/development/conversation_logs/*.md
```

### Find logs with test failures
```bash
grep -l "FAILED\|Failed" documentations/development/conversation_logs/*.md
```

### Find incomplete logs
```bash
grep -l "In Progress" documentations/development/conversation_logs/*.md
```

### Count logs by topic
```bash
grep -h "Topic:" documentations/development/conversation_logs/*.md | sort | uniq -c
```

---

## Performance Benchmarks

### Typical Conversation Log Metrics
- Creation time: 15-30 minutes per log
- Local CI/CD execution: 10-15 minutes for full workflow
- File size: 8-15 KB per log
- Word count: 500-2,000 words per log

### CI/CD Pipeline Performance
- Stage 1 (Config validation): ~0.5s
- Stage 2 (Performance testing): ~2-3s
- Stage 3 (Compatibility): ~1-2s
- Stage 4 (Workflow simulation): ~3-4s
- Stage 5 (Documentation): ~1-2s
- Stage 6 (Packaging): ~1s
- Stage 7 (GitHub Pages): ~2-3s
- **Total**: ~12-17 seconds

---

## Troubleshooting

### "I can't find a log I created"
- Check file naming: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- Search by date: `ls documentations/development/conversation_logs/CONVERSATION_LOG_202511*.md`
- Search by keyword: `grep -r "keyword" documentations/development/conversation_logs/`

### "The index seems outdated"
- This is a manual index - it may lag behind actual files
- Check the directory directly: `ls documentations/development/conversation_logs/`
- Use git to track history: `git log --oneline documentations/development/conversation_logs/`

### "Where are older logs?"
- Check archive directory: `documentations/archive/conversation_logs/`
- Search git history: `git log --all -- documentations/development/conversation_logs/`
- Check README for archival information

---

## Statistics Dashboard

This section is auto-updated as logs are added.

```
📊 Conversation Logs Statistics
├─ Total Logs: [0]
├─ Current Month: [0]
├─ Previous Month: [0]
├─ This Year: [0]
└─ All Time: [0]

📈 Activity Trend
├─ Week Average: [0] logs/week
├─ Month Average: [0] logs/month
├─ Most Active Day: [TBD]
└─ Most Active Topic: [TBD]

✅ Quality Metrics
├─ Complete Logs: [0%]
├─ With CI/CD Results: [0%]
├─ With System State: [0%]
└─ Security Compliant: [0%]
```

---

## Constitutional Compliance

This index supports CLAUDE.md requirements:

**Section**: LLM Conversation Logging (MANDATORY)
- ✅ Organized storage of conversation logs
- ✅ Easy searchability and reference
- ✅ Historical tracking of work
- ✅ Quality metrics for compliance

---

## Last Updated

- Date: 2025-11-16
- Version: 1.0
- Status: ACTIVE - INITIAL SETUP
- Next Review: When first logs are added

## Quick Links

- [README.md](./README.md) - Full infrastructure documentation
- [CONVERSATION_LOG_TEMPLATE.md](./CONVERSATION_LOG_TEMPLATE.md) - Log template
- [LLM_LOGGING_QUICK_GUIDE.md](./LLM_LOGGING_QUICK_GUIDE.md) - Quick reference for assistants
- [SECURITY.md](./SECURITY.md) - Security and sensitive data guidelines
- [CLAUDE.md](../../../../CLAUDE.md) - Constitutional requirements

---

**Note**: This index is maintained manually. If you notice discrepancies between the index and the actual directory contents, the directory contents are the source of truth. You can use the file listing commands above to get an accurate, up-to-date view.
