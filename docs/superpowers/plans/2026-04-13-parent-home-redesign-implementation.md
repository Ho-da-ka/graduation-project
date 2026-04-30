# Parent Home Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the mini-program parent home page into a child-focused service dashboard that surfaces growth summary, quick actions, and recent updates without adding a homepage-only AI gimmick.

**Architecture:** Keep `Code/mobile-app/src/pages/parent/home.vue` as the container page, move child-selection persistence and dashboard summary rules into a focused utility module, and render the redesigned sections through small local page components. Reuse the existing parent APIs plus `growthOverview` on the client, and add a minimal Vitest harness so the selection logic and dashboard copy rules are covered before the UI wiring lands.

**Tech Stack:** uni-app CLI, Vue 3 + TypeScript, uview-plus, Vite, Vitest

---

## File Structure

- `Code/mobile-app/package.json`
  Adds a `test:unit` script so the dashboard rules can be exercised without a full mini-program build.
- `Code/mobile-app/package-lock.json`
  Locks the Vitest dependency introduced for the new unit tests.
- `Code/mobile-app/vitest.config.ts`
  Provides a Node-based Vitest config with the existing `@` alias mapped to `src/`.
- `Code/mobile-app/src/types/parent-home.ts`
  Defines the dashboard view-model types shared by the utility layer and the page-local components.
- `Code/mobile-app/src/utils/parent-home.ts`
  Owns persisted current-child selection, empty-state generation, action definitions, and dashboard summary derivation.
- `Code/mobile-app/src/utils/parent-home.test.ts`
  Covers child selection, storage fallback, summary metric generation, next-course prioritization, and empty-state output.
- `Code/mobile-app/src/pages/parent/components/ParentHomeHero.vue`
  Renders the child hero card, headline copy, reminder badge, and child switch chips.
- `Code/mobile-app/src/pages/parent/components/ParentHomeMetricGrid.vue`
  Renders the three summary metric cards.
- `Code/mobile-app/src/pages/parent/components/ParentHomeActionSection.vue`
  Renders primary and secondary quick actions in the approved information order.
- `Code/mobile-app/src/pages/parent/components/ParentHomeActivityCard.vue`
  Renders the “recent update” and “to-do” cards with CTA buttons.
- `Code/mobile-app/src/pages/parent/home.vue`
  Fetches parent data, resolves the current child, builds the dashboard view model, handles loading/error/empty states, and composes the local components.

## Task 1: Add A Lightweight Unit-Test Harness

**Files:**
- Create: `Code/mobile-app/vitest.config.ts`
- Create: `Code/mobile-app/src/utils/parent-home.ts`
- Create: `Code/mobile-app/src/utils/parent-home.test.ts`
- Modify: `Code/mobile-app/package.json`
- Modify: `Code/mobile-app/package-lock.json`

- [ ] **Step 1: Write the failing test**

```ts
// Code/mobile-app/src/utils/parent-home.test.ts
import { describe, expect, it } from 'vitest'
import { resolveCurrentParentStudentId } from './parent-home'

describe('resolveCurrentParentStudentId', () => {
  it('falls back to the first bound child when there is no preferred id', () => {
    const children = [{ id: 11, name: '乐乐' }, { id: 22, name: '安安' }] as Array<{ id: number; name: string }>
    expect(resolveCurrentParentStudentId(children, null)).toBe(11)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd Code/mobile-app
npx vitest run src/utils/parent-home.test.ts
```

Expected: FAIL with a missing `vitest` package and/or missing `./parent-home` module.

- [ ] **Step 3: Write minimal implementation**

```json
// Code/mobile-app/package.json
{
  "scripts": {
    "dev:mp-weixin": "uni -p mp-weixin",
    "build:mp-weixin": "uni build -p mp-weixin",
    "type-check": "vue-tsc --noEmit",
    "test:unit": "vitest run"
  },
  "devDependencies": {
    "@dcloudio/types": "3.4.19",
    "@dcloudio/uni-app": "3.0.0-4080720251210001",
    "@dcloudio/uni-mp-weixin": "^3.0.0-4080720251210001",
    "@dcloudio/vite-plugin-uni": "3.0.0-4080720251210001",
    "@types/crypto-js": "^4.2.2",
    "@types/node": "^25.2.3",
    "sass": "^1.97.3",
    "typescript": "^5.4.2",
    "vite": "5.2.8",
    "vitest": "^2.1.8",
    "vue-tsc": "^2.0.6"
  }
}
```

```ts
// Code/mobile-app/vitest.config.ts
import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts']
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  }
})
```

```ts
// Code/mobile-app/src/utils/parent-home.ts
export function resolveCurrentParentStudentId(children: Array<{ id: number }>, preferredId?: number | null): number | null {
  if (!children.length) return null
  if (preferredId && children.some((child) => child.id === preferredId)) {
    return preferredId
  }
  return children[0].id
}
```

Then update the lockfile:

```bash
cd Code/mobile-app
npm install
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
cd Code/mobile-app
npm run test:unit -- src/utils/parent-home.test.ts
```

Expected: PASS with `1 passed`.

- [ ] **Step 5: Commit**

```bash
git -C Code/mobile-app add package.json package-lock.json vitest.config.ts src/utils/parent-home.ts src/utils/parent-home.test.ts
git -C Code/mobile-app commit -m "test: add parent home dashboard harness"
```

## Task 2: Implement Child Selection Persistence And Dashboard View-Model Rules

**Files:**
- Create: `Code/mobile-app/src/types/parent-home.ts`
- Modify: `Code/mobile-app/src/utils/parent-home.ts`
- Modify: `Code/mobile-app/src/utils/parent-home.test.ts`

- [ ] **Step 1: Write the failing tests**

```ts
// Code/mobile-app/src/utils/parent-home.test.ts
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  buildParentHomeDashboard,
  clearStoredParentHomeStudentId,
  readStoredParentHomeStudentId,
  resolveCurrentParentStudentId,
  writeStoredParentHomeStudentId
} from './parent-home'

const storage = new Map<string, string>()

beforeEach(() => {
  storage.clear()
  vi.stubGlobal('uni', {
    getStorageSync: vi.fn((key: string) => storage.get(key) ?? ''),
    setStorageSync: vi.fn((key: string, value: string) => {
      storage.set(key, value)
    }),
    removeStorageSync: vi.fn((key: string) => {
      storage.delete(key)
    })
  })
})

afterEach(() => {
  vi.unstubAllGlobals()
})

describe('child selection persistence', () => {
  it('uses a stored child id when the child is still bound', () => {
    writeStoredParentHomeStudentId(22)
    const children = [{ id: 11 }, { id: 22 }] as Array<{ id: number }>

    expect(readStoredParentHomeStudentId()).toBe(22)
    expect(resolveCurrentParentStudentId(children, readStoredParentHomeStudentId())).toBe(22)
  })

  it('clears an invalid stored child id and falls back to the first bound child', () => {
    writeStoredParentHomeStudentId(99)
    const children = [{ id: 11 }, { id: 22 }] as Array<{ id: number }>

    expect(resolveCurrentParentStudentId(children, readStoredParentHomeStudentId())).toBe(11)
    expect(storage.has('zf_parent_home_student_id')).toBe(false)
  })
})

describe('buildParentHomeDashboard', () => {
  it('prefers the current child booked course over the generic course list when building hero meta', () => {
    const dashboard = buildParentHomeDashboard({
      child: {
        id: 11,
        studentNo: 'S001',
        name: '乐乐',
        gender: 'MALE',
        birthDate: '2015-05-01',
        guardianName: '张女士',
        guardianPhone: '13800000000',
        status: 'ACTIVE'
      },
      overview: null,
      messages: [{ id: 1, title: '提醒', content: '请查看反馈', msgType: 'REMINDER', read: false, createdAt: '2026-04-13T09:00:00' }],
      bookings: [{
        id: 8,
        studentId: 11,
        studentName: '乐乐',
        courseId: 101,
        courseName: '爆发力专项',
        bookingStatus: 'BOOKED',
        courseCapacity: 20,
        bookingRemark: '',
        checkinStatus: 'PENDING',
        createdAt: '2026-04-13T08:00:00'
      }],
      courses: [{
        id: 101,
        courseCode: 'C-101',
        name: '爆发力专项',
        courseType: 'GROUP',
        coachName: '李教练',
        venue: 'A馆',
        startTime: '2026-04-14T18:30:00',
        durationMinutes: 60,
        status: 'PLANNED',
        description: '',
        capacity: 20,
        bookedCount: 10,
        availableCount: 10
      }],
      fitnessRecords: [{
        id: 5,
        studentId: 11,
        studentName: '乐乐',
        testDate: '2026-04-12',
        itemName: '坐位体前屈',
        testValue: 18,
        unit: 'cm',
        comment: '较上次稳定'
      }]
    })

    expect(dashboard.hero.meta).toContain('2026-04-14 18:30')
    expect(dashboard.metrics.map((item) => item.label)).toEqual(['本周出勤', '最新体测', '待处理事项'])
    expect(dashboard.todo.summary).toContain('查看最新训练反馈')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd Code/mobile-app
npm run test:unit -- src/utils/parent-home.test.ts
```

Expected: FAIL with missing exports such as `writeStoredParentHomeStudentId`, `buildParentHomeDashboard`, and `clearStoredParentHomeStudentId`.

- [ ] **Step 3: Write minimal implementation**

```ts
// Code/mobile-app/src/types/parent-home.ts
import type { ParentBooking, ParentChild, ParentCourse, ParentMessage } from '@/api/modules/parent'
import type { FitnessTestRecord, ParentGrowthOverview } from '@/types/parent'

export interface ParentHomeMetric {
  key: 'attendance' | 'fitness' | 'todo'
  label: string
  value: string
  hint: string
  tone: 'teal' | 'blue' | 'amber'
}

export interface ParentHomeAction {
  key: string
  label: string
  hint: string
  url: string
  variant: 'primary' | 'secondary'
  badge?: string
}

export interface ParentHomeHero {
  label: string
  title: string
  status: string
  meta: string
  unreadCount: number
}

export interface ParentHomeActivity {
  title: string
  summary: string
  caption: string
  ctaLabel: string
  ctaUrl: string
}

export interface ParentHomeEmptyState {
  title: string
  description: string
  ctaLabel: string
  ctaUrl: string
}

export interface ParentHomeDashboard {
  hero: ParentHomeHero
  metrics: ParentHomeMetric[]
  primaryActions: ParentHomeAction[]
  secondaryActions: ParentHomeAction[]
  latestUpdate: ParentHomeActivity
  todo: ParentHomeActivity
  emptyState: ParentHomeEmptyState | null
}

export interface ParentHomeDashboardInput {
  child: ParentChild | null
  overview: ParentGrowthOverview | null
  messages: ParentMessage[]
  bookings: ParentBooking[]
  courses: ParentCourse[]
  fitnessRecords: FitnessTestRecord[]
}
```

```ts
// Code/mobile-app/src/utils/parent-home.ts
import type { ParentBooking, ParentChild, ParentCourse, ParentMessage } from '@/api/modules/parent'
import type { FitnessTestRecord } from '@/types/parent'
import type { ParentHomeAction, ParentHomeDashboard, ParentHomeDashboardInput, ParentHomeMetric } from '@/types/parent-home'

const CURRENT_CHILD_KEY = 'zf_parent_home_student_id'

const PRIMARY_ACTIONS: ParentHomeAction[] = [
  { key: 'courses', label: '课程预约', hint: '查看可预约课程', url: '/pages/parent/courses/list', variant: 'primary' },
  { key: 'growth', label: '成长总览', hint: '查看阶段表现', url: '/pages/parent/growth/index', variant: 'primary' },
  { key: 'checkin', label: '签到记录', hint: '查看到课情况', url: '/pages/parent/checkin/list', variant: 'primary' },
  { key: 'children', label: '我的孩子', hint: '切换孩子档案', url: '/pages/parent/children/list', variant: 'primary' }
]

const SECONDARY_ACTIONS: ParentHomeAction[] = [
  { key: 'fitness', label: '体测记录', hint: '查看最新体测', url: '/pages/parent/fitness/list', variant: 'secondary' },
  { key: 'bookings', label: '预约记录', hint: '查看预约状态', url: '/pages/parent/bookings/list', variant: 'secondary' },
  { key: 'messages', label: '站内消息', hint: '查看通知提醒', url: '/pages/parent/messages/list', variant: 'secondary' }
]

function formatDateTime(value?: string): string {
  return value ? value.replace('T', ' ') : '暂无近期课程'
}

function getWeekAttendance(bookings: ParentBooking[], childId: number): string {
  const recentBookings = bookings.filter((item) => item.studentId === childId && item.bookingStatus === 'BOOKED')
  const checkedIn = recentBookings.filter((item) => item.checkinStatus === 'CHECKED_IN').length
  if (!recentBookings.length) return '暂无记录'
  return `${checkedIn} / ${recentBookings.length} 次`
}

function getLatestFitnessSignal(fitnessRecords: FitnessTestRecord[]): { value: string; hint: string } {
  const latest = [...fitnessRecords].sort((a, b) => b.testDate.localeCompare(a.testDate))[0]
  if (!latest) {
    return { value: '暂无体测', hint: '等待新体测记录' }
  }
  return {
    value: latest.itemName,
    hint: latest.comment?.trim() || `${latest.testValue}${latest.unit}`
  }
}

function buildTodoSummary(messages: ParentMessage[], bookings: ParentBooking[], childId: number): { value: string; hint: string; summary: string } {
  const unreadCount = messages.filter((item) => !item.read).length
  const pendingCheckin = bookings.filter((item) => item.studentId === childId && item.bookingStatus === 'BOOKED' && item.checkinStatus === 'PENDING').length
  const parts: string[] = []
  if (unreadCount > 0) parts.push(`有 ${unreadCount} 条新消息待确认`)
  if (pendingCheckin > 0) parts.push(`本周还有 ${pendingCheckin} 条签到待确认`)
  if (!parts.length) parts.push('查看最新训练反馈')
  return {
    value: `${unreadCount + pendingCheckin} 项`,
    hint: parts[0],
    summary: parts.join('；')
  }
}

function getNextCourseMeta(child: ParentChild, bookings: ParentBooking[], courses: ParentCourse[]): string {
  const booking = bookings
    .filter((item) => item.studentId === child.id && item.bookingStatus === 'BOOKED')
    .sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''))[0]
  if (!booking) {
    const availableCourse = [...courses].sort((a, b) => a.startTime.localeCompare(b.startTime))[0]
    return availableCourse ? `下一节可约课程 ${formatDateTime(availableCourse.startTime)}` : '暂无近期课程'
  }
  const matchedCourse = courses.find((item) => item.id === booking.courseId)
  return matchedCourse ? `下一节课 ${formatDateTime(matchedCourse.startTime)}` : `已预约 ${booking.courseName}`
}

function buildLatestUpdate(input: ParentHomeDashboardInput): { summary: string; caption: string } {
  const evaluation = input.overview?.latestEvaluation
  if (evaluation?.parentReport?.trim()) {
    return {
      summary: evaluation.parentReport.trim(),
      caption: `阶段评估 · ${evaluation.cycleName}`
    }
  }
  const feedback = input.overview?.recentTrainingFeedback?.[0]
  if (feedback) {
    return {
      summary: feedback.aiSummary?.trim() || feedback.highlightNote?.trim() || feedback.nextStepSuggestion?.trim() || '最近训练反馈已更新',
      caption: `训练反馈 · ${feedback.trainingDate}`
    }
  }
  return {
    summary: '最近还没有新的训练反馈，进入成长总览查看完整档案。',
    caption: '成长动态 · 暂无新记录'
  }
}

export function readStoredParentHomeStudentId(): number | null {
  const raw = uni.getStorageSync(CURRENT_CHILD_KEY)
  if (!raw) return null
  const parsed = Number(raw)
  return Number.isFinite(parsed) && parsed > 0 ? parsed : null
}

export function writeStoredParentHomeStudentId(studentId: number): void {
  uni.setStorageSync(CURRENT_CHILD_KEY, String(studentId))
}

export function clearStoredParentHomeStudentId(): void {
  uni.removeStorageSync(CURRENT_CHILD_KEY)
}

export function resolveCurrentParentStudentId(children: Array<Pick<ParentChild, 'id'>>, preferredId?: number | null): number | null {
  if (!children.length) return null
  if (preferredId && children.some((child) => child.id === preferredId)) {
    return preferredId
  }
  if (preferredId) {
    clearStoredParentHomeStudentId()
  }
  return children[0].id
}

export function buildParentHomeDashboard(input: ParentHomeDashboardInput): ParentHomeDashboard {
  if (!input.child) {
    return {
      hero: {
        label: '家长首页',
        title: '先绑定孩子',
        status: '绑定后即可查看成长摘要与快捷入口',
        meta: '当前没有可展示的孩子档案',
        unreadCount: input.messages.filter((item) => !item.read).length
      },
      metrics: [],
      primaryActions: PRIMARY_ACTIONS,
      secondaryActions: SECONDARY_ACTIONS,
      latestUpdate: {
        title: '最近动态',
        summary: '绑定孩子后，这里会显示最近训练反馈和阶段评估。',
        caption: '成长动态 · 暂不可用',
        ctaLabel: '查看我的孩子',
        ctaUrl: '/pages/parent/children/list'
      },
      todo: {
        title: '待处理事项',
        summary: '先进入“我的孩子”确认绑定信息，再回来查看首页摘要。',
        caption: '首页引导',
        ctaLabel: '查看我的孩子',
        ctaUrl: '/pages/parent/children/list'
      },
      emptyState: {
        title: '还没有绑定孩子',
        description: '先进入“我的孩子”查看绑定信息，再回来查看成长摘要。',
        ctaLabel: '查看我的孩子',
        ctaUrl: '/pages/parent/children/list'
      }
    }
  }

  const unreadCount = input.messages.filter((item) => !item.read).length
  const latestFitness = getLatestFitnessSignal(input.fitnessRecords)
  const todoState = buildTodoSummary(input.messages, input.bookings, input.child.id)
  const latestUpdate = buildLatestUpdate(input)

  const metrics: ParentHomeMetric[] = [
    {
      key: 'attendance',
      label: '本周出勤',
      value: getWeekAttendance(input.bookings, input.child.id),
      hint: '优先按已预约与签到状态汇总',
      tone: 'teal'
    },
    {
      key: 'fitness',
      label: '最新体测',
      value: latestFitness.value,
      hint: latestFitness.hint,
      tone: 'blue'
    },
    {
      key: 'todo',
      label: '待处理事项',
      value: todoState.value,
      hint: todoState.hint,
      tone: 'amber'
    }
  ]

  return {
    hero: {
      label: '家长首页',
      title: `${input.child.name} · 家庭服务首页`,
      status: input.overview?.goalFocus?.trim() || '最近训练与提醒已汇总到首页',
      meta: getNextCourseMeta(input.child, input.bookings, input.courses),
      unreadCount
    },
    metrics,
    primaryActions: PRIMARY_ACTIONS,
    secondaryActions: SECONDARY_ACTIONS,
    latestUpdate: {
      title: '最近动态',
      summary: latestUpdate.summary,
      caption: latestUpdate.caption,
      ctaLabel: '进入成长总览',
      ctaUrl: `/pages/parent/growth/index?studentId=${input.child.id}`
    },
    todo: {
      title: '待处理事项',
      summary: todoState.summary,
      caption: unreadCount > 0 ? '建议优先处理消息提醒' : '建议优先查看最新训练反馈',
      ctaLabel: unreadCount > 0 ? '查看站内消息' : '查看成长总览',
      ctaUrl: unreadCount > 0 ? '/pages/parent/messages/list' : `/pages/parent/growth/index?studentId=${input.child.id}`
    },
    emptyState: null
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
cd Code/mobile-app
npm run test:unit -- src/utils/parent-home.test.ts
```

Expected: PASS with the child-selection and dashboard-summary cases green.

- [ ] **Step 5: Commit**

```bash
git -C Code/mobile-app add src/types/parent-home.ts src/utils/parent-home.ts src/utils/parent-home.test.ts
git -C Code/mobile-app commit -m "feat: add parent home dashboard view model"
```

## Task 3: Add Presentational Components For The Approved Homepage Sections

**Files:**
- Create: `Code/mobile-app/src/pages/parent/components/ParentHomeHero.vue`
- Create: `Code/mobile-app/src/pages/parent/components/ParentHomeMetricGrid.vue`
- Create: `Code/mobile-app/src/pages/parent/components/ParentHomeActionSection.vue`
- Create: `Code/mobile-app/src/pages/parent/components/ParentHomeActivityCard.vue`
- Modify: `Code/mobile-app/src/utils/parent-home.ts`
- Modify: `Code/mobile-app/src/utils/parent-home.test.ts`

- [ ] **Step 1: Write the failing test for the unread-message badge contract**

```ts
// Code/mobile-app/src/utils/parent-home.test.ts
it('adds an unread badge to the station message action when reminders exist', () => {
  const dashboard = buildParentHomeDashboard({
    child: {
      id: 11,
      studentNo: 'S001',
      name: '乐乐',
      gender: 'MALE',
      birthDate: '2015-05-01',
      guardianName: '张女士',
      guardianPhone: '13800000000',
      status: 'ACTIVE'
    },
    overview: null,
    messages: [{ id: 1, title: '提醒', content: '请查看反馈', msgType: 'REMINDER', read: false, createdAt: '2026-04-13T09:00:00' }],
    bookings: [],
    courses: [],
    fitnessRecords: []
  })

  expect(dashboard.primaryActions.map((item) => item.label)).toEqual(['课程预约', '成长总览', '签到记录', '我的孩子'])
  expect(dashboard.secondaryActions.map((item) => item.label)).toEqual(['体测记录', '预约记录', '站内消息'])
  expect(dashboard.secondaryActions.find((item) => item.key === 'messages')?.badge).toBe('1')
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd Code/mobile-app
npm run test:unit -- src/utils/parent-home.test.ts
```

Expected: FAIL if the action arrays or their ordering do not yet match the approved homepage information architecture.

- [ ] **Step 3: Write the presentational components**

```vue
<!-- Code/mobile-app/src/pages/parent/components/ParentHomeHero.vue -->
<template>
  <view class="hero-card">
    <view class="hero-row">
      <view>
        <view class="hero-label">{{ hero.label }}</view>
        <view class="hero-title">{{ hero.title }}</view>
        <view class="hero-status">{{ hero.status }}</view>
        <view class="hero-meta">{{ hero.meta }}</view>
      </view>
      <view v-if="hero.unreadCount" class="hero-badge">{{ hero.unreadCount }} 条提醒</view>
    </view>

    <scroll-view v-if="children.length > 1" scroll-x class="chip-scroll">
      <view class="chip-row">
        <view
          v-for="child in children"
          :key="child.id"
          class="child-chip"
          :class="{ active: child.id === currentStudentId }"
          @click="$emit('select-child', child.id)"
        >
          {{ child.name }}
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup lang="ts">
import type { ParentChild } from '@/api/modules/parent'
import type { ParentHomeHero } from '@/types/parent-home'

defineProps<{
  hero: ParentHomeHero
  children: ParentChild[]
  currentStudentId: number | null
}>()

defineEmits<{
  (event: 'select-child', studentId: number): void
}>()
</script>

<style scoped lang="scss">
.hero-card {
  background: linear-gradient(135deg, #0f766e 0%, #1d4ed8 100%);
  border-radius: 28rpx;
  padding: 30rpx;
  color: #ffffff;
  box-shadow: 0 20rpx 48rpx rgba(15, 118, 110, 0.22);
}

.hero-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 20rpx;
}

.hero-label {
  font-size: 22rpx;
  opacity: 0.85;
}

.hero-title {
  margin-top: 8rpx;
  font-size: 40rpx;
  font-weight: 700;
}

.hero-status,
.hero-meta {
  margin-top: 10rpx;
  font-size: 24rpx;
  line-height: 1.6;
  opacity: 0.92;
}

.hero-badge {
  padding: 10rpx 18rpx;
  border-radius: 999rpx;
  background: rgba(255, 255, 255, 0.18);
  font-size: 22rpx;
  white-space: nowrap;
}

.chip-scroll {
  margin-top: 22rpx;
  white-space: nowrap;
}

.chip-row {
  display: inline-flex;
  gap: 12rpx;
}

.child-chip {
  padding: 10rpx 24rpx;
  border-radius: 999rpx;
  background: rgba(255, 255, 255, 0.18);
  font-size: 24rpx;
}

.child-chip.active {
  background: #ffffff;
  color: #0f766e;
  font-weight: 700;
}
</style>
```

```vue
<!-- Code/mobile-app/src/pages/parent/components/ParentHomeMetricGrid.vue -->
<template>
  <view class="metric-grid">
    <view v-for="metric in metrics" :key="metric.key" class="metric-card" :class="metric.tone">
      <view class="metric-label">{{ metric.label }}</view>
      <view class="metric-value">{{ metric.value }}</view>
      <view class="metric-hint">{{ metric.hint }}</view>
    </view>
  </view>
</template>

<script setup lang="ts">
import type { ParentHomeMetric } from '@/types/parent-home'

defineProps<{
  metrics: ParentHomeMetric[]
}>()
</script>

<style scoped lang="scss">
.metric-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16rpx;
}

.metric-card {
  border-radius: 24rpx;
  padding: 24rpx 20rpx;
  background: #ffffff;
  box-shadow: 0 12rpx 32rpx rgba(15, 23, 42, 0.06);
}

.metric-card.teal {
  background: linear-gradient(180deg, #f0fdfa 0%, #ffffff 100%);
}

.metric-card.blue {
  background: linear-gradient(180deg, #eff6ff 0%, #ffffff 100%);
}

.metric-card.amber {
  background: linear-gradient(180deg, #fffbeb 0%, #ffffff 100%);
}

.metric-label {
  font-size: 24rpx;
  color: #64748b;
}

.metric-value {
  margin-top: 12rpx;
  font-size: 34rpx;
  font-weight: 700;
  color: #0f172a;
}

.metric-hint {
  margin-top: 10rpx;
  font-size: 22rpx;
  line-height: 1.5;
  color: #475569;
}
</style>
```

```vue
<!-- Code/mobile-app/src/pages/parent/components/ParentHomeActionSection.vue -->
<template>
  <view class="section-card">
    <view class="section-title">常用功能</view>

    <view class="primary-grid">
      <view v-for="item in primaryActions" :key="item.key" class="action-card primary" @click="$emit('navigate', item.url)">
        <view class="action-name">{{ item.label }}</view>
        <view class="action-hint">{{ item.hint }}</view>
      </view>
    </view>

    <view class="secondary-grid">
      <view v-for="item in secondaryActions" :key="item.key" class="action-card secondary" @click="$emit('navigate', item.url)">
        <view class="action-row">
          <view class="action-name">{{ item.label }}</view>
          <view v-if="item.badge" class="action-badge">{{ item.badge }}</view>
        </view>
        <view class="action-hint">{{ item.hint }}</view>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
import type { ParentHomeAction } from '@/types/parent-home'

defineProps<{
  primaryActions: ParentHomeAction[]
  secondaryActions: ParentHomeAction[]
}>()

defineEmits<{
  (event: 'navigate', url: string): void
}>()
</script>

<style scoped lang="scss">
.section-card {
  background: #ffffff;
  border-radius: 24rpx;
  padding: 28rpx;
  box-shadow: 0 12rpx 32rpx rgba(15, 23, 42, 0.06);
}

.section-title {
  font-size: 30rpx;
  font-weight: 700;
  color: #0f172a;
}

.primary-grid,
.secondary-grid {
  display: grid;
  gap: 16rpx;
}

.primary-grid {
  margin-top: 20rpx;
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.secondary-grid {
  margin-top: 16rpx;
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.action-card {
  border-radius: 20rpx;
  padding: 22rpx 20rpx;
}

.action-card.primary {
  background: linear-gradient(180deg, #f8fafc 0%, #ffffff 100%);
  border: 1rpx solid #dbeafe;
}

.action-card.secondary {
  background: #f8fafc;
}

.action-name {
  font-size: 28rpx;
  font-weight: 700;
  color: #0f172a;
}

.action-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12rpx;
}

.action-badge {
  min-width: 36rpx;
  padding: 4rpx 10rpx;
  border-radius: 999rpx;
  background: #fee2e2;
  color: #b91c1c;
  font-size: 20rpx;
  text-align: center;
}

.action-hint {
  margin-top: 8rpx;
  font-size: 22rpx;
  line-height: 1.5;
  color: #64748b;
}
</style>
```

```ts
// Code/mobile-app/src/utils/parent-home.ts
  const secondaryActions = SECONDARY_ACTIONS.map((item) => {
    if (item.key === 'messages' && unreadCount > 0) {
      return {
        ...item,
        badge: String(unreadCount)
      }
    }
    return item
  })

  return {
    hero: {
      label: '家长首页',
      title: `${input.child.name} · 家庭服务首页`,
      status: input.overview?.goalFocus?.trim() || '最近训练与提醒已汇总到首页',
      meta: getNextCourseMeta(input.child, input.bookings, input.courses),
      unreadCount
    },
    metrics,
    primaryActions: PRIMARY_ACTIONS,
    secondaryActions,
```

```vue
<!-- Code/mobile-app/src/pages/parent/components/ParentHomeActivityCard.vue -->
<template>
  <view class="activity-card">
    <view class="activity-title">{{ title }}</view>
    <view class="activity-summary">{{ summary }}</view>
    <view class="activity-caption">{{ caption }}</view>
    <u-button size="small" type="primary" :text="ctaLabel" @click="$emit('navigate', ctaUrl)" />
  </view>
</template>

<script setup lang="ts">
defineProps<{
  title: string
  summary: string
  caption: string
  ctaLabel: string
  ctaUrl: string
}>()

defineEmits<{
  (event: 'navigate', url: string): void
}>()
</script>

<style scoped lang="scss">
.activity-card {
  background: #ffffff;
  border-radius: 24rpx;
  padding: 28rpx;
  box-shadow: 0 12rpx 32rpx rgba(15, 23, 42, 0.06);
}

.activity-title {
  font-size: 30rpx;
  font-weight: 700;
  color: #0f172a;
}

.activity-summary {
  margin-top: 14rpx;
  font-size: 26rpx;
  line-height: 1.7;
  color: #1f2937;
}

.activity-caption {
  margin: 14rpx 0 20rpx;
  font-size: 22rpx;
  color: #64748b;
}
</style>
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
cd Code/mobile-app
npm run test:unit -- src/utils/parent-home.test.ts
```

Expected: PASS with the unread-message badge case green.

- [ ] **Step 5: Commit**

```bash
git -C Code/mobile-app add src/pages/parent/components/ParentHomeHero.vue src/pages/parent/components/ParentHomeMetricGrid.vue src/pages/parent/components/ParentHomeActionSection.vue src/pages/parent/components/ParentHomeActivityCard.vue src/utils/parent-home.test.ts
git -C Code/mobile-app commit -m "feat: add parent home presentation components"
```

## Task 4: Refactor The Parent Home Page Container And Verify The End-To-End Flow

**Files:**
- Modify: `Code/mobile-app/src/pages/parent/home.vue`
- Modify: `Code/mobile-app/src/utils/parent-home.ts`
- Modify: `Code/mobile-app/src/utils/parent-home.test.ts`

- [ ] **Step 1: Write the failing test for the no-child onboarding state**

```ts
// Code/mobile-app/src/utils/parent-home.test.ts
it('returns the onboarding empty state when the parent has no bound children', () => {
  const dashboard = buildParentHomeDashboard({
    child: null,
    overview: null,
    messages: [],
    bookings: [],
    courses: [],
    fitnessRecords: []
  })

  expect(dashboard.emptyState).toEqual({
    title: '还没有绑定孩子',
    description: '先进入“我的孩子”查看绑定信息，再回来查看成长摘要。',
    ctaLabel: '查看我的孩子',
    ctaUrl: '/pages/parent/children/list'
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd Code/mobile-app
npm run test:unit -- src/utils/parent-home.test.ts
```

Expected: FAIL if the empty-state copy or structure does not yet match the approved onboarding contract.

- [ ] **Step 3: Wire the page container to the dashboard view model**

```vue
<!-- Code/mobile-app/src/pages/parent/home.vue -->
<template>
  <view class="page parent-home">
    <view v-if="loading" class="state-card">首页数据加载中...</view>
    <view v-else-if="errorText" class="state-card">
      <view class="state-title">首页加载失败</view>
      <view class="state-copy">{{ errorText }}</view>
      <u-button type="primary" text="重新加载" @click="loadHome" />
    </view>
    <view v-else-if="dashboard.emptyState" class="state-card">
      <view class="state-title">{{ dashboard.emptyState.title }}</view>
      <view class="state-copy">{{ dashboard.emptyState.description }}</view>
      <u-button type="primary" :text="dashboard.emptyState.ctaLabel" @click="navigate(dashboard.emptyState.ctaUrl)" />
    </view>
    <template v-else>
      <ParentHomeHero
        :hero="dashboard.hero"
        :children="children"
        :current-student-id="currentStudentId"
        @select-child="handleSelectChild"
      />

      <ParentHomeMetricGrid class="section-gap" :metrics="dashboard.metrics" />

      <ParentHomeActionSection
        class="section-gap"
        :primary-actions="dashboard.primaryActions"
        :secondary-actions="dashboard.secondaryActions"
        @navigate="navigate"
      />

      <ParentHomeActivityCard
        class="section-gap"
        :title="dashboard.latestUpdate.title"
        :summary="dashboard.latestUpdate.summary"
        :caption="dashboard.latestUpdate.caption"
        :cta-label="dashboard.latestUpdate.ctaLabel"
        :cta-url="dashboard.latestUpdate.ctaUrl"
        @navigate="navigate"
      />

      <ParentHomeActivityCard
        class="section-gap"
        :title="dashboard.todo.title"
        :summary="dashboard.todo.summary"
        :caption="dashboard.todo.caption"
        :cta-label="dashboard.todo.ctaLabel"
        :cta-url="dashboard.todo.ctaUrl"
        @navigate="navigate"
      />

      <view class="section-gap footer-actions">
        <u-button type="primary" text="刷新首页" @click="loadHome" />
        <u-button text="退出登录" @click="handleLogout" />
      </view>
    </template>
  </view>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import { logout } from '@/api/modules/auth'
import {
  getParentGrowthOverview,
  listParentBookings,
  listParentChildren,
  listParentCourses,
  listParentFitness,
  listParentMessages,
  type ParentBooking,
  type ParentChild,
  type ParentCourse,
  type ParentMessage
} from '@/api/modules/parent'
import ParentHomeActionSection from './components/ParentHomeActionSection.vue'
import ParentHomeActivityCard from './components/ParentHomeActivityCard.vue'
import ParentHomeHero from './components/ParentHomeHero.vue'
import ParentHomeMetricGrid from './components/ParentHomeMetricGrid.vue'
import { getAuth, isLoggedIn } from '@/store/auth'
import type { FitnessTestRecord, ParentGrowthOverview } from '@/types/parent'
import { buildParentHomeDashboard, readStoredParentHomeStudentId, resolveCurrentParentStudentId, writeStoredParentHomeStudentId } from '@/utils/parent-home'
import { showError, showSuccess } from '@/utils/error'

const loading = ref(false)
const errorText = ref('')
const children = ref<ParentChild[]>([])
const currentStudentId = ref<number | null>(null)
const messages = ref<ParentMessage[]>([])
const bookings = ref<ParentBooking[]>([])
const courses = ref<ParentCourse[]>([])
const fitnessRecords = ref<FitnessTestRecord[]>([])
const overview = ref<ParentGrowthOverview | null>(null)

function ensureLogin() {
  if (!isLoggedIn()) {
    uni.reLaunch({ url: '/pages/login/index' })
    return false
  }
  return true
}

const currentChild = computed(() => children.value.find((item) => item.id === currentStudentId.value) || null)

const dashboard = computed(() =>
  buildParentHomeDashboard({
    child: currentChild.value,
    overview: overview.value,
    messages: messages.value,
    bookings: bookings.value,
    courses: courses.value,
    fitnessRecords: fitnessRecords.value
  })
)

async function loadHome(preferredStudentId?: number | null) {
  if (!ensureLogin()) return
  loading.value = true
  errorText.value = ''

  try {
    const childList = await listParentChildren()
    children.value = childList

    const resolvedId = resolveCurrentParentStudentId(childList, preferredStudentId ?? readStoredParentHomeStudentId())
    currentStudentId.value = resolvedId
    if (resolvedId) {
      writeStoredParentHomeStudentId(resolvedId)
    }

    const [messageRows, bookingRows, courseRows, fitnessRows, growth] = await Promise.all([
      listParentMessages(),
      listParentBookings(),
      listParentCourses(),
      resolvedId ? listParentFitness(resolvedId) : Promise.resolve([]),
      resolvedId ? getParentGrowthOverview(resolvedId) : Promise.resolve(null)
    ])

    messages.value = messageRows
    bookings.value = bookingRows
    courses.value = courseRows
    fitnessRecords.value = fitnessRows
    overview.value = growth
  } catch (error) {
    errorText.value = '请检查网络后重试，首页其他功能稍后仍可从菜单进入。'
    showError(error, '家长首页加载失败')
  } finally {
    loading.value = false
  }
}

function navigate(url: string) {
  uni.navigateTo({ url })
}

function handleSelectChild(studentId: number) {
  if (studentId === currentStudentId.value) return
  loadHome(studentId)
}

async function handleLogout() {
  try {
    await logout(getAuth()?.refreshToken)
    showSuccess('已退出登录')
  } catch (error) {
    showError(error, '退出登录失败')
  } finally {
    uni.reLaunch({ url: '/pages/login/index' })
  }
}

onLoad(() => {
  loadHome()
})

onShow(() => {
  if (ensureLogin()) {
    loadHome(currentStudentId.value)
  }
})
</script>

<style scoped lang="scss">
.parent-home {
  padding: 24rpx 24rpx 40rpx;
  background:
    radial-gradient(circle at top right, rgba(14, 165, 233, 0.08), transparent 32%),
    linear-gradient(180deg, #f4fbf8 0%, #f5f7fb 42%, #eef4ff 100%);
  min-height: 100vh;
}

.section-gap {
  margin-top: 20rpx;
}

.state-card {
  background: #ffffff;
  border-radius: 24rpx;
  padding: 32rpx 28rpx;
  box-shadow: 0 12rpx 32rpx rgba(15, 23, 42, 0.06);
}

.state-title {
  font-size: 34rpx;
  font-weight: 700;
  color: #0f172a;
}

.state-copy {
  margin: 12rpx 0 24rpx;
  font-size: 26rpx;
  line-height: 1.6;
  color: #64748b;
}

.footer-actions {
  display: flex;
  gap: 16rpx;
}
</style>
```

- [ ] **Step 4: Run the full verification suite**

Run:

```bash
cd Code/mobile-app
npm run test:unit -- src/utils/parent-home.test.ts
npm run type-check
npm run build:mp-weixin
```

Expected:

1. `test:unit` passes all parent-home cases.
2. `type-check` exits cleanly with no TypeScript errors.
3. `build:mp-weixin` completes successfully and refreshes `dist/build/mp-weixin`.

- [ ] **Step 5: Commit**

```bash
git -C Code/mobile-app add src/pages/parent/home.vue src/utils/parent-home.ts src/utils/parent-home.test.ts
git -C Code/mobile-app commit -m "feat: redesign parent home dashboard"
```

## Self-Review

### Spec Coverage

1. Homepage positioning, mixed summary + quick actions, and single-child focus are covered in Task 2 and Task 4.
2. Existing business data reuse (`children`, `messages`, `bookings`, `courses`, `fitness`, `growthOverview`) is covered in Task 2 and Task 4.
3. The approved quick-action hierarchy and recent activity modules are covered in Task 3 and Task 4.
4. Empty/error/AI-fallback behavior is covered in Task 2 and Task 4.

No spec gaps remain for the agreed implementation scope.

### Placeholder Scan

1. No `TODO`, `TBD`, or “similar to above” placeholders remain.
2. Every task includes concrete file paths, code snippets, commands, and expected outcomes.

### Type Consistency

1. `ParentHomeDashboard`, `ParentHomeHero`, `ParentHomeMetric`, and `ParentHomeAction` are defined once in `src/types/parent-home.ts` and reused consistently.
2. `buildParentHomeDashboard()` is the only dashboard assembly entrypoint across the utility tests and page container.
3. The persisted child-selection helpers use a single storage key: `zf_parent_home_student_id`.
