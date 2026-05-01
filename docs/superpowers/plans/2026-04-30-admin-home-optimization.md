# 管理端首页及列表极简重构实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将管理端（管理员/教练）首页及学员列表页重构为“极简工作台”布局，通过数据磁贴和有序网格提升管理效率。

**Architecture:** 采用组件化重构，引入 `AdminStatTile` (统计磁贴) 和 `AdminMenuTile` (网格菜单)，通过重构首页布局实现数据仪表盘化，并对列表页进行信息层级优化。

**Tech Stack:** uni-app (Vue 3, TypeScript), uview-plus, SCSS.

---

### Task 1: 创建管理端基础磁贴组件

**Files:**
- Create: `Code/mobile-app/src/pages/admin/components/AdminStatTile.vue`
- Create: `Code/mobile-app/src/pages/admin/components/AdminMenuTile.vue`

- [ ] **Step 1: 实现 AdminStatTile 组件**
```vue
<!-- 
支持 label, value, trend (可选) 属性。
采用极简设计，背景色 #FFFFFF，1rpx 细边框 #E2E8F0。
-->
```

- [ ] **Step 2: 实现 AdminMenuTile 组件**
```vue
<!-- 
支持 title, subtitle, icon 属性。
采用 2 列网格布局中的单个项目，背景色 #FFFFFF。
-->
```

- [ ] **Step 3: 提交组件**
```bash
git add Code/mobile-app/src/pages/admin/components/
git commit -m "feat: add AdminStatTile and AdminMenuTile components"
```

### Task 2: 重构管理端首页 (admin/home.vue)

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/home.vue`

- [ ] **Step 1: 引入新组件并重构 Hero 区域**
- [ ] **Step 2: 将统计概览重构为 AdminStatTile 组合布局**
- [ ] **Step 3: 将功能菜单重构为 2 列网格的 AdminMenuTile 布局**
- [ ] **Step 4: 移除冗余样式，应用 #F8FAFC 页面背景色**
- [ ] **Step 5: 提交变更**
```bash
git add Code/mobile-app/src/pages/admin/home.vue
git commit -m "feat: refactor admin home with minimalist dashboard layout"
```

### Task 3: 重构学员列表页 (admin/students/list.vue)

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/students/list.vue`

- [ ] **Step 1: 将筛选区重构为轻量级搜索框 + 筛选抽屉/Picker**
- [ ] **Step 2: 优化列表卡片信息层级，使用标签 (Tag) 展示状态**
- [ ] **Step 3: 简化操作按钮为文本按钮风格**
- [ ] **Step 4: 提交变更**
```bash
git add Code/mobile-app/src/pages/admin/students/list.vue
git commit -m "feat: refactor student list with minimalist professional style"
```

### Task 4: 全局样式优化与清理

**Files:**
- Modify: `Code/mobile-app/src/uni.scss`

- [ ] **Step 1: 增加 $admin-primary-color: #3B82F6 变量**
- [ ] **Step 2: 确保所有管理端按钮和高亮均使用此颜色**
- [ ] **Step 3: 提交最终优化**
```bash
git add Code/mobile-app/src/uni.scss
git commit -m "cleanup: finalize admin side visual optimization"
```
