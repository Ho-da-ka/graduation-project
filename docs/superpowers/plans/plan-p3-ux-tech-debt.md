# Plan P3: 用户体验优化 + 技术债务清理

Spec: `docs/superpowers/specs/full-upgrade-spec.md` §6-7
依赖: P0 完成后可独立执行

---

## Step 1: HTTP 错误统一处理

**修改 `Code/admin-panel/src/api/http.js`：**

在响应拦截器的 `return Promise.reject(error)` 之前，新增统一错误提示：

```js
// 在现有 401 处理块之后，最终 reject 之前插入：
if (status === 403) {
  ElMessage.error('权限不足，无法执行此操作')
} else if (status >= 500) {
  ElMessage.error('服务器内部错误，请稍后重试')
} else if (!status) {
  ElMessage.error('网络请求超时，请检查网络连接')
}
```

注意：只在非 401 且非 `_isRefreshCall` 的情况下显示，避免重复提示。

**验证：** 手动触发 403（用 coach 账号访问 admin 接口），确认提示"权限不足"

---

## Step 2: 空状态统一处理

**在以下页面的 `<el-table>` 下方新增空状态（当 `rows.length === 0 && !loading` 时显示）：**

- `AttendanceView.vue`：`<el-empty description="暂无考勤记录，请调整筛选条件或新增考勤" />`
- `FitnessView.vue`：`<el-empty description="暂无体测记录，请选择学员或新增体测" />`
- `TrainingRecordView.vue`：`<el-empty description="暂无训练记录" />`
- `CoachListView.vue`：`<el-empty description="暂无教练数据" />`
- `CourseListView.vue`：`<el-empty description="暂无课程数据" />`
- `StudentListView.vue`：`<el-empty description="暂无学员数据" />`

实现方式：在 `<el-table>` 后紧跟：
```html
<el-empty v-if="!loading && rows.length === 0" description="..." />
```

**验证：** 清空筛选条件使结果为空，确认空状态提示正常显示

---

## Step 3: 加载状态优化

**所有列表页已有 `v-loading="loading"`，补充以下细节：**

- 提交按钮已有 `:loading="saving"`，确认所有表单的提交按钮都已绑定
- 在 `StudentProfileView.vue` 的页面级加载期间，用 `v-loading` 包裹整个内容区

**验证：** 网络较慢时，确认表格有 loading 遮罩，按钮有 loading 状态

---

## Step 4: 后端 Swagger UI 集成

**修改 `Code/backend-service/ManagementPlatform/pom.xml`，新增依赖：**
```xml
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
  <version>2.6.0</version>
</dependency>
```

**修改 `SecurityConfig.java`，在 `permitAll()` 路径中新增：**
```java
"/swagger-ui/**",
"/swagger-ui.html",
"/v3/api-docs/**"
```

**验证：** 重启后访问 `http://localhost:8080/swagger-ui/index.html`，确认所有接口可见

---

## Step 5: JWT Secret 强度警告

**修改 `JwtTokenProvider.java`：**

在 `buildSigningKey()` 方法中，当 `bytes.length < 32` 时新增日志警告：

```java
private static final org.slf4j.Logger log =
    org.slf4j.LoggerFactory.getLogger(JwtTokenProvider.class);

private SecretKey buildSigningKey(String secret) {
    byte[] bytes = secret.getBytes(StandardCharsets.UTF_8);
    if (bytes.length < 32) {
        log.warn("[SECURITY] JWT secret is shorter than 32 bytes and has been hashed. " +
                 "Please configure a strong secret in production.");
        try {
            bytes = MessageDigest.getInstance("SHA-256").digest(bytes);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to build signing key", ex);
        }
    }
    return Keys.hmacShaKeyFor(bytes);
}
```

**验证：** 用短 secret 启动，确认控制台打印 `[SECURITY]` 警告

---

## Step 6: 工程化优化

**新增 `Code/admin-panel/.env.example`：**
```
VITE_API_BASE=/api/v1
```

**新增 `Code/mobile-app/.env.example`：**
```
VITE_BASE_URL=http://localhost:8080
```

**修改根目录 `.gitignore`（如不存在则新建）：**
```
run-logs/
Code/admin-panel/dist/
Code/mobile-app/dist/
Code/admin-panel/.npm-cache/
```

**验证：** `git status` 确认 dist/ 和 run-logs/ 不再被追踪

---

## Step 7: admin-panel API 模块拆分（TypeScript 渐进式迁移）

**将 `src/api/modules.js` 拆分为按业务域的独立文件：**

新建目录 `Code/admin-panel/src/api/modules/`，创建以下文件（保持 `.js` 格式，不强制迁移 TS）：

- `auth.js` — login, logout, changeOwnPassword, adminSetPassword, adminResetPassword
- `students.js` — listStudents, getStudent, createStudent, updateStudent, deleteStudent, getStudentProfile, getStudentAttendanceStats, getStudentFitnessTrends, importStudents
- `courses.js` — listCourses, getCourse, createCourse, updateCourse, deleteCourse, getCourseStudents, getCourseAttendanceStats
- `coaches.js` — listCoaches, listCoachOptions, getCoach, createCoach, updateCoach, deleteCoach
- `attendance.js` — listAttendances, createAttendance, updateAttendance, deleteAttendance, batchCreateAttendance
- `fitness.js` — listFitnessTests, createFitnessTest, updateFitnessTest, deleteFitnessTest
- `training.js` — listTrainingRecords, getTrainingRecord, createTrainingRecord, updateTrainingRecord, deleteTrainingRecord
- `statistics.js` — getDashboardStats, getCoachWorkload

每个文件顶部 `import http from '../http'`，底部 `export { ... }`。

**删除旧的 `src/api/modules.js`。**

**更新所有 View 文件的 import 路径：**
- `AttendanceView.vue`：`import { ... } from '../../api/modules/attendance'`
- `FitnessView.vue`：`import { ... } from '../../api/modules/fitness'`
- 以此类推

**验证：** `npm run build` 无报错，所有页面功能正常

---

## Step 8: 单元测试补充

**在 `src/test/java/com/shuzi/managementplatform/` 下新增测试类：**

`AttendanceServiceTest.java` — 测试以下场景：
- `create()` 正常创建
- `create()` 重复考勤抛出异常（如果已加重复校验）
- `batchCreate()` 幂等性（重复调用不重复插入）
- `update()` 更新状态
- `delete()` 记录不存在时抛出 `ResourceNotFoundException`

`FitnessTestServiceTest.java` — 测试：
- `create()` 正常创建
- `update()` 正常更新
- `delete()` 逻辑删除（`@TableLogic` 触发）

`CourseServiceTest.java` — 测试：
- `delete()` 有关联数据时抛出 `BusinessException`
- `delete(force=true)` 级联删除

`StatisticsServiceTest.java` — 测试：
- `getDashboard()` 返回非 null 结构

使用 `@ExtendWith(MockitoExtension.class)`，mock 所有 Mapper 依赖。

**验证：** `mvn test` 通过，覆盖率 ≥ 60%

---

## 完成标准

- [ ] HTTP 403/500/超时有统一错误提示
- [ ] 所有列表页有空状态提示
- [ ] Swagger UI 可访问（`/swagger-ui/index.html`）
- [ ] 启动时弱 JWT secret 打印警告
- [ ] `.env.example` 文件存在，`.gitignore` 排除 dist/ 和 run-logs/
- [ ] API 模块按业务域拆分，旧 `modules.js` 删除
- [ ] 单元测试通过，覆盖率 ≥ 60%
