# Parent Home Optimization Task 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update TypeScript types and refactor the dashboard data processing logic to support the new "Minimalist Timeline" layout.

**Architecture:** Update `ParentHomeHero` to include `selectedDate`, add `ParentHomeTimelineItem` for the timeline view, and refactor `buildParentHomeDashboard` to filter and map data based on a selected date into a timeline format.

**Tech Stack:** TypeScript, Vue 3, Uni-app (context-specific)

---

### Task 1: Update Parent Home Types

**Files:**
- Modify: `Code/mobile-app/src/types/parent-home.ts`

- [ ] **Step 1: Update `ParentHomeHero` interface**

```typescript
export interface ParentHomeHero {
  selectedDate: string; // YYYY-MM-DD
  unreadCount: number;
}
```

- [ ] **Step 2: Add `ParentHomeTimelineItem` interface**

```typescript
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

- [ ] **Step 3: Update `ParentHomeDashboard` interface**

```typescript
export interface ParentHomeDashboard {
  hero: ParentHomeHero
  metrics: ParentHomeMetric[]
  timeline: ParentHomeTimelineItem[] // Added for timeline view
  primaryActions: ParentHomeAction[]
  secondaryActions: ParentHomeAction[]
  latestUpdate: ParentHomeActivity
  todo: ParentHomeActivity
  emptyState: ParentHomeEmptyState | null
}
```

- [ ] **Step 4: Commit types update**

```bash
git add Code/mobile-app/src/types/parent-home.ts
git commit -m "refactor: update parent home types for minimalist timeline"
```

### Task 2: Refactor `buildParentHomeDashboard` Utility

**Files:**
- Modify: `Code/mobile-app/src/utils/parent-home.ts`

- [ ] **Step 1: Update `buildParentHomeDashboard` signature and initial logic**

Accept `selectedDate` and calculate `unreadCount` first.

```typescript
export function buildParentHomeDashboard(
  input: ParentHomeDashboardInput,
  selectedDate: string = new Date().toISOString().split('T')[0]
): ParentHomeDashboard {
  const now = new Date()
  const unreadCount = input.messages.filter((item) => !item.read).length
  // ... rest of the setup logic
```

- [ ] **Step 2: Implement timeline data processing logic**

Filter bookings and courses for `selectedDate` and map to `ParentHomeTimelineItem`.

```typescript
  // Timeline processing logic
  const timeline: ParentHomeTimelineItem[] = []
  const courseStartLookup = buildCourseStartLookup(input.courses)

  if (input.child) {
    const studentId = input.child.id
    
    // Filter bookings for this child and this date
    const dayBookings = input.bookings.filter(booking => {
      if (booking.studentId !== studentId || booking.bookingStatus !== 'BOOKED') return false
      const startTime = getCourseStartTime(booking, courseStartLookup)
      return startTime && startTime.startsWith(selectedDate)
    })

    dayBookings.forEach(booking => {
      const startTimeStr = getCourseStartTime(booking, courseStartLookup)
      if (!startTimeStr) return
      
      const startTime = new Date(startTimeStr)
      const endTime = new Date(startTime.getTime() + 90 * 60 * 1000) // Assume 90 min duration
      const currentTime = now.getTime()
      
      let status: 'past' | 'upcoming' | 'ongoing' = 'upcoming'
      if (currentTime > endTime.getTime()) {
        status = 'past'
      } else if (currentTime >= startTime.getTime() && currentTime <= endTime.getTime()) {
        status = 'ongoing'
      }

      let reportUrl: string | undefined = undefined
      if (status === 'past' && booking.checkinStatus === 'CHECKED_IN') {
        reportUrl = `/pages/parent/growth/index?studentId=${studentId}&courseId=${booking.courseId}`
      }

      timeline.push({
        id: booking.courseId,
        time: startTimeStr.split('T')[1].slice(0, 5),
        date: selectedDate,
        title: booking.courseName || '未知课程',
        coach: (booking.coachName as string) || '待定教练',
        location: (booking.locationName as string) || '场馆待定',
        status,
        reportUrl
      })
    })

    // Sort timeline by time
    timeline.sort((a, b) => a.time.localeCompare(b.time))
  }
```

- [ ] **Step 3: Update the return object for both "no child" and "child exists" cases**

Ensure the `hero` and `timeline` are correctly populated.

```typescript
  // For "no child" case:
  if (!input.child) {
    return {
      hero: {
        selectedDate,
        unreadCount
      },
      metrics: [],
      timeline: [], // Empty timeline
      // ... actions and other fields
    }
  }

  // For "child exists" case:
  return {
    hero: {
      selectedDate,
      unreadCount
    },
    metrics,
    timeline,
    // ... actions and other fields
  }
```

- [ ] **Step 4: Verify and Commit**

Run type check if possible and commit changes.

```bash
git add Code/mobile-app/src/utils/parent-home.ts
git commit -m "refactor: update dashboard builder for timeline support"
```
