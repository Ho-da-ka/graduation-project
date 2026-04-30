# Parent Date Strip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a minimalist horizontal scrolling date selection component for the parent home page.

**Architecture:** A stateless component that receives the selected date as a prop and emits a selection event. It generates a range of dates around the current date for selection.

**Tech Stack:** Vue 3 (Script Setup), TypeScript, uni-app (scroll-view).

---

### Task 1: Implement ParentDateStrip Component

**Files:**
- Create: `Code/mobile-app/src/pages/parent/components/ParentDateStrip.vue`

- [ ] **Step 1: Create the component file with basic structure**

```vue
<script setup lang="ts">
import { computed } from 'vue';

interface Props {
  selectedDate: string; // YYYY-MM-DD
}

const props = defineProps<Props>();
const emit = defineEmits<{
  (e: 'select', date: string): void;
}>();

// Generate dates: 7 days before today to 7 days after today
const dates = computed(() => {
  const list = [];
  const today = new Date();
  const weekDays = ['日', '一', '二', '三', '四', '五', '六'];
  
  for (let i = -7; i <= 7; i++) {
    const date = new Date(today);
    date.setDate(today.getDate() + i);
    
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    const dateStr = `${yyyy}-${mm}-${dd}`;
    
    list.push({
      date: dateStr,
      day: date.getDate(),
      weekDay: weekDays[date.getDay()],
      isToday: i === 0
    });
  }
  return list;
});

const onSelect = (date: string) => {
  emit('select', date);
};
</script>

<template>
  <scroll-view class="date-strip-scroll" scroll-x :show-scrollbar="false">
    <div class="date-strip-container">
      <div 
        v-for="item in dates" 
        :key="item.date"
        class="date-item"
        :class="{ 'is-selected': item.date === selectedDate }"
        @tap="onSelect(item.date)"
      >
        <span class="weekday">{{ item.weekDay }}</span>
        <span class="day">{{ item.day }}</span>
        <div class="underline" v-if="item.date === selectedDate"></div>
      </div>
    </div>
  </scroll-view>
</template>

<style lang="scss" scoped>
.date-strip-scroll {
  width: 100%;
  background-color: #ffffff;
  white-space: nowrap;
}

.date-strip-container {
  display: flex;
  padding: 20rpx 10rpx;
}

.date-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-width: 90rpx;
  position: relative;
  padding: 10rpx 0;
  
  .weekday {
    font-size: 24rpx;
    color: #6B7280;
    margin-bottom: 8rpx;
  }
  
  .day {
    font-size: 32rpx;
    color: #111827;
    font-weight: 500;
  }
  
  &.is-selected {
    .weekday {
      color: #2563EB;
      font-weight: 600;
    }
    .day {
      color: #2563EB;
      font-weight: 700;
    }
  }
}

.underline {
  position: absolute;
  bottom: 0;
  width: 40rpx;
  height: 4rpx;
  background-color: #2563EB;
  border-radius: 2rpx;
}
</style>
```

- [ ] **Step 2: Commit**

```bash
git add Code/mobile-app/src/pages/parent/components/ParentDateStrip.vue
git commit -m "feat: add ParentDateStrip component"
```

---

### Task 2: Verify with Unit Tests

**Files:**
- Create: `Code/mobile-app/src/pages/parent/components/ParentDateStrip.test.ts`

- [ ] **Step 1: Write unit tests**

```typescript
import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import ParentDateStrip from './ParentDateStrip.vue';

describe('ParentDateStrip', () => {
  it('renders correctly and generates 15 dates', () => {
    const wrapper = mount(ParentDateStrip, {
      props: {
        selectedDate: '2024-01-01'
      }
    });
    
    const items = wrapper.findAll('.date-item');
    expect(items.length).toBe(15); // -7 to +7 includes 0
  });

  it('highlights the selected date', () => {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const todayStr = `${yyyy}-${mm}-${dd}`;

    const wrapper = mount(ParentDateStrip, {
      props: {
        selectedDate: todayStr
      }
    });
    
    const selectedItem = wrapper.find('.is-selected');
    expect(selectedItem.exists()).toBe(true);
    expect(selectedItem.find('.day').text()).toBe(String(today.getDate()));
  });

  it('emits select event when a date is clicked', async () => {
    const wrapper = mount(ParentDateStrip, {
      props: {
        selectedDate: '2024-01-01'
      }
    });
    
    const items = wrapper.findAll('.date-item');
    await items[0].trigger('tap');
    
    expect(wrapper.emitted()).toHaveProperty('select');
    // The first item should be 7 days ago
    const expectedDate = new Date();
    expectedDate.setDate(expectedDate.getDate() - 7);
    const yyyy = expectedDate.getFullYear();
    const mm = String(expectedDate.getMonth() + 1).padStart(2, '0');
    const dd = String(expectedDate.getDate()).padStart(2, '0');
    const expectedDateStr = `${yyyy}-${mm}-${dd}`;
    
    expect(wrapper.emitted('select')![0]).toEqual([expectedDateStr]);
  });
});
```

- [ ] **Step 2: Run tests**

Run: `cd Code/mobile-app && npm run test:unit src/pages/parent/components/ParentDateStrip.test.ts`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add Code/mobile-app/src/pages/parent/components/ParentDateStrip.test.ts
git commit -m "test: add unit tests for ParentDateStrip"
```
