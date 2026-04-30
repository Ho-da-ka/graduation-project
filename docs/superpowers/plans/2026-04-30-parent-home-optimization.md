# 家长首页极简专业化 (方案 A) 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将家长首页重构为以垂直时间轴为核心的极简专业布局，突出日程安排和课后反馈。

**Architecture:** 采用组件化重构方案，引入横向滚动日期条（DateStrip）和垂直时间轴项（TimelineItem），通过重构数据处理逻辑确保日程按时间精确排序并区分过去/未来状态。

**Tech Stack:** uni-app (Vue 3, TypeScript), uview-plus, SCSS.

---

### Task 1: 更新数据类型与工具函数

**Files:**
- Modify: `Code/mobile-app/src/types/parent-home.ts`
- Modify: `Code/mobile-app/src/utils/parent-home.ts`

- [ ] **Step 1: 更新 ParentHomeHero 类型，移除多余字段，增加日期支持**
```typescript
// Code/mobile-app/src/types/parent-home.ts
export interface ParentHomeHero {
  selectedDate: string; // YYYY-MM-DD
  unreadCount: number;
}
```

- [ ] **Step 2: 更新日程项类型，增加状态和报告链接字段**
```typescript
// Code/mobile-app/src/types/parent-home.ts
export interface ParentHomeTimelineItem {
  id: number;
  time: string;       // HH:mm
  date: string;       // YYYY-MM-DD
  title: string;
  coach: string;
  location: string;
  status: 'past' | 'upcoming' | 'ongoing';
  reportUrl?: string; // 课后反馈报告链接
}
```

- [ ] **Step 3: 重构 buildParentHomeDashboard 逻辑，按日期过滤和排序数据**
```typescript
// Code/mobile-app/src/utils/parent-home.ts
// 修改 buildParentHomeDashboard 函数，使其返回按日期分组的 timeline 数据
```

- [ ] **Step 4: 提交变更**
```bash
git add Code/mobile-app/src/types/parent-home.ts Code/mobile-app/src/utils/parent-home.ts
git commit -m "refactor: update parent home types and data processing for timeline"
```

### Task 2: 创建极简日期选择条 (ParentDateStrip)

**Files:**
- Create: `Code/mobile-app/src/pages/parent/components/ParentDateStrip.vue`

- [ ] **Step 1: 实现横向滚动的日期选择组件**
```vue
<!-- 
使用 <scroll-view scroll-x> 实现。
仅显示日期数字和星期简称。
选中项带下划线标识。
-->
```

- [ ] **Step 2: 提交组件**
```bash
git add Code/mobile-app/src/pages/parent/components/ParentDateStrip.vue
git commit -m "feat: add ParentDateStrip component"
```

### Task 3: 创建时间轴日程组件 (TimelineItem)

**Files:**
- Create: `Code/mobile-app/src/pages/parent/components/TimelineItem.vue`

- [ ] **Step 1: 实现垂直时间轴单项 UI**
```vue
<!-- 
左侧显示时间文字。
中间显示垂直细线和圆点。
右侧显示日程卡片，支持 past 状态置灰和“查看报告”链接。
-->
```

- [ ] **Step 2: 提交组件**
```bash
git add Code/mobile-app/src/pages/parent/components/TimelineItem.vue
git commit -m "feat: add TimelineItem component"
```

### Task 4: 重构家长首页 (parent/home.vue)

**Files:**
- Modify: `Code/mobile-app/src/pages/parent/home.vue`

- [ ] **Step 1: 移除旧的 Hero 和 Grid 组件引用，引入新组件**
- [ ] **Step 2: 实现吸顶布局逻辑 (position: sticky)**
- [ ] **Step 3: 绑定日期切换事件，联动数据更新**
- [ ] **Step 4: 应用极简背景色和间距规范**
- [ ] **Step 5: 提交变更**
```bash
git add Code/mobile-app/src/pages/parent/home.vue
git commit -m "feat: refactor parent home with new minimalist timeline layout"
```

### Task 5: 视觉微调与清理

**Files:**
- Modify: `Code/mobile-app/src/uni.scss`
- Delete: `Code/mobile-app/src/pages/parent/components/ParentHomeHero.vue` (不再使用)
- Delete: `Code/mobile-app/src/pages/parent/components/ParentHomeMetricGrid.vue` (不再使用)

- [ ] **Step 1: 优化全局配色变量**
- [ ] **Step 2: 删除冗余组件**
- [ ] **Step 3: 运行开发服务器验证 UI 效果**
- [ ] **Step 4: 提交最终清理**
```bash
git commit -m "cleanup: remove unused components and optimize styles"
```
