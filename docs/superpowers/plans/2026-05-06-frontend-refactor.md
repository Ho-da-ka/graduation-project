# 前端视觉与交互重构实施计划 (Modern Professional)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将管理后台重构为“现代专业感”风格，提升视觉美感与操作效率。

**Architecture:** 基于 Element Plus 的深度定制重构。通过全局 CSS 变量统一视觉规范，重写核心布局与关键视图，优化数据可视化展示。

**Tech Stack:** Vue 3, Element Plus, ECharts, SCSS (via sass-embedded)

---

### Task 1: 定义全局设计系统 (Styles & Variables)

**Files:**
- Modify: `Code/admin-panel/src/styles.css`

- [ ] **Step 1: 更新全局 CSS 变量与基础样式**
将设计规范中的色彩、圆角和投影定义为 CSS 变量，并覆写 Element Plus 的基础组件样式（按钮、输入框、卡片）。

```css
:root {
  /* Colors - Slate & Blue Palette */
  --admin-bg: #f8fafc;
  --admin-sidebar-bg: #ffffff;
  --admin-sidebar-text: #64748b;
  --admin-sidebar-active: #3b82f6;
  --admin-sidebar-active-bg: #eff6ff;
  --admin-primary: #3b82f6;
  --admin-primary-light: rgba(59, 130, 246, 0.1);
  --admin-purple: #8b5cf6;
  --admin-border: #e2e8f0;
  --admin-card-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
  --admin-card-hover-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.08);
  --color-text: #1e293b;
  --color-muted: #64748b;
  --border-radius: 16px;
  --border-radius-sm: 8px;
}

/* Base Overrides */
html, body, #app {
  background-color: var(--admin-bg);
  color: var(--color-text);
  -webkit-font-smoothing: antialiased;
}

/* Card Overrides - Remove border, add soft shadow */
.el-card {
  border: 1px solid var(--admin-border) !important;
  border-radius: var(--border-radius) !important;
  box-shadow: var(--admin-card-shadow) !important;
  transition: all 0.3s ease;
}
.el-card:hover {
  box-shadow: var(--admin-card-hover-shadow) !important;
  transform: translateY(-2px);
}
.el-card__header {
  border-bottom: 1px solid var(--admin-border) !important;
  padding: 16px 24px !important;
  background-color: #ffffff;
}

/* Button & Input Overrides */
.el-button { border-radius: var(--border-radius-sm) !important; font-weight: 600 !important; }
.el-input__wrapper { border-radius: var(--border-radius-sm) !important; box-shadow: 0 0 0 1px var(--admin-border) inset !important; }
```

- [ ] **Step 2: 验证样式加载**
运行 `npm run dev`（如果在开发环境下）或检查文件内容。
Expected: `styles.css` 已更新。

- [ ] **Step 3: Commit**
```bash
git add Code/admin-panel/src/styles.css
git commit -m "style: define global design variables and basic overrides"
```

### Task 2: 全局布局重构 (AdminLayout.vue)

**Files:**
- Modify: `Code/admin-panel/src/layouts/AdminLayout.vue`

- [ ] **Step 1: 实现浅色卡片式侧边栏**
修改 `AdminLayout.vue` 的 template 和 style 部分，将侧边栏背景改为白色，优化菜单激活态。

```vue
<!-- Template changes: Update classes and structure -->
<el-aside class="sidebar" width="260px">
  <div class="logo-area">
    <div class="logo-box">ZF</div>
    <div class="logo-text">教务管理平台</div>
  </div>
  <el-menu :default-active="activePath" router class="menu">
    <!-- ... same items ... -->
  </el-menu>
  <!-- New User Info at Bottom -->
  <div class="sidebar-footer">
    <div class="user-card">
      <el-avatar :size="32" src="" />
      <div class="user-meta">
        <div class="user-name">{{ username }}</div>
        <div class="user-role">{{ roleLabel }}</div>
      </div>
    </div>
  </div>
</el-aside>
```

```scss
/* Scoped Style Overrides */
.sidebar {
  background-color: var(--admin-sidebar-bg);
  border-right: 1px solid var(--admin-border);
  box-shadow: none;
}
.menu :deep(.el-menu-item) {
  margin: 4px 12px;
  border-radius: 12px;
  color: var(--admin-sidebar-text);
}
.menu :deep(.el-menu-item.is-active) {
  background-color: var(--admin-sidebar-active-bg);
  color: var(--admin-sidebar-active);
  font-weight: 700;
}
```

- [ ] **Step 2: 运行构建校验**
Run: `npm run build` (在 `Code/admin-panel` 目录下)
Expected: 构建成功无错误。

- [ ] **Step 3: Commit**
```bash
git add Code/admin-panel/src/layouts/AdminLayout.vue
git commit -m "refactor: implement light card-style layout"
```

### Task 3: 仪表盘重构 (DashboardView.vue)

**Files:**
- Modify: `Code/admin-panel/src/views/DashboardView.vue`

- [ ] **Step 1: 实现 2:1 响应式分栏布局**
修改布局结构，左侧放置核心图表，右侧放置提醒列表。

- [ ] **Step 2: 优化统计卡片视觉**
移除背景色，增强数字字重，增加趋势指示器（+XX%）。

- [ ] **Step 3: 定制 ECharts 主题**
在 `onMounted` 中修改 `attendanceOption` 等配置，移除坐标轴边框，使用渐变色。

- [ ] **Step 4: 运行构建校验**
Run: `npm run build`
Expected: 编译通过。

- [ ] **Step 5: Commit**
```bash
git add Code/admin-panel/src/views/DashboardView.vue
git commit -m "refactor: dashboard with 2:1 layout and polished charts"
```

### Task 4: AI 智慧中心重构 (AiAnalysisHub.vue)

**Files:**
- Modify: `Code/admin-panel/src/views/ai/AiAnalysisHub.vue`

- [ ] **Step 1: 应用浅色专业版样式**
移除深色尝试的残留，统一使用白底蓝/紫点缀。

- [ ] **Step 2: 优化 AI 发现 Feed 流**
将提醒列表改为更具“实时感”的垂直卡片流。

- [ ] **Step 3: Commit**
```bash
git add Code/admin-panel/src/views/ai/AiAnalysisHub.vue
git commit -m "refactor: AI Hub with unified light professional style"
```
