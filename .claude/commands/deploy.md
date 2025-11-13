---
description: Execute complete deployment workflow - Astro build, validation, commit, and GitHub Pages deployment
---

## User Input

```text
$ARGUMENTS
```

## Workflow

Execute the following agents **in sequence**:

1. **astro-build-specialist**:
   - Rebuild Astro site
   - Verify .nojekyll file integrity
   - Validate build output (docs/index.html, docs/_astro/)

2. **git-operations-specialist**:
   - Execute constitutional commit workflow
   - Commit message: "deploy: Rebuild Astro site with latest content"
   - Push changes to main branch

3. **project-health-auditor**:
   - Verify GitHub Pages configuration
   - Check deployment status
   - Validate site accessibility

## Execution

1. First, invoke `astro-build-specialist` to rebuild the site
2. Then, invoke `git-operations-specialist` to commit and push
3. Finally, invoke `project-health-auditor` to verify deployment

Provide a summary report of all three stages.
