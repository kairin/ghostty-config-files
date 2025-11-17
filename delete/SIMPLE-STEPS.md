# 🎯 Simple Spec-Kit Execution Steps

**What is this folder?** This folder contains everything you need to successfully run the spec-kit workflow without repeating previous mistakes.

**When to delete this folder?** Once you complete all 5 spec-kit commands successfully, delete this entire `delete/` folder.

---

## 📋 Step-by-Step Instructions

### STEP 0: Understand the Problem
Your previous spec-kit attempts kept reverting because the spec-kit guides had outdated information:
- ❌ They reference `.runners-local/` (doesn't exist in your project)
- ❌ They recommend `shadcn/ui` (you use DaisyUI)
- ❌ They require `Node.js 18+` (you use latest v25.2.0+)

**Solution**: After EVERY spec-kit command, fix these 3 things immediately.

---

### STEP 1: Read These Files (in order)
```bash
# Start here - overview of everything
cat delete/00-READ-ME-FIRST.md

# Keep this visible while working (one-page reference)
cat delete/01-QUICK-REFERENCE-keep-visible.md

# Read this for detailed guidance
cat delete/03-MASTER-GUIDE-comprehensive.md
```

---

### STEP 2: Verify Your System is Ready
```bash
# Run this script - it checks everything
./delete/02-verify-prerequisites.sh

# Expected result: ✅ PASSED: 17 checks
# If you see ❌ FAILED, fix those issues first
```

---

### STEP 3: Execute /speckit.constitution

**What to do:**
1. Run the slash command: `/speckit.constitution`
2. **BUT** tell it these corrections:
   ```
   CRITICAL CORRECTIONS (use current reality):
   - Use .runners-local/ NOT .runners-local/
   - Use DaisyUI NOT shadcn/ui
   - Use Node.js latest (v25.2.0+) NOT Node.js 18+
   - Preserve docs/.nojekyll (CRITICAL for GitHub Pages)
   ```

3. After it generates the constitution file, **IMMEDIATELY** fix it:
   ```bash
   # Find the generated file (likely .specify/memory/constitution.md)
   FILE=".specify/memory/constitution.md"

   # Fix the 3 common mistakes
   sed -i 's|.runners-local/|.runners-local/|g' "$FILE"
   sed -i 's|shadcn/ui|DaisyUI|g' "$FILE"
   sed -i 's|Node\.js 18|Node.js latest (v25.2.0+)|g' "$FILE"
   ```

4. Verify nothing broke:
   ```bash
   ./delete/02-verify-prerequisites.sh
   ls docs/.nojekyll  # Must still exist
   ```

5. Commit with proper branch:
   ```bash
   DATETIME=$(date +"%Y%m%d-%H%M%S")
   BRANCH_NAME="${DATETIME}-docs-speckit-constitution"

   git checkout -b "$BRANCH_NAME"
   git add .
   git commit -m "docs: Establish constitution via /speckit.constitution"
   git push -u origin "$BRANCH_NAME"
   git checkout main
   git merge "$BRANCH_NAME" --no-ff
   git push origin main
   # Do NOT delete the branch
   ```

---

### STEP 4: Execute /speckit.specify

**What to do:**
1. Run: `/speckit.specify`
2. Tell it to use the constitution and apply same corrections
3. **IMMEDIATELY** after it generates spec.md:
   ```bash
   FILE="specs/[feature-name]/spec.md"  # Adjust path

   sed -i 's|.runners-local/|.runners-local/|g' "$FILE"
   sed -i 's|shadcn/ui|DaisyUI|g' "$FILE"
   sed -i 's|Node\.js 18|Node.js latest (v25.2.0+)|g' "$FILE"
   ```
4. Verify: `./delete/02-verify-prerequisites.sh`
5. Commit with same branch workflow as Step 3

---

### STEP 5: Execute /speckit.plan

**What to do:**
1. Optional: Run `/speckit.clarify` first if spec has ambiguities
2. Run: `/speckit.plan`
3. **IMMEDIATELY** fix plan.md:
   ```bash
   FILE="specs/[feature-name]/plan.md"

   sed -i 's|.runners-local/|.runners-local/|g' "$FILE"
   sed -i 's|shadcn/ui|DaisyUI|g' "$FILE"
   sed -i 's|Node\.js 18|Node.js latest (v25.2.0+)|g' "$FILE"
   ```
4. Verify: `./delete/02-verify-prerequisites.sh`
5. Commit with branch workflow

---

### STEP 6: Execute /speckit.tasks

**What to do:**
1. Optional: Run `/speckit.checklist` for quality gates
2. Run: `/speckit.tasks`
3. **IMMEDIATELY** fix tasks.md:
   ```bash
   FILE="specs/[feature-name]/tasks.md"

   sed -i 's|.runners-local/|.runners-local/|g' "$FILE"
   sed -i 's|shadcn/ui|DaisyUI|g' "$FILE"
   sed -i 's|Node\.js 18|Node.js latest (v25.2.0+)|g' "$FILE"
   ```
4. Optional: Run `/speckit.analyze` to check consistency
5. Verify: `./delete/02-verify-prerequisites.sh`
6. Commit with branch workflow

---

### STEP 7: Execute /speckit.implement

**What to do:**
1. Run: `/speckit.implement`
2. It will work through tasks.md
3. After EACH task completion, verify:
   ```bash
   ./delete/02-verify-prerequisites.sh
   ls docs/.nojekyll  # Still there?
   ```
4. If any file gets generated, apply the fix immediately
5. Commit after each major milestone

---

### STEP 8: Celebrate & Clean Up

Once all 5 commands complete successfully:

```bash
# Final verification
./delete/02-verify-prerequisites.sh

# Confirm everything works
ls docs/.nojekyll
grep "daisyui" website/package.json
ls .runners-local/

# Delete this folder (you succeeded!)
rm -rf /home/kkk/Apps/ghostty-config-files/delete/

# Commit the deletion
git add .
git commit -m "chore: Remove spec-kit reference materials after successful implementation"
```

---

## 🚨 The ONE Thing to Remember

**After EVERY spec-kit command, immediately run these 3 lines:**

```bash
sed -i 's|.runners-local/|.runners-local/|g' [generated-file]
sed -i 's|shadcn/ui|DaisyUI|g' [generated-file]
sed -i 's|Node\.js 18|Node.js latest (v25.2.0+)|g' [generated-file]
```

That's it. This prevents the reversion issues you experienced before.

---

## 📂 What's in This Folder

```
delete/
├── 00-READ-ME-FIRST.md              ← Comprehensive overview
├── 01-QUICK-REFERENCE-keep-visible.md  ← Keep this open while working
├── 02-verify-prerequisites.sh        ← Run before/after each command
├── 03-MASTER-GUIDE-comprehensive.md  ← Detailed guidance
├── SIMPLE-STEPS.md                   ← This file (simple instructions)
├── reference-materials/              ← Background reading (optional)
│   ├── constitutional-principles-reference.md
│   ├── reversion-issues-analysis.md
│   ├── speckit-workflow-execution-guide.md
│   └── spec-005-lessons-learned.md
└── old-spec-artifacts/               ← Your previous attempt (archived)
    ├── guides/
    ├── specs/
    └── .specify/
```

---

## ❓ FAQ

**Q: Which file should I read first?**
A: Read this file (SIMPLE-STEPS.md), then `01-QUICK-REFERENCE-keep-visible.md`

**Q: Do I need to read all the reference materials?**
A: No. Only read them if you want deeper understanding. The simple steps above are enough.

**Q: What if I forget to fix the 3 mistakes?**
A: Run `./delete/02-verify-prerequisites.sh` - it will catch some issues. But better to fix immediately.

**Q: When can I delete this folder?**
A: After all 5 spec-kit commands succeed and your implementation is complete.

**Q: What if something breaks?**
A: Run `./delete/02-verify-prerequisites.sh` to see what's wrong. Check if `docs/.nojekyll` still exists.

---

## 🎯 Success Checklist

After completing all steps, verify:
- [ ] Constitution established with correct paths
- [ ] Spec created with DaisyUI references
- [ ] Plan uses .runners-local/ directory
- [ ] Tasks reference correct Node.js version
- [ ] Implementation completed successfully
- [ ] `docs/.nojekyll` still exists
- [ ] DaisyUI still in package.json
- [ ] `.runners-local/` directory intact
- [ ] No branches were deleted
- [ ] All commits follow branch naming (YYYYMMDD-HHMMSS-type-description)

**If all checked**: Delete this folder and celebrate! 🎉

---

**Remember**: The key to success is **immediately fixing the 3 common mistakes** after each spec-kit command. Don't batch them, don't skip them, fix them right away.

Good luck! 🚀
