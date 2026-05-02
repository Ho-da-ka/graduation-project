# Web端视觉重塑与全平台 AI 集成实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 Web 端全局视觉升级（高端极简），并在 Web 端和移动端深度集成 AI 成长分析入口。

**Architecture:** 
- **Web 端**: 基于 Vue 3 + Element Plus，重构全局布局与样式系统，开发独立的 AI 业务组件。
- **移动端**: 基于 uni-app + uview-plus，在首页时间轴集成 AI 简报卡片。
- **后端**: 调用 `GeneratedContentService` 提供的 AI 文本生成能力。

**Tech Stack:** Vue 3, Vite, Element Plus, Tailwind CSS (if used), uni-app, uview-plus.

---

### Task 1: Web 端全局视觉系统重构 (P1)

**Files:**
- Modify: `Code/admin-panel/src/styles.css` (or `main.css`)
- Modify: `Code/admin-panel/src/layouts/AdminLayout.vue`

- [ ] **Step 1: 更新全局 CSS 变量与重置样式**
```css
/* 设置 Premium Minimalism 配色 */
:root {
  --admin-bg: #F8FAFC;
  --admin-card-shadow: 0 4px 20rpx rgba(0, 0, 0, 0.02);
  --admin-primary: #3B82F6;
}
body { background-color: var(--admin-bg); }
```

- [ ] **Step 2: 重构侧边栏 (Sidebar) 样式**
```vue
<!-- 将侧边栏改为极简悬浮风格或细线条风格 -->
```

- [ ] **Step 3: 优化主工作区卡片容器**
```vue
<!-- 应用统一的圆角 (12px) 和微影样式 -->
```

- [ ] **Step 4: 提交 P1 视觉变更**
```bash
git add Code/admin-panel/src/
git commit -m "style: overhaul web visual system to premium minimalism"
```

### Task 2: 实现学员详情页 AI 智能综述 (P2)

**Files:**
- Create: `Code/admin-panel/src/components/ai/AiStudentInsights.vue`
- Modify: `Code/admin-panel/src/views/students/StudentProfileView.vue`

- [ ] **Step 1: 开发 AiStudentInsights 通用组件**
```vue
<!-- 
包含流式文字加载动画。
调用后台 AI 接口获取学员成长总结。
视觉：紫色渐变边框卡片。
-->
```

- [ ] **Step 2: 集成至学员档案顶部**
- [ ] **Step 3: 提交 AI 综述功能**
```bash
git add Code/admin-panel/src/
git commit -m "feat: integrate AI insights card to student profile"
```

### Task 3: 实现录入页 AI 魔法助手 (P2)

**Files:**
- Create: `Code/admin-panel/src/components/ai/AiMagicPen.vue`
- Modify: `Code/admin-panel/src/views/fitness/FitnessView.vue`
- Modify: `Code/admin-panel/src/views/training/TrainingRecordView.vue`

- [ ] **Step 1: 开发 AiMagicPen 悬浮/行内助手组件**
```vue
<!-- 
点击后读取表单数值，调用 AI 生成建议文本。
支持“一键填入”功能。
-->
```

- [ ] **Step 2: 在体测和训练录入表单中集成**
- [ ] **Step 3: 提交 AI 魔法助手**
```bash
git add Code/admin-panel/src/
git commit -m "feat: add AI magic pen assistant to data entry"
```

### Task 4: 创建 Web 端 AI 智慧中心 (P2)

**Files:**
- Create: `Code/admin-panel/src/views/ai/AiAnalysisHub.vue`
- Modify: `Code/admin-panel/src/router/index.js`

- [ ] **Step 1: 实现智慧分析中心看板布局**
- [ ] **Step 2: 注册路由并在侧边栏添加入口**
- [ ] **Step 3: 提交 AI Hub**
```bash
git add Code/admin-panel/src/
git commit -m "feat: add dedicated AI analysis hub"
```

### Task 5: 移动端 AI 智能简报集成 (P3)

**Files:**
- Create: `Code/mobile-app/src/pages/parent/components/AiDashboardFeed.vue`
- Modify: `Code/mobile-app/src/pages/parent/home.vue`

- [ ] **Step 1: 开发移动端 AI 简报卡片组件**
```vue
<!-- 极简高亮设计，带 AI 动画效果 -->
```

- [ ] **Step 2: 在家长首页时间轴顶部挂载组件**
- [ ] **Step 3: 实现流式内容加载逻辑**
- [ ] **Step 4: 提交移动端集成**
```bash
git add Code/mobile-app/src/
git commit -m "feat: integrate AI dashboard feed to mobile app"
```

### Task 6: 全平台联调与验证

- [ ] **Step 1: 验证全量编译与 API 连通性**
- [ ] **Step 2: 运行所有端 (Web & MP) 的视觉回归检查**
- [ ] **Step 3: 提交最终优化**
```bash
git commit -m "cleanup: finalize all-in-one web and ai integration"
```
