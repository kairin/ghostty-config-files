# Data Model: Wave 0 Foundation Fixes

**Date**: 2026-01-18
**Branch**: `001-foundation-fixes`
**Type**: Documentation-only (no database)

## Entities

This feature involves static documentation files. No database or runtime data model required.

### Entity 1: LICENSE File

**Description**: Legal document defining usage rights for the repository

| Field | Type | Constraints |
|-------|------|-------------|
| license_type | string | "MIT" (fixed) |
| year | integer | 2026 |
| copyright_holder | string | Repository owner name |
| full_text | text | Standard MIT template |

**Validation Rules**:
- Must contain "MIT License" header
- Must contain copyright year and holder
- Must contain permission grant clause
- Must contain disclaimer clause

**State**: Static (created once, rarely modified)

---

### Entity 2: Documentation Link

**Description**: Internal reference from one markdown file to another

| Field | Type | Constraints |
|-------|------|-------------|
| source_file | path | Existing .md file |
| target_path | path | Relative path from source |
| link_text | string | Display text in source |
| target_exists | boolean | Must be true for valid link |

**Validation Rules**:
- Target path must resolve to existing file
- Path must be relative (not absolute)
- Target file must contain meaningful content

**Affected Links**:
| Source | Target | Status |
|--------|--------|--------|
| `local-cicd-operations.md` | `../guides/local-cicd-guide.md` | BROKEN (target missing) |

---

### Entity 3: Tier Definition

**Description**: Agent classification structure within the architecture

| Field | Type | Constraints |
|-------|------|-------------|
| tier_number | integer | 0-4 |
| model_name | string | "Sonnet", "Opus", or "Haiku" |
| agent_count | integer | Positive integer |
| purpose | string | Brief description |

**Validation Rules**:
- All documentation files must show same tier structure
- Total agent count: 65
- Model assignments must be consistent across files

**Canonical Values**:
| tier_number | model_name | agent_count | purpose |
|-------------|------------|-------------|---------|
| 0 | Sonnet | 5 | Complete workflows |
| 1 | Opus | 1 | Multi-agent orchestration |
| 2 | Sonnet | 5 | Core operations |
| 3 | Sonnet | 4 | Utility operations |
| 4 | Haiku | 50 | Atomic execution |

---

## Relationships

```text
Repository
├── LICENSE (1:1)
│
└── Documentation/
    ├── Source Files (1:N)
    │   └── Links (1:N per source)
    │       └── Target Files (N:1)
    │
    └── Architecture Docs (4 files)
        └── Tier Definitions (must match)
```

## No Database Schema

This feature modifies static files only. No database tables, migrations, or runtime data storage required.

## Contracts

N/A - Documentation-only feature with no API endpoints.
