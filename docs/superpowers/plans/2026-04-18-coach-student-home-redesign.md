# 教练端与学生端首页重构 (B3方案) 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** 将教练端和学生端的首页重构为基于“顶部水平日期条 + 下方纵向日程流”的任务驱动型界面。

**Architecture:** 
采用 Vue 3 <script setup> 结合 uview-plus UI 库。顶部数据概览区域精简，核心部分由一个自定义的横向日期滑动组件（或封装 u-tabs）和一个基于 Flex 布局的日程列表组件组成。数据根据选中的日期进行过滤展示。

**Tech Stack:** Vue 3 (Composition API), TypeScript, uview-plus, UniApp (微信小程序)

---

### Task 1: 创建公共业务组件 - 水平日期滑动条

**Files:**
- Create: src/components/date-slider/date-slider.vue

- [ ] **Step 1: 创建 date-slider 组件骨架**
  - 在 src/components/date-slider/date-slider.vue 中，实现一个基于 scroll-view 的横向滚动条。
  - 生成当前日期及前后各一周（共 15 天）的日期数组作为数据源。

`ue
<template>
  <scroll-view class="date-slider" scroll-x :scroll-into-view="scrollIntoId" scroll-with-animation>
    <view class="date-list">
      <view
        v-for="(item, index) in dateList"
        :key="item.date"
        :id="'date-' + index"
        class="date-item"
        :class="{ active: item.date === modelValue }"
        @click="selectDate(item.date)"
      >
        <text class="week">{{ item.week }}</text>
        <text class="day">{{ item.day }}</text>
        <!-- 预留状态圆点位置 -->
        <view class="dot" :class="{ 'has-event': item.hasEvent }"></view>
      </view>
    </view>
  </scroll-view>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

const props = defineProps<{
  modelValue: string // YYYY-MM-DD
  events?: string[] // 有事件的日期数组 ['2026-04-18']
}>()

const emit = defineEmits(['update:modelValue', 'change'])

const dateList = ref<Array<{ date: string; day: string; week: string; hasEvent: boolean }>>([])
const scrollIntoId = ref('')

const weekMap = ['日', '一', '二', '三', '四', '五', '六']

function generateDates() {
  const list = []
  const today = new Date()
  // 生成前后各7天
  for (let i = -7; i <= 7; i++) {
    const d = new Date(today)
    d.setDate(today.getDate() + i)
    const year = d.getFullYear()
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    const dateStr = ${year}--
    
    list.push({
      date: dateStr,
      day: day,
      week: weekMap[d.getDay()],
      hasEvent: props.events?.includes(dateStr) ?? false
    })
  }
  dateList.value = list
  
  // 滚动到选中的日期
  const activeIndex = list.findIndex(item => item.date === props.modelValue)
  if (activeIndex > -1) {
    // 稍微往左偏一点，让选中的居中
    const targetIndex = Math.max(0, activeIndex - 2)
    scrollIntoId.value = 'date-' + targetIndex
  }
}

function selectDate(date: string) {
  emit('update:modelValue', date)
  emit('change', date)
}

onMounted(() => {
  generateDates()
})
</script>

<style scoped lang="scss">
.date-slider {
  width: 100%;
  white-space: nowrap;
  background-color: #ffffff;
  padding: 20rpx 0;
  border-bottom: 1rpx solid #f3f4f6;
}
.date-list {
  display: inline-flex;
  padding: 0 20rpx;
}
.date-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 90rpx;
  height: 110rpx;
  margin: 0 10rpx;
  border-radius: 16rpx;
  background-color: #f8fafc;
  transition: all 0.2s;

  &.active {
    background-color: #3b82f6; // 主题色
    color: #ffffff;
    
    .week, .day { color: #ffffff; }
  }

  .week {
    font-size: 24rpx;
    color: #6b7280;
    margin-bottom: 8rpx;
  }
  .day {
    font-size: 32rpx;
    font-weight: bold;
    color: #111827;
  }
  .dot {
    width: 8rpx;
    height: 8rpx;
    border-radius: 50%;
    margin-top: 6rpx;
    background-color: transparent;
    
    &.has-event {
      background-color: #ef4444; // 有课标记为红色
    }
  }
  
  &.active .dot.has-event {
    background-color: #ffffff;
  }
}
</style>
`

- [ ] **Step 2: 验证组件无语法错误**
  - 运行 
pm run type-check 确保 date-slider.vue 没有 TS 错误。

---

### Task 2: 重构教练端首页 (Admin Home)

**Files:**
- Modify: src/pages/admin/home.vue
- Modify: src/api/modules/admin.ts (可能需要确保获取课程列表接口支持日期筛选)

- [ ] **Step 1: 引入日期组件并重构布局结构**
  - 替换原有的九宫格为“精简数据卡片” + “水平日期选择器” + “课程日程卡片流”。
  - 移除原有的 grid 相关代码。

`ue
<!-- src/pages/admin/home.vue 部分代码替换 -->
<template>
  <view class="page">
    <!-- 1. 顶部数据概览 -->
    <view class="summary-bar">
      <view class="summary-item">
        <text class="label">今日课程</text>
        <text class="value">{{ stats.todayCourses }}</text>
      </view>
      <view class="summary-item">
        <text class="label">待签到</text>
        <text class="value">{{ stats.pendingSignIns }}</text>
      </view>
    </view>

    <!-- 2. 日期滑动条 -->
    <date-slider v-model="selectedDate" @change="fetchSchedule" />

    <!-- 3. 日程流 -->
    <view class="schedule-stream">
      <template v-if="scheduleList.length > 0">
        <view class="course-card" v-for="course in scheduleList" :key="course.id">
          <view class="card-header">
            <view class="time">{{ formatTime(course.startTime) }} - {{ formatTime(course.endTime) }}</view>
            <view class="status" :class="course.status">{{ course.statusText }}</view>
          </view>
          <view class="card-body">
            <view class="course-name">{{ course.name }}</view>
            <view class="course-info">
              <text>人数: {{ course.studentCount }}/{{ course.capacity }}</text>
              <text class="divider">|</text>
              <text>场地: {{ course.location }}</text>
            </view>
          </view>
          <view class="card-actions">
            <u-button size="small" type="primary" plain text="录入体测" @click="goRecordFitness(course.id)" />
            <u-button size="small" type="primary" text="点名签到" @click="goSignIn(course.id)" />
          </view>
        </view>
      </template>
      <template v-else>
        <u-empty mode="data" text="所选日期无课程安排" />
      </template>
    </view>

    <!-- 4. 全局悬浮按钮 -->
    <view class="fab-btn" @click="handleScan">
      <u-icon name="scan" color="#fff" size="24"></u-icon>
    </view>
  </view>
</template>

<script setup lang="ts">
// ... 保留原有导入
import DateSlider from '@/components/date-slider/date-slider.vue'

// 状态定义
const selectedDate = ref(new Date().toISOString().split('T')[0])
const scheduleList = ref<any[]>([]) // 根据实际类型替换
const stats = reactive({ todayCourses: 0, pendingSignIns: 0 })

// 辅助函数
function formatTime(timeStr: string) {
  if (!timeStr) return ''
  // 假设 timeStr 是 '2026-04-18 14:00:00'
  return timeStr.split(' ')[1]?.substring(0, 5) || timeStr
}

async function fetchSchedule(date: string) {
  // TODO: 调用 API 获取指定日期的课程
  // 示例模拟数据
  // scheduleList.value = await getAdminCourses({ date })
}

// 页面加载逻辑...
onMounted(() => {
  fetchSchedule(selectedDate.value)
})
</script>

<style scoped lang="scss">
.summary-bar {
  display: flex;
  justify-content: space-around;
  background-color: #1e3a8a; // 深蓝色底
  color: #fff;
  padding: 30rpx 0;
  border-radius: 0 0 32rpx 32rpx;
  
  .summary-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    .label { font-size: 24rpx; opacity: 0.8; margin-bottom: 8rpx; }
    .value { font-size: 40rpx; font-weight: bold; }
  }
}

.schedule-stream {
  padding: 24rpx;
}

.course-card {
  background: #fff;
  border-radius: 16rpx;
  padding: 24rpx;
  margin-bottom: 24rpx;
  box-shadow: 0 2rpx 12rpx rgba(0,0,0,0.05);

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16rpx;
    
    .time { font-size: 32rpx; font-weight: bold; color: #111827; }
    .status { font-size: 24rpx; padding: 4rpx 12rpx; border-radius: 8rpx; }
    /* 根据状态定义颜色 */
  }

  .course-name { font-size: 30rpx; font-weight: 500; margin-bottom: 12rpx; }
  .course-info { font-size: 26rpx; color: #6b7280; margin-bottom: 24rpx; }
  .divider { margin: 0 12rpx; color: #d1d5db; }

  .card-actions {
    display: flex;
    justify-content: flex-end;
    gap: 16rpx;
    border-top: 1rpx solid #f3f4f6;
    padding-top: 16rpx;
  }
}

.fab-btn {
  position: fixed;
  right: 40rpx;
  bottom: 60rpx;
  width: 100rpx;
  height: 100rpx;
  border-radius: 50%;
  background-color: #3b82f6;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8rpx 16rpx rgba(59,130,246,0.4);
}
</style>
`

- [ ] **Step 2: 完善 TypeScript 类型与 API 联调**
  - 根据 src/api/modules/admin.ts 中现有的接口，补全数据获取逻辑。

---

### Task 3: 重构学生端首页 (Student Home)

**Files:**
- Modify: src/pages/student/home.vue

- [ ] **Step 1: 应用相同的设计模式到学生端**
  - 保持顶部结构类似，数据换为“剩余课时”等。
  - 引入 date-slider 组件。
  - 下方卡片流调整为学生视角的课程展示。

`ue
<!-- src/pages/student/home.vue 部分代码 -->
<template>
  <view class="page">
    <view class="summary-bar">
      <view class="summary-item">
        <text class="label">剩余课时</text>
        <text class="value">{{ stats.remainingHours }}</text>
      </view>
      <view class="summary-item">
        <text class="label">最近体测</text>
        <text class="value">{{ stats.lastScore || '--' }}</text>
      </view>
    </view>

    <date-slider v-model="selectedDate" @change="fetchSchedule" />

    <view class="schedule-stream">
      <template v-if="scheduleList.length > 0">
        <view class="course-card" v-for="course in scheduleList" :key="course.id">
          <view class="card-header">
            <view class="time">{{ formatTime(course.startTime) }} - {{ formatTime(course.endTime) }}</view>
            <view class="status" :class="course.status">{{ course.statusText }}</view>
          </view>
          <view class="card-body">
            <view class="course-name">{{ course.name }}</view>
            <view class="course-info">
              <text>教练: {{ course.coachName }}</text>
              <text class="divider">|</text>
              <text>场地: {{ course.location }}</text>
            </view>
          </view>
          <view class="card-actions">
            <u-button size="small" text="请假" @click="handleLeave(course.id)" />
            <u-button size="small" type="primary" text="课程详情" @click="goDetail(course.id)" />
          </view>
        </view>
      </template>
      <template v-else>
        <u-empty mode="data" text="今天没有课程，好好休息吧" />
      </template>
    </view>
  </view>
</template>
`

- [ ] **Step 2: 验证样式与接口**
  - 将相关的样式（从 admin home 中复用公共部分或提取到公共 css）。

---

### Task 4: 清理与构建验证

- [ ] **Step 1: 运行类型检查与构建测试**
  - 运行 
pm run type-check 确保没有遗留的 TS 错误。
  - 运行 
pm run build:mp-weixin 确保构建成功。
  - 清理废弃的无用引用和组件（如旧版的九宫格代码）。
