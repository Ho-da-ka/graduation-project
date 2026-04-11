# ZF青少年体能培训教务管理平台 - 全面升级设计文档

## 1. 项目背景

本文档为毕业设计项目"ZF青少年体能培训教务管理平台"的全面升级方案设计文档。
项目包含三个子系统：后端服务（Spring Boot）、管理后台（Vue 3）、移动端小程序（UniApp）。

当前版本存在以下主要问题：
- 考勤管理无法编辑，只能删除重建
- 体测管理无法编辑和删除
- 课程管理无法删除
- 考勤、体测、训练记录列表无分页
- Dashboard 统计信息极少，无图表
- 缺少学员档案、课程详情等综合视图
- 缺少批量操作和数据导出功能

---

## 2. 升级范围总览

| 模块 | 类型 | 优先级 |
|------|------|--------|
| 考勤管理增强 | 基础功能补全 | P0 |
| 体测管理增强 | 基础功能补全 | P0 |
| 课程管理增强 | 基础功能补全 | P0 |
| 训练记录增强 | 基础功能补全 | P0 |
| Dashboard 改造 | 统计报表 | P1 |
| 学员档案页 | 统计报表 | P1 |
| 课程详情页增强 | 统计报表 | P1 |
| 课程容量管理 | 业务逻辑 | P2 |
| 课程冲突检测 | 业务逻辑 | P2 |
| 批量操作 | 业务逻辑 | P2 |
| 数据导出 | 业务逻辑 | P2 |
| 用户体验优化 | UX | P3 |
| 技术债务清理 | 工程化 | P3 |

---

## 3. 基础功能补全

### 3.1 考勤管理增强

#### 3.1.1 后端改造

**新增接口：**

```
PUT /api/v1/attendances/{id}
```
请求体：
```json
{
  "status": "LATE",
  "remark": "迟到10分钟"
}
```
响应：更新后的 AttendanceResponse

**分页支持：**

现有 `GET /api/v1/attendances` 增加分页参数：
- `page`（默认 0）
- `size`（默认 20）

响应改为 `PageResponse<AttendanceResponse>`

**业务校验：**
- 同一学员同一课程同一天不允许重复考勤（创建时校验）
- 考勤日期不能晚于当前日期

**涉及文件：**
- `AttendanceController.java` - 新增 PUT 接口，GET 接口增加分页参数
- `AttendanceService.java` / `AttendanceServiceImpl.java` - 新增 update 方法，page 方法改造
- `AttendanceUpdateRequest.java` - 新增 DTO

#### 3.1.2 前端改造（admin-panel）

**AttendanceView.vue 改造：**
- 表格新增"编辑"操作列按钮
- 新增编辑对话框（复用创建对话框的表单结构，仅开放 status 和 remark 字段）
- 表格底部增加 `el-pagination` 分页组件
- 新增批量删除：表格开启多选，顶部增加"批量删除"按钮
- 无数据时显示空状态提示

---

### 3.2 体测管理增强

#### 3.2.1 后端改造

**新增接口：**

```
PUT /api/v1/fitness-tests/{id}
```
请求体：
```json
{
  "testDate": "2026-04-11",
  "testItem": "50米跑",
  "value": 8.5,
  "unit": "秒",
  "remark": ""
}
```

```
DELETE /api/v1/fitness-tests/{id}
```

**分页支持：**

`GET /api/v1/fitness-tests` 增加分页参数，响应改为 `PageResponse<FitnessTestResponse>`

**业务校验：**
- 体测日期不能晚于当前日期
- value 必须大于 0

**涉及文件：**
- `FitnessTestController.java` - 新增 PUT、DELETE 接口
- `FitnessTestService.java` / `FitnessTestServiceImpl.java` - 新增 update、delete 方法
- `FitnessTestUpdateRequest.java` - 新增 DTO

#### 3.2.2 前端改造（admin-panel）

**FitnessView.vue 改造：**
- 表格新增"编辑"和"删除"操作列按钮
- 新增编辑对话框
- 表格底部增加分页组件
- 体测项目选择改为下拉框（预设常见项目）+ 自定义输入
- 选择预设项目后自动填充单位
- 无数据时显示空状态提示

**预设体测项目：**
```js
const FITNESS_ITEMS = [
  { label: '身高', unit: 'cm' },
  { label: '体重', unit: 'kg' },
  { label: '50米跑', unit: '秒' },
  { label: '立定跳远', unit: 'cm' },
  { label: '坐位体前屈', unit: 'cm' },
  { label: '引体向上', unit: '次' },
  { label: '仰卧起坐', unit: '次/分钟' },
  { label: '1000米跑', unit: '秒' },
  { label: '800米跑', unit: '秒' },
]
```

---

### 3.3 课程管理增强

#### 3.3.1 后端改造

**新增接口：**

```
DELETE /api/v1/courses/{id}
```

**业务校验（软删除策略）：**
- 检查是否有关联考勤记录
- 检查是否有关联训练记录
- 如果有关联数据，返回 400 错误，提示关联数量
- 前端可选择"强制删除"（级联删除关联记录），需传 `force=true` 参数

**涉及文件：**
- `CourseController.java` - 新增 DELETE 接口
- `CourseService.java` / `CourseServiceImpl.java` - 新增 delete 方法

#### 3.3.2 前端改造（admin-panel）

**CourseListView.vue 改造：**
- 表格新增"删除"操作列按钮
- 删除前显示确认对话框
- 如果后端返回关联数据错误，显示详细提示并提供"强制删除"选项

---

### 3.4 训练记录增强

#### 3.4.1 后端改造

**新增接口：**

```
DELETE /api/v1/training-records/{id}
```

**分页支持：**

`GET /api/v1/training-records` 增加分页参数，响应改为 `PageResponse<TrainingRecordResponse>`

**涉及文件：**
- `TrainingRecordController.java` - 新增 DELETE 接口，GET 接口增加分页
- `TrainingRecordService.java` / `TrainingRecordServiceImpl.java` - 新增 delete 方法

#### 3.4.2 前端改造（admin-panel）

**TrainingRecordView.vue 改造：**
- 表格新增"删除"操作列按钮
- 表格底部增加分页组件
- 无数据时显示空状态提示

---

## 4. 统计报表模块

### 4.1 Dashboard 全面改造

#### 4.1.1 后端改造

**新增统计接口：**

```
GET /api/v1/statistics/dashboard
```

响应结构：
```json
{
  "students": {
    "total": 120,
    "active": 98,
    "inactive": 15,
    "graduated": 7
  },
  "courses": {
    "total": 30,
    "planned": 5,
    "ongoing": 12,
    "completed": 10,
    "cancelled": 3
  },
  "coaches": {
    "total": 8,
    "active": 7,
    "inactive": 1
  },
  "attendance": {
    "thisMonthTotal": 320,
    "thisMonthPresent": 290,
    "thisMonthRate": 0.906,
    "last7Days": [
      { "date": "2026-04-05", "present": 45, "total": 50 }
    ]
  },
  "recentFitnessCount": 18,
  "recentTrainingCount": 42
}
```

```
GET /api/v1/statistics/coach-workload
```
返回每位教练的课程数、训练记录数，用于柱状图排行。

**涉及新增文件：**
- `StatisticsController.java`
- `StatisticsService.java` / `StatisticsServiceImpl.java`
- `DashboardStatsResponse.java`
- `CoachWorkloadResponse.java`

#### 4.1.2 前端改造（admin-panel）

**DashboardView.vue 全面改造，布局：**

```
第一行（4列统计卡片）
  学员总数 | 课程总数 | 教练总数 | 本月出勤率

第二行（左右各半）
  近7天考勤趋势折线图 | 学员状态分布饼图

第三行（左右各半）
  课程状态分布饼图 | 教练工作量柱状图
```

**技术选型：**
- 引入 ECharts 5.x：`npm install echarts`
- 封装 `useChart(domRef, option)` composable 统一图表初始化与销毁

---

### 4.2 学员档案页（新增）

#### 4.2.1 后端改造

**新增接口：**

```
GET /api/v1/students/{id}/profile
```
响应：学员基本信息 + 统计概览
```json
{
  "student": { "...StudentResponse字段" },
  "stats": {
    "attendanceTotal": 80,
    "attendancePresent": 72,
    "attendanceRate": 0.9,
    "fitnessTestCount": 12,
    "trainingRecordCount": 35
  }
}
```

```
GET /api/v1/students/{id}/attendance-stats
```
按月统计出勤率（折线图数据）：
```json
[
  { "month": "2025-10", "present": 18, "total": 20, "rate": 0.9 },
  { "month": "2025-11", "present": 16, "total": 18, "rate": 0.889 }
]
```

```
GET /api/v1/students/{id}/fitness-trends
```
体测趋势（按项目分组的时间序列）：
```json
[
  {
    "testItem": "50米跑",
    "unit": "秒",
    "records": [
      { "testDate": "2025-09-01", "value": 9.2 },
      { "testDate": "2025-12-01", "value": 8.8 }
    ]
  }
]
```

**涉及新增文件：**
- `StudentProfileResponse.java`
- `StudentAttendanceStatsResponse.java`
- `StudentFitnessTrendResponse.java`
- `StudentController.java` 新增三个 GET 接口
- `StudentService.java` / `StudentServiceImpl.java` 新增 `getProfile`、`getAttendanceStats`、`getFitnessTrends` 方法

#### 4.2.2 前端改造（admin-panel）

**新增 `StudentProfileView.vue`，路由：`/students/:id/profile`**

页面结构：
- 顶部返回按钮 + 学员姓名
- 基本信息卡片
- 统计概览卡片（4个数字：累计上课、出勤率、体测次数、训练次数）
- Tabs：考勤记录 / 体测记录 / 训练记录

**考勤 Tab：** 列表（分页）+ 月度出勤率折线图 + 状态分布饼图

**体测 Tab：** 列表（分页）+ 多项目趋势折线图（可选择项目）

**训练 Tab：** 列表（分页）+ 训练强度分布饼图

StudentListView.vue 中"详情"按钮改为跳转 `/students/:id/profile`。

---

### 4.3 课程详情页增强

#### 4.3.1 后端改造

**新增接口：**

```
GET /api/v1/courses/{id}/students
```
返回报名该课程的学员列表及每人出勤率：
```json
[
  {
    "studentId": 1,
    "studentName": "张三",
    "gender": "MALE",
    "attendanceTotal": 10,
    "attendancePresent": 9,
    "attendanceRate": 0.9
  }
]
```

```
GET /api/v1/courses/{id}/attendance-stats
```
课程整体考勤统计：
```json
{
  "totalSessions": 20,
  "avgAttendanceRate": 0.88,
  "trend": [
    { "date": "2026-03-01", "present": 12, "total": 15 }
  ]
}
```

**涉及文件：** `CourseController.java` 新增两个接口。

#### 4.3.2 前端改造（admin-panel）

**CourseListView.vue 的"查看详情"改为增强详情对话框：**
- 课程基本信息
- 报名学员列表（可点击跳转学员档案）
- 课程考勤趋势折线图
- 训练记录预览（最近5条）

---

## 5. 业务逻辑增强

### 5.1 课程容量管理

#### 5.1.1 后端改造

**Course 实体新增字段：**
- `maxCapacity INTEGER NULL` — 最大容量（NULL 表示不限制）
- `currentEnrollment` — 不落库，由 Service 层实时统计（通过 attendance 表 distinct student 数）

**业务逻辑：**
- 创建考勤时，检查该课程下不重复的学员数量是否已达到 `maxCapacity`
- 达到上限时返回 400，提示"课程报名已达上限（X/X）"

**接口变更：**
- `CourseCreateRequest` / `CourseUpdateRequest` 新增 `maxCapacity` 字段（可选）
- `CourseResponse` 新增 `maxCapacity` 和 `currentEnrollment` 字段

#### 5.1.2 前端改造

- 课程创建/编辑表单新增"最大容量"数字输入框（选填）
- 课程列表新增"已报名/容量"列（如 "12/20" 或 "15/不限"）

---

### 5.2 课程冲突检测

#### 5.2.1 后端改造

**Course 实体新增字段：**
- `courseDate DATE NULL` — 上课日期
- `startTime TIME NULL` — 开始时间
- `endTime TIME NULL` — 结束时间

**冲突检测逻辑（`CourseConflictChecker` 组件）：**
- 创建/更新课程时，如果填写了时间段，检测同一教练是否有时间重叠的其他课程
- 冲突时返回 409 状态码，body 包含冲突课程信息
- 前端可选择"忽略冲突强制创建"（传 `ignoreConflict=true`）

#### 5.2.2 前端改造

- 课程表单新增日期选择器 + 时间区间选择器（选填）
- 提交时如果 409 响应，弹出确认对话框："检测到时间冲突：[冲突课程名]，是否仍然创建？"

---

### 5.3 批量操作

#### 5.3.1 批量考勤

**新增后端接口：**
```
POST /api/v1/attendances/batch
```
请求体：
```json
{
  "courseId": 1,
  "attendanceDate": "2026-04-11",
  "studentIds": [1, 2, 3, 4, 5],
  "status": "PRESENT"
}
```
- 忽略已存在的同课程同日期同学员的记录（幂等）

**前端新增"批量考勤"功能：**
- AttendanceView.vue 顶部增加"批量考勤"按钮
- 弹出对话框：选择课程 → 选择日期 → 显示该课程所有报名学员 → 可调整每人状态 → 一键提交

#### 5.3.2 数据导出（Excel）

**技术选型（纯前端实现）：**
- 引入 `xlsx`：`npm install xlsx`
- 封装 `utils/export.ts`，提供 `exportToExcel(data, columns, filename)` 函数

**支持导出的页面：**
- StudentListView.vue：导出学员列表
- AttendanceView.vue：导出当前筛选结果
- FitnessView.vue：导出体测记录
- TrainingRecordView.vue：导出训练记录

每个列表页顶部新增"导出 Excel"按钮。

#### 5.3.3 学员批量导入（Excel）

**后端新增接口：**
```
POST /api/v1/students/import
Content-Type: multipart/form-data
```
- 使用 Apache POI 解析 Excel
- 返回导入结果：成功数、失败数、失败详情

**前端：**
- StudentListView.vue 顶部新增"导入"按钮和"下载模板"链接
- 导入完成后显示结果摘要

**依赖（pom.xml 新增）：**
```xml
<dependency>
  <groupId>org.apache.poi</groupId>
  <artifactId>poi-ooxml</artifactId>
  <version>5.3.0</version>
</dependency>
```

---

## 6. 用户体验优化

### 6.1 空状态统一处理

所有列表页在无数据时显示：
- 图标（Element Plus 的 `el-empty` 组件）
- 提示文字（如"暂无学员数据"）
- 操作引导按钮（如"立即新增学员"）

### 6.2 加载状态优化

- 所有表格请求期间显示 `v-loading` 遮罩
- 提交按钮在请求期间禁用并显示 loading 图标
- 页面级数据加载使用骨架屏（`el-skeleton`）

### 6.3 HTTP 错误统一处理

**admin-panel/src/api/http.js 改造：**
- 响应拦截器新增对 400、403、500 的统一 `ElMessage.error` 提示
- 403 提示"权限不足"，500 提示"服务器内部错误，请稍后重试"
- 网络超时提示"网络请求超时，请检查网络连接"

### 6.4 表单体验优化

- 所有表单的必填项标注红色星号（Element Plus 原生支持）
- 错误提示文字显示在输入框下方
- 所有表单已有草稿自动保存（`utils/draft.js`），确认所有表单都已接入

---

## 7. 技术债务清理

### 7.1 admin-panel TypeScript 迁移

将所有 `.js` 文件逐步迁移为 `.ts`：
- `src/api/http.js` → `http.ts`
- `src/api/modules.js` → 拆分为按业务域的 `src/api/modules/*.ts`
- `src/router/index.js` → `index.ts`
- `src/utils/*.js` → `*.ts`
- 新增 `src/types/` 目录，定义业务实体类型

**API 模块拆分目标结构：**
```
src/api/modules/
  auth.ts
  students.ts
  courses.ts
  coaches.ts
  attendance.ts
  fitness.ts
  training.ts
  statistics.ts
```

### 7.2 后端 Swagger UI 集成

**pom.xml 新增依赖：**
```xml
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
  <version>2.6.0</version>
</dependency>
```

访问地址：`http://localhost:8080/swagger-ui/index.html`

需要在 SecurityConfig 中放行 `/swagger-ui/**` 和 `/v3/api-docs/**`。

### 7.3 JWT Secret 强度警告

在 `JwtTokenProvider` 构造方法中，当 secret 不足 32 字节时用 SHA-256 补强的同时，使用 `log.warn()` 输出警告：
```
[SECURITY] JWT secret is shorter than 32 bytes and has been hashed. Please configure a strong secret in production.
```

### 7.4 工程化优化

**新增 `.env.example` 文件（三个子项目各一份）：**

admin-panel/.env.example:
```
VITE_API_BASE=/api/v1
```

mobile-app/.env.example:
```
VITE_BASE_URL=http://localhost:8080
```

backend .env 说明（在 README 中补充）：
```
security.jwt.secret=<至少32位随机字符串>
security.jwt.access-token-expire-seconds=7200
```

**更新 .gitignore（根目录）：**
```
run-logs/
Code/admin-panel/dist/
Code/mobile-app/dist/
```

### 7.5 单元测试补充

为以下 Service 类编写单元测试，覆盖核心业务逻辑：
- `StudentServiceImpl` — create、update、delete、page
- `AttendanceServiceImpl` — create（含重复校验）、update、批量创建
- `FitnessTestServiceImpl` — create、update、delete
- `CourseServiceImpl` — create、delete（含关联数据校验）
- `StatisticsServiceImpl` — dashboard 统计

使用 Mockito mock Repository 层，测试覆盖率目标 ≥ 60%。

---

## 8. 实施计划

| 阶段 | 内容 | 预计工时 |
|------|------|----------|
| 第1-2天 | 基础功能补全（考勤/体测/课程/训练的增删改+分页） | 2天 |
| 第3-4天 | Dashboard改造 + ECharts集成 + 统计后端接口 | 2天 |
| 第5-6天 | 学员档案页 + 课程详情页增强 | 2天 |
| 第7-8天 | 课程容量/冲突检测 + 批量操作 + 数据导出 | 2天 |
| 第9天 | 用户体验优化（空状态/加载/错误提示） | 1天 |
| 第10天 | 技术债务清理 + 单元测试 + 全面回归测试 | 1天 |

---

## 9. 关键技术决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 前端图表库 | ECharts 5.x | 功能强大，文档完善，适合毕业设计展示 |
| Excel 导出 | 纯前端（xlsx 库） | 无需后端改造，实现简单 |
| Excel 导入 | 后端（Apache POI） | 需要数据校验和事务保证 |
| TypeScript 迁移 | 渐进式（只迁移修改到的文件） | 降低迁移风险，不引入大规模变更 |
| 课程删除策略 | 软阻止 + 强制删除选项 | 保护数据完整性，同时不阻塞管理员操作 |
| 分页默认值 | page=0, size=20 | 与现有接口保持一致 |

