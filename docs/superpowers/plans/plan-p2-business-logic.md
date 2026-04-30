# Plan P2: 业务逻辑增强

Spec: `docs/superpowers/specs/full-upgrade-spec.md` §5
依赖: Plan P0 完成

---

## Step 1: 后端 — 课程容量管理

**修改 `Course.java` 实体：**
新增字段：
```java
@TableField("max_capacity")
private Integer maxCapacity;  // NULL = 不限制
```

**修改数据库（手动执行 SQL）：**
```sql
ALTER TABLE courses ADD COLUMN max_capacity INT NULL COMMENT '最大容量，NULL表示不限制';
```

**修改 `CourseCreateRequest.java` / `CourseUpdateRequest.java`：**
新增 `Integer maxCapacity` 字段（无 `@NotNull`，可选）

**修改 `CourseResponse.java`：**
新增 `Integer maxCapacity` 和 `long currentEnrollment` 字段

**修改 `CourseService.java`：**
- `create()` / `update()` 中设置 `maxCapacity`
- `toResponse()` 中实时统计 `currentEnrollment`：
  ```java
  long enrollment = attendanceRecordMapper.selectCount(
      Wrappers.<AttendanceRecord>lambdaQuery()
          .eq(AttendanceRecord::getCourseId, course.getId())
          .select(AttendanceRecord::getStudentId)  // distinct 通过 groupBy 实现
  );
  // 注：用 selectMaps + groupBy studentId 统计不重复学员数
  ```

**修改 `AttendanceService.create()`：**
创建考勤前检查容量：
```java
Course course = courseService.getEntityById(request.courseId());
if (course.getMaxCapacity() != null) {
    long enrolled = countDistinctStudents(course.getId());
    boolean alreadyEnrolled = attendanceRecordMapper.selectCount(
        Wrappers.<AttendanceRecord>lambdaQuery()
            .eq(AttendanceRecord::getCourseId, request.courseId())
            .eq(AttendanceRecord::getStudentId, request.studentId())
    ) > 0;
    if (!alreadyEnrolled && enrolled >= course.getMaxCapacity()) {
        throw new BusinessException(HttpStatus.CONFLICT,
            "课程报名已达上限（" + enrolled + "/" + course.getMaxCapacity() + "）");
    }
}
```

**验证：** 创建容量为2的课程，添加第3个不同学员的考勤时应返回 409

---

## Step 2: 前端 — 课程容量字段

**修改 `Code/admin-panel/src/views/courses/CourseListView.vue`：**
- 创建/编辑表单新增"最大容量"数字输入框（`el-input-number`，`min=1`，选填，placeholder="不填则不限制"）
- 课程列表表格新增"报名/容量"列，显示 `currentEnrollment + '/' + (maxCapacity || '不限')`

**验证：** 创建带容量的课程，列表显示报名人数

---

## Step 3: 后端 — 课程冲突检测

**修改 `Course.java` 实体，新增字段：**
```java
@TableField("course_date")
private LocalDate courseDate;

@TableField("class_start_time")
private LocalTime classStartTime;

@TableField("class_end_time")
private LocalTime classEndTime;
```

**修改数据库：**
```sql
ALTER TABLE courses
  ADD COLUMN course_date DATE NULL,
  ADD COLUMN class_start_time TIME NULL,
  ADD COLUMN class_end_time TIME NULL;
```

**修改 `CourseCreateRequest.java` / `CourseUpdateRequest.java`：**
新增三个可选字段（均无 `@NotNull`）

**新增 `CourseConflictChecker.java`（`config` 包下）：**
```java
@Component
public class CourseConflictChecker {
    public List<Course> findConflicts(CourseMapper mapper, String coachName,
                                      LocalDate date, LocalTime start, LocalTime end, Long excludeId) {
        if (date == null || start == null || end == null) return List.of();
        return mapper.selectList(Wrappers.<Course>lambdaQuery()
            .eq(Course::getCoachName, coachName)
            .eq(Course::getCourseDate, date)
            .ne(excludeId != null, Course::getId, excludeId)
            .lt(Course::getClassStartTime, end)
            .gt(Course::getClassEndTime, start));
    }
}
```

**修改 `CourseService.create()` / `update()`：**
```java
List<Course> conflicts = conflictChecker.findConflicts(...);
if (!ignoreConflict && !conflicts.isEmpty()) {
    throw new BusinessException(HttpStatus.CONFLICT,
        "教练时间冲突：" + conflicts.get(0).getName());
}
```

**修改 `CourseController`：**
`POST /` 和 `PUT /{id}` 新增 `@RequestParam(defaultValue="false") boolean ignoreConflict` 参数

**验证：** 创建两个同教练同时间段的课程，第二个应返回 409

---

## Step 4: 前端 — 课程冲突检测

**修改 `CourseListView.vue`：**
- 创建/编辑表单新增日期选择器（`courseDate`）和时间区间选择器（`classStartTime` / `classEndTime`，均选填）
- 提交时捕获 409 响应：弹出 `ElMessageBox.confirm`，提示冲突课程名，确认后重新提交并带 `ignoreConflict=true`

**验证：** 创建冲突课程时弹出确认框，确认后成功创建

---

## Step 5: 后端 — 批量考勤接口

**新增 `web/dto/attendance/AttendanceBatchCreateRequest.java`：**
```java
public record AttendanceBatchCreateRequest(
    @NotNull Long courseId,
    @NotNull LocalDate attendanceDate,
    @NotNull @Size(min=1) List<Long> studentIds,
    @NotNull AttendanceStatus status
) {}
```

**修改 `AttendanceService.java`，新增 `batchCreate()` 方法：**
```java
@Transactional
public List<AttendanceResponse> batchCreate(AttendanceBatchCreateRequest request) {
    Course course = courseService.getEntityById(request.courseId());
    List<AttendanceResponse> results = new ArrayList<>();
    for (Long studentId : request.studentIds()) {
        // 幂等：已存在则跳过
        boolean exists = attendanceRecordMapper.selectCount(
            Wrappers.<AttendanceRecord>lambdaQuery()
                .eq(AttendanceRecord::getCourseId, request.courseId())
                .eq(AttendanceRecord::getStudentId, studentId)
                .eq(AttendanceRecord::getAttendanceDate, request.attendanceDate())
        ) > 0;
        if (exists) continue;
        Student student = studentService.getEntityById(studentId);
        AttendanceRecord record = new AttendanceRecord();
        record.setStudentId(studentId);
        record.setCourseId(request.courseId());
        record.setAttendanceDate(request.attendanceDate());
        record.setStatus(request.status());
        attendanceRecordMapper.insert(record);
        results.add(toResponse(record, student, course));
    }
    return results;
}
```

**修改 `AttendanceController.java`：**
```java
@PostMapping("/batch")
@PreAuthorize("hasAnyRole('ADMIN','COACH')")
public ApiResponse<List<AttendanceResponse>> batchCreate(@Valid @RequestBody AttendanceBatchCreateRequest request) {
    return ApiResponse.ok("batch attendance recorded", attendanceService.batchCreate(request));
}
```

**验证：** POST `/api/v1/attendances/batch` 批量创建，重复调用应幂等

---

## Step 6: 前端 — 批量考勤对话框

**修改 `AttendanceView.vue`：**
工具栏新增"批量考勤"按钮，点击打开批量考勤对话框：

```
对话框流程：
1. 选择课程（el-select）
2. 选择日期（el-date-picker）
3. 点击"加载学员"→ 调用 getCourseStudents(courseId) 获取该课程学员列表
4. 显示学员表格，每行有状态下拉（默认 PRESENT）
5. 点击"一键提交"→ 调用 batchCreateAttendance(payload)
```

**新增 API 函数：**
```js
export const batchCreateAttendance = (payload) => http.post('/attendances/batch', payload).then(unwrap)
```

**验证：** 选择课程和日期，加载学员后批量提交，考勤列表刷新

---

## Step 7: 前端 — Excel 导出

**安装依赖：**
```bash
cd Code/admin-panel && npm install xlsx
```

**新增 `Code/admin-panel/src/utils/export.js`：**
```js
import * as XLSX from 'xlsx'

export function exportToExcel(data, columns, filename) {
  const header = columns.map(c => c.label)
  const rows = data.map(row => columns.map(c => row[c.prop] ?? ''))
  const ws = XLSX.utils.aoa_to_sheet([header, ...rows])
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, 'Sheet1')
  XLSX.writeFile(wb, filename + '.xlsx')
}
```

**在以下4个页面各新增"导出 Excel"按钮：**

`StudentListView.vue`：
```js
exportToExcel(rows.value, [
  { label: 'ID', prop: 'id' }, { label: '姓名', prop: 'name' },
  { label: '性别', prop: 'gender' }, { label: '状态', prop: 'status' }
], '学员列表')
```

`AttendanceView.vue`：
```js
exportToExcel(rows.value, [
  { label: 'ID', prop: 'id' }, { label: '学员', prop: 'studentName' },
  { label: '课程', prop: 'courseName' }, { label: '日期', prop: 'attendanceDate' },
  { label: '状态', prop: 'status' }, { label: '备注', prop: 'note' }
], '考勤记录')
```

`FitnessView.vue` 和 `TrainingRecordView.vue` 类似。

**验证：** 点击导出按钮，浏览器下载 xlsx 文件，内容正确

---

## Step 8: 后端 — 学员批量导入

**pom.xml 新增依赖：**
```xml
<dependency>
  <groupId>org.apache.poi</groupId>
  <artifactId>poi-ooxml</artifactId>
  <version>5.3.0</version>
</dependency>
```

**新增 `web/dto/student/StudentImportResult.java`：**
```java
public record StudentImportResult(int successCount, int failCount, List<String> errors) {}
```

**修改 `StudentService.java`，新增 `importFromExcel(MultipartFile file)` 方法：**
- 用 Apache POI 读取 Excel（`WorkbookFactory.create(file.getInputStream())`）
- 逐行解析：姓名（必填）、性别、出生日期、联系方式
- 每行调用 `create()` 方法，捕获异常记录到 errors 列表
- 返回 `StudentImportResult`

**修改 `StudentController.java`：**
```java
@PostMapping("/import")
@PreAuthorize("hasRole('ADMIN')")
public ApiResponse<StudentImportResult> importStudents(@RequestParam("file") MultipartFile file) {
    return ApiResponse.ok(studentService.importFromExcel(file));
}
```

**新增模板下载接口：**
```java
@GetMapping("/import-template")
@PreAuthorize("hasRole('ADMIN')")
public void downloadTemplate(HttpServletResponse response) throws IOException {
    // 生成含表头的空 Excel 并写入 response
}
```

**验证：** 上传含3行数据的 Excel，返回 `{successCount:3, failCount:0}`

---

## Step 9: 前端 — 学员导入功能

**修改 `StudentListView.vue`：**
工具栏新增"导入"按钮和"下载模板"链接：
- "下载模板"：`window.open('/api/v1/students/import-template')`
- "导入"：使用 `<el-upload>` 组件，`action` 指向导入接口，上传完成后显示结果摘要对话框

**验证：** 下载模板，填写数据后上传，列表刷新并显示导入结果

---

## 完成标准

- [ ] 课程支持设置最大容量，超出时创建考勤返回 409
- [ ] 课程支持时间段，同教练时间冲突时返回 409 并可强制忽略
- [ ] 批量考勤对话框可正常使用，幂等
- [ ] 四个列表页均有"导出 Excel"按钮，导出内容正确
- [ ] 学员列表支持 Excel 导入，显示导入结果摘要
