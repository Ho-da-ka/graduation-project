# Plan P1: 统计报表模块

Spec: `docs/superpowers/specs/full-upgrade-spec.md` §4
依赖: Plan P0 完成（分页接口已就绪）

---

## Step 1: 后端 — 统计接口

**新增文件：**

`web/dto/statistics/DashboardStatsResponse.java`
```java
package com.shuzi.managementplatform.web.dto.statistics;

import java.util.List;

public record DashboardStatsResponse(
    StudentStats students,
    CourseStats courses,
    CoachStats coaches,
    AttendanceStats attendance,
    long recentFitnessCount,
    long recentTrainingCount
) {
    public record StudentStats(long total, long active, long inactive, long graduated) {}
    public record CourseStats(long total, long planned, long ongoing, long completed, long cancelled) {}
    public record CoachStats(long total, long active, long inactive) {}
    public record AttendanceStats(long thisMonthTotal, long thisMonthPresent, double thisMonthRate, List<DailyAttendance> last7Days) {}
    public record DailyAttendance(String date, long present, long total) {}
}
```

`web/dto/statistics/CoachWorkloadResponse.java`
```java
public record CoachWorkloadResponse(Long coachId, String coachName, long courseCount, long trainingCount) {}
```

**新增 `StatisticsService.java`：**
- `getDashboard()` — 用 MyBatis-Plus `selectCount` + `Wrappers.lambdaQuery()` 按状态分组统计各实体数量；考勤统计用 `ge`/`le` 过滤本月日期范围；近7天按日期循环查询
- `getCoachWorkload()` — 查所有在职教练，对每个教练统计课程数和训练记录数

**新增 `StatisticsController.java`：**
```java
@RestController
@RequestMapping("/api/v1/statistics")
@PreAuthorize("hasRole('ADMIN')")
public class StatisticsController {
    @GetMapping("/dashboard")
    public ApiResponse<DashboardStatsResponse> dashboard() { ... }

    @GetMapping("/coach-workload")
    public ApiResponse<List<CoachWorkloadResponse>> coachWorkload() { ... }
}
```

**验证：** `GET /api/v1/statistics/dashboard` 返回完整 JSON 结构

---

## Step 2: 前端 — 安装 ECharts + 封装 composable

**安装依赖：**
```bash
cd Code/admin-panel && npm install echarts
```

**新增 `Code/admin-panel/src/composables/useChart.js`：**
```js
import { onBeforeUnmount, onMounted, watch } from 'vue'
import * as echarts from 'echarts/core'
import { LineChart, PieChart, BarChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([LineChart, PieChart, BarChart, GridComponent, TooltipComponent, LegendComponent, CanvasRenderer])

export function useChart(domRef, optionRef) {
  let chart = null
  onMounted(() => {
    chart = echarts.init(domRef.value)
    chart.setOption(optionRef.value)
  })
  watch(optionRef, (val) => chart?.setOption(val), { deep: true })
  onBeforeUnmount(() => chart?.dispose())
  return { chart: () => chart }
}
```

**新增 `Code/admin-panel/src/api/modules/statistics.js`：**
```js
import http from '../http'
function unwrap(r) { const b = r.data; if (!b?.success) throw new Error(b?.message || '请求失败'); return b.data }
export const getDashboardStats = () => http.get('/statistics/dashboard').then(unwrap)
export const getCoachWorkload = () => http.get('/statistics/coach-workload').then(unwrap)
```

---

## Step 3: 前端 — DashboardView.vue 全面改造

**完全重写 `Code/admin-panel/src/views/DashboardView.vue`：**

布局（使用 Element Plus `el-row` / `el-col`）：

**第一行 — 4个统计卡片：**
- 学员总数（副标题：在读 X / 休学 X / 毕业 X）
- 课程总数（副标题：进行中 X / 已完成 X）
- 教练总数（副标题：在职 X）
- 本月出勤率（副标题：本月考勤 X 次）

**第二行 — 2个图表（各占 12 列）：**
- 左：近7天考勤趋势折线图（x轴日期，y轴出勤人数）
- 右：学员状态分布饼图（在读/休学/毕业）

**第三行 — 2个图表（各占 12 列）：**
- 左：课程状态分布饼图
- 右：教练工作量柱状图（x轴教练名，y轴课程数）

每个图表容器 `<div ref="chartRef" style="height:280px" />`，使用 `useChart` composable 初始化。

`onMounted` 并行调用 `getDashboardStats()` 和 `getCoachWorkload()`，填充统计卡片数据和图表 option。

**验证：** 浏览器打开 Dashboard，确认4张卡片数据正确，4个图表正常渲染

---

## Step 4: 后端 — 学员档案统计接口

**新增 DTO：**

`web/dto/student/StudentProfileResponse.java`
```java
public record StudentProfileResponse(StudentResponse student, StudentStats stats) {
    public record StudentStats(long attendanceTotal, long attendancePresent,
                               double attendanceRate, long fitnessTestCount, long trainingRecordCount) {}
}
```

`web/dto/student/StudentAttendanceStatsResponse.java`
```java
public record StudentAttendanceStatsResponse(String month, long present, long total, double rate) {}
```

`web/dto/student/StudentFitnessTrendResponse.java`
```java
public record StudentFitnessTrendResponse(String testItem, String unit, List<DataPoint> records) {
    public record DataPoint(LocalDate testDate, BigDecimal value) {}
}
```

**修改 `StudentService.java`，新增三个方法：**

`getProfile(Long id)` — 查学员基本信息 + 统计考勤/体测/训练数量

`getAttendanceStats(Long id)` — 按月分组统计出勤率（查近12个月）：
```java
// 用 Java Stream 对 attendance 记录按 yearMonth 分组，统计 present/total
```

`getFitnessTrends(Long id)` — 查该学员所有体测记录，按 itemName 分组，每组按 testDate 排序

**修改 `StudentController.java`，新增三个接口：**
```java
@GetMapping("/{id}/profile")
@GetMapping("/{id}/attendance-stats")
@GetMapping("/{id}/fitness-trends")
```
均需 `hasAnyRole('ADMIN','COACH')`

**验证：** 测试三个接口返回正确数据

---

## Step 5: 前端 — 新增 StudentProfileView.vue

**新增 `Code/admin-panel/src/views/students/StudentProfileView.vue`：**

页面结构：
```
顶部：<el-page-header @back="router.back()" :title="student.name" />

基本信息卡片：姓名、性别、出生日期、联系方式、状态

统计概览（4个数字卡片）：
  累计上课 | 出勤率 | 体测次数 | 训练次数

<el-tabs>
  考勤记录 Tab：
    - 月度出勤率折线图（useChart）
    - 考勤状态分布饼图（useChart）
    - 考勤列表（分页，调用 listAttendances({studentId, page, size})）

  体测记录 Tab：
    - 多项目趋势折线图（useChart，多条折线）
    - 体测列表（分页，调用 listFitnessTests({studentId, page, size})）

  训练记录 Tab：
    - 训练列表（分页，调用 listTrainingRecords({studentId, page, size})）
</el-tabs>
```

`onMounted` 并行调用：
- `getStudentProfile(id)` → 填充基本信息和统计概览
- `getStudentAttendanceStats(id)` → 填充考勤图表
- `getStudentFitnessTrends(id)` → 填充体测趋势图

**新增 API 函数（`modules.js`）：**
```js
export const getStudentProfile = (id) => http.get(`/students/${id}/profile`).then(unwrap)
export const getStudentAttendanceStats = (id) => http.get(`/students/${id}/attendance-stats`).then(unwrap)
export const getStudentFitnessTrends = (id) => http.get(`/students/${id}/fitness-trends`).then(unwrap)
```

**修改 `Code/admin-panel/src/router/index.js`：**
在 students 路由下新增子路由：
```js
{ path: '/students/:id/profile', name: 'StudentProfile',
  component: () => import('@/views/students/StudentProfileView.vue') }
```

**修改 `StudentListView.vue`：**
"详情"按钮改为 `router.push('/students/' + row.id + '/profile')`

**验证：** 点击学员列表的"详情"跳转到档案页，图表和列表正常显示

---

## Step 6: 后端 — 课程详情统计接口

**新增 DTO：**

`web/dto/course/CourseStudentResponse.java`
```java
public record CourseStudentResponse(Long studentId, String studentName, String gender,
                                    long attendanceTotal, long attendancePresent, double attendanceRate) {}
```

`web/dto/course/CourseAttendanceStatsResponse.java`
```java
public record CourseAttendanceStatsResponse(long totalSessions, double avgAttendanceRate,
                                            List<DailyAttendance> trend) {
    public record DailyAttendance(LocalDate date, long present, long total) {}
}
```

**修改 `CourseService.java`，新增两个方法：**
- `getCourseStudents(Long id)` — 查该课程所有考勤记录，按 studentId 分组，统计每人出勤率
- `getCourseAttendanceStats(Long id)` — 统计总场次、平均出勤率、按日期的趋势数据

**修改 `CourseController.java`，新增两个接口：**
```java
@GetMapping("/{id}/students")
@GetMapping("/{id}/attendance-stats")
```

---

## Step 7: 前端 — CourseListView.vue 详情对话框增强

**修改 `Code/admin-panel/src/views/courses/CourseListView.vue`：**

将现有"查看详情"对话框改为增强版，新增 Tabs：

**基本信息 Tab（原有内容）**

**报名学员 Tab（新增）：**
- 调用 `getCourseStudents(id)` 获取学员列表
- 表格显示：学员名、性别、出勤次数、出勤率
- 学员名可点击跳转到 `/students/:id/profile`

**考勤统计 Tab（新增）：**
- 调用 `getCourseAttendanceStats(id)` 获取统计数据
- 显示总场次、平均出勤率
- 考勤趋势折线图（useChart）

**新增 API 函数（`modules.js`）：**
```js
export const getCourseStudents = (id) => http.get(`/courses/${id}/students`).then(unwrap)
export const getCourseAttendanceStats = (id) => http.get(`/courses/${id}/attendance-stats`).then(unwrap)
```

**验证：** 点击课程"查看详情"，确认三个 Tab 数据正常

---

## 完成标准

- [ ] `GET /api/v1/statistics/dashboard` 返回完整统计数据
- [ ] Dashboard 页面显示4张统计卡片 + 4个 ECharts 图表
- [ ] 学员档案页可访问，显示统计概览和三个 Tab 的图表+列表
- [ ] 课程详情对话框显示报名学员和考勤统计
