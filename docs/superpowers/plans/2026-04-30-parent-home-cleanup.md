# Parent Home Cleanup and Style Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean up unused components and types, and optimize global styles for a minimalist professional theme.

**Architecture:** Remove legacy components replaced by the timeline layout, clean up the associated types and utility logic, and update global SCSS variables.

**Tech Stack:** Vue 3, TypeScript, SCSS, uni-app

---

### Task 1: Update Global Styles

**Files:**
- Modify: `Code/mobile-app/src/uni.scss`

- [ ] **Step 1: Refine global color variables**

Update `Code/mobile-app/src/uni.scss` to ensure the primary color is a crisp, professional blue and add any necessary tokens.

```scss
$uni-color-primary: #2563eb;
$uni-color-success: #16a34a;
$uni-color-warning: #d97706;
$uni-color-error: #dc2626;

// Professional Gray scale if needed
$uni-bg-color-grey: #f9fafb;
$uni-text-color-placeholder: #9ca3af;
```

- [ ] **Step 2: Commit changes**

```bash
git add Code/mobile-app/src/uni.scss
git commit -m "style: optimize global color variables for minimalist theme"
```

---

### Task 2: Remove Unused Components

**Files:**
- Delete: `Code/mobile-app/src/pages/parent/components/ParentHomeHero.vue`
- Delete: `Code/mobile-app/src/pages/parent/components/ParentHomeMetricGrid.vue`

- [ ] **Step 1: Delete the legacy component files**

- [ ] **Step 2: Commit deletion**

```bash
git rm Code/mobile-app/src/pages/parent/components/ParentHomeHero.vue Code/mobile-app/src/pages/parent/components/ParentHomeMetricGrid.vue
git commit -m "cleanup: remove unused legacy home components"
```

---

### Task 3: Clean Up Types and Utilities

**Files:**
- Modify: `Code/mobile-app/src/types/parent-home.ts`
- Modify: `Code/mobile-app/src/utils/parent-home.ts`

- [ ] **Step 1: Remove `ParentHomeHero` type if it's no longer used for components**

Since the component is gone and `home.vue` uses its own `selectedDate`, we can remove it from the dashboard interface.

In `Code/mobile-app/src/types/parent-home.ts`:
Remove `ParentHomeHero` interface.
Remove `hero` from `ParentHomeDashboard`.

- [ ] **Step 2: Update `buildParentHomeDashboard` in `Code/mobile-app/src/utils/parent-home.ts`**

Remove the `hero` property from the returned object.

- [ ] **Step 3: Commit cleanup**

```bash
git add Code/mobile-app/src/types/parent-home.ts Code/mobile-app/src/utils/parent-home.ts
git commit -m "cleanup: remove unused ParentHomeHero types and utility logic"
```

---

### Task 4: Final Verification and Project Build

- [ ] **Step 1: Scan `Code/mobile-app/src/pages/parent/home.vue` for unused imports or styles**

(I already did this, but will double check).

- [ ] **Step 2: Build the project to ensure no errors**

Run: `npm -C Code/mobile-app run build:h5` (or equivalent)

- [ ] **Step 3: Verify no references to deleted components remain**

Run: `grep -r "ParentHomeHero" Code/mobile-app/src`
Expected: No matches (except maybe in docs/plans).

- [ ] **Step 4: Commit final cleanup**

```bash
git commit --allow-empty -m "cleanup: final code scan and verification complete"
```
