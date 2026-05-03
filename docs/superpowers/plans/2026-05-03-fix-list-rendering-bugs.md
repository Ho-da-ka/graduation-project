# Fix Empty Records and Audit List Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the issue where empty cards are displayed in the training record list and ensure all other list pages correctly handle paginated API responses.

**Architecture:** 
- Fix `admin/training/list.vue` to use `data.content` instead of the whole `data` object.
- Check and fix `admin/attendances/list.vue`, `admin/courses/list.vue`, `admin/fitness/list.vue`, and `admin/coaches/list.vue`.

**Tech Stack:** Vue 3, TypeScript, Uni-app.

---

### Task 1: Fix Training Record List

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/training/list.vue`

- [ ] **Step 1: Correct data assignment in fetchData**

```vue
<<<<
    const data = await listTrainingRecords({
      studentName: query.studentName.trim() || undefined
    })
    rows.value = data
====
    const data = await listTrainingRecords({
      studentName: query.studentName.trim() || undefined
    })
    rows.value = data.content || []
>>>>
```

### Task 2: Audit and Fix Attendance List

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/attendances/list.vue` (if needed)

- [ ] **Step 1: Check `fetchData` in `attendances/list.vue`**
- [ ] **Step 2: Apply fix if it incorrectly handles `PageResponse`**

### Task 3: Audit and Fix Courses List

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/courses/list.vue` (if needed)

- [ ] **Step 1: Check `fetchData` in `courses/list.vue`**
- [ ] **Step 2: Apply fix if it incorrectly handles `PageResponse`**

### Task 4: Audit and Fix Fitness Test List

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/fitness/list.vue` (if needed)

- [ ] **Step 1: Check `fetchData` in `fitness/list.vue`**
- [ ] **Step 2: Apply fix if it incorrectly handles `PageResponse`**

### Task 5: Audit and Fix Coaches List

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/coaches/list.vue` (if needed)

- [ ] **Step 1: Check `fetchData` in `coaches/list.vue`**
- [ ] **Step 2: Apply fix if it incorrectly handles `PageResponse`**
