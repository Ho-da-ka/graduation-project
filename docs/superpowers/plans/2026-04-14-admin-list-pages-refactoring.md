# Admin List Pages Minimalist Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor 6 admin list pages into the "Minimalist Workspace" style with sticky headers, card-based lists, and streamlined interactions.

**Architecture:** Each page will feature a sticky header containing a search bar and filter controls. The main content will be a list of cards with `#FFFFFF` background, `24rpx` border-radius, and subtle shadows. Actions will be replaced with bold blue text links.

**Tech Stack:** Vue 3 (Composition API), TypeScript, uni-app, uview-plus.

---

### Task 1: Refactor Students List Page

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/students/list.vue`

- [ ] **Step 1: Apply Minimalist Template and Styles**
Update the template to include a sticky header with `u-search` and a filter icon. Update the list item cards to match the spec. Replace `u-button` actions with `text.action-link`.

- [ ] **Step 2: Update Script Logic**
Ensure all existing API calls, pagination, and filtering logic are preserved. Add helper functions if needed for tag types.

- [ ] **Step 3: Commit**
```bash
git add Code/mobile-app/src/pages/admin/students/list.vue
git commit -m "style: refactor students list to minimalist style"
```

### Task 2: Refactor Courses List Page

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/courses/list.vue`

- [ ] **Step 1: Apply Minimalist Template and Styles**
Apply the same pattern as Task 1 to the courses list.

- [ ] **Step 2: Update Script Logic**
Maintain course-specific logic and API integration.

- [ ] **Step 3: Commit**
```bash
git add Code/mobile-app/src/pages/admin/courses/list.vue
git commit -m "style: refactor courses list to minimalist style"
```

### Task 3: Refactor Coaches List Page

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/coaches/list.vue`

- [ ] **Step 1: Apply Minimalist Template and Styles**
Apply the minimalist pattern, handling the `isAdmin` check for the "Add" and "Edit/Delete" actions.

- [ ] **Step 2: Update Script Logic**
Preserve the delete confirmation logic and role-based visibility.

- [ ] **Step 3: Commit**
```bash
git add Code/mobile-app/src/pages/admin/coaches/list.vue
git commit -m "style: refactor coaches list to minimalist style"
```

### Task 4: Refactor Attendances List Page

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/attendances/list.vue`

- [ ] **Step 1: Apply Minimalist Template and Styles**
Adapt the sticky header to accommodate student and course filters. Since there's no text search, use the header for primary filters.

- [ ] **Step 2: Update Script Logic**
Preserve the option loading and date range filtering logic.

- [ ] **Step 3: Commit**
```bash
git add Code/mobile-app/src/pages/admin/attendances/list.vue
git commit -m "style: refactor attendances list to minimalist style"
```

### Task 5: Refactor Fitness Tests List Page

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/fitness/list.vue`

- [ ] **Step 1: Apply Minimalist Template and Styles**
Apply the minimalist pattern for fitness test records.

- [ ] **Step 2: Update Script Logic**
Ensure student filtering and data fetching remain functional.

- [ ] **Step 3: Commit**
```bash
git add Code/mobile-app/src/pages/admin/fitness/list.vue
git commit -m "style: refactor fitness list to minimalist style"
```

### Task 6: Refactor Training Records List Page

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/training/list.vue`

- [ ] **Step 1: Apply Minimalist Template and Styles**
Apply the minimalist pattern, ensuring intensity levels are displayed as tags.

- [ ] **Step 2: Update Script Logic**
Preserve the complex filtering and detailed record display logic.

- [ ] **Step 3: Commit**
```bash
git add Code/mobile-app/src/pages/admin/training/list.vue
git commit -m "style: refactor training list to minimalist style"
```
