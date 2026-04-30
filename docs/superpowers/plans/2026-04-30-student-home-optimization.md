# 学生端首页极简活力化 (方案 A) 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将学生端首页重构为“行动中心型”极简布局，突出今日训练计划并辅以月度进度可视化。

**Architecture:** 采用组件化重构，引入 StudentActionHub (包含进度环和今日课程) 和 StudentFeatureTile (磁贴式入口)，通过重构数据处理逻辑计算训练进度。

**Tech Stack:** uni-app (Vue 3, TypeScript), uview-plus, SCSS.

---

### Task 1: 定义学生端视图模型与工具函数

**Files:**
- Create: `Code/mobile-app/src/types/student-home.ts`
- Create: `Code/mobile-app/src/utils/student-home.ts`

- [ ] **Step 1: 定义 StudentHomeDashboard 接口**
```typescript
export interface StudentHomeDashboard {
  progress: number; // 0-100
  todayCourse: {
    id?: number;
    name: string;
    time: string;
    location: string;
    status: 'none' | 'upcoming' | 'ongoing' | 'completed';
    ctaLabel: string;
  };
  stats: {
    label: string;
    value: string;
  }[];
}
```

- [ ] **Step 2: 实现 buildStudentHomeDashboard 工具函数**
```typescript
// 计算逻辑：
// 1. progress: 本月已签到课程数 / 本月总课数 (若总数为0则为0)
// 2. todayCourse: 查找今日开始的第一个 BOOKED 状态课程
```

- [ ] **Step 3: 提交变更**
```bash
git add Code/mobile-app/src/types/student-home.ts Code/mobile-app/src/utils/student-home.ts
git commit -m "feat: add student home types and utility functions"
```

### Task 2: 创建极简进度环组件 (StudentProgressCircle)

**Files:**
- Create: `Code/mobile-app/src/pages/student/components/StudentProgressCircle.vue`

- [ ] **Step 1: 使用 CSS 实现极细线条进度环**
```vue
<!-- 
使用圆环 SVG 或 CSS border-radius。
橙色 (#F97316) 展示进度。
中心显示百分比文本。
-->
```

- [ ] **Step 2: 提交组件**
```bash
git add Code/mobile-app/src/pages/student/components/StudentProgressCircle.vue
git commit -m "feat: add StudentProgressCircle component"
```

### Task 3: 创建行动中心卡片 (StudentActionHub)

**Files:**
- Create: `Code/mobile-app/src/pages/student/components/StudentActionHub.vue`

- [ ] **Step 1: 整合进度环与课程信息**
```vue
<!-- 
左侧：StudentProgressCircle。
右侧：课程标题、时间、地点。
底部：大号橙色渐变按钮。
-->
```

- [ ] **Step 2: 提交组件**
```bash
git add Code/mobile-app/src/pages/student/components/StudentActionHub.vue
git commit -m "feat: add StudentActionHub component"
```

### Task 4: 重构学生端首页 (student/home.vue)

**Files:**
- Modify: `Code/mobile-app/src/pages/student/home.vue`

- [ ] **Step 1: 替换旧的统计格子和按钮列表**
- [ ] **Step 2: 引入 StudentActionHub 和磁贴导航**
- [ ] **Step 3: 绑定刷新与跳转逻辑**
- [ ] **Step 4: 提交变更**
```bash
git add Code/mobile-app/src/pages/student/home.vue
git commit -m "feat: refactor student home with minimalist action-hub layout"
```

### Task 5: 最终清理与验证

**Files:**
- Modify: `Code/mobile-app/src/pages/student/home.vue` (样式微调)

- [ ] **Step 1: 确保整体配色与设计稿一致**
- [ ] **Step 2: 运行类型检查与测试**
- [ ] **Step 3: 提交清理**
```bash
git commit -m "cleanup: finalize student home redesign"
```
