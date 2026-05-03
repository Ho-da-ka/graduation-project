# Remove English Prefixes from AI Intelligence Briefing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove "mag" (icon) and "AI" prefixes from the "AI 智能简报" badge in the parent-side mini-program to provide a cleaner, Chinese-only interface as requested.

**Architecture:** Modify the `AiDashboardFeed.vue` component to remove the `u-icon` that renders as "mag" and update the badge text to remove "AI".

**Tech Stack:** Vue 3, Uni-app, uView-plus.

---

### Task 1: Update AiDashboardFeed Component

**Files:**
- Modify: `Code/mobile-app/src/pages/parent/components/AiDashboardFeed.vue`

- [ ] **Step 1: Remove the magic-stick icon and update the badge text**

The icon `magic-stick` is rendering as "mag" due to font loading issues. The user also wants to remove "AI".

```vue
<<<<
      <view class="ai-badge">
        <u-icon name="magic-stick" color="#FFFFFF" size="24rpx"></u-icon>
        <text class="badge-text">AI 智能简报</text>
      </view>
====
      <view class="ai-badge">
        <text class="badge-text">智能简报</text>
      </view>
>>>>
```

- [ ] **Step 2: Commit changes**

```bash
git add Code/mobile-app/src/pages/parent/components/AiDashboardFeed.vue
git commit -m "ui: remove English prefixes from AI Intelligence Briefing"
```

### Task 2: Update Growth Index Page (Optional but recommended)

**Files:**
- Modify: `Code/mobile-app/src/pages/parent/growth/index.vue`

- [ ] **Step 1: Remove the magic-stick icon from the generated report badge**

This prevents "mag" from appearing before "DeepSeek 生成" or "真实数据兜底".

```vue
<<<<
          <view class="generated-report-badge">
            <up-icon name="magic-stick" size="24rpx" color="#2563EB" />
            <text>{{ aiReport.generatedByAi ? 'DeepSeek 生成' : '真实数据兜底' }}</text>
          </view>
====
          <view class="generated-report-badge">
            <text>{{ aiReport.generatedByAi ? '成长解析 (DeepSeek)' : '成长解析 (真实数据)' }}</text>
          </view>
>>>>
```

Wait, if I change "DeepSeek" to "(DeepSeek)", it's still English.
Maybe just "AI 生成" or "数据生成"?
The user said "mag等英文". "DeepSeek" is English.
Maybe: `<text>{{ aiReport.generatedByAi ? '智能生成' : '数据解析' }}</text>`

- [ ] **Step 2: Commit changes**

```bash
git add Code/mobile-app/src/pages/parent/growth/index.vue
git commit -m "ui: remove English prefixes and icons from growth report"
```
