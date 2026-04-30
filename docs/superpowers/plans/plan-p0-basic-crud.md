# Plan P0: 基础功能补全

Spec: `docs/superpowers/specs/full-upgrade-spec.md` §3

---

## Step 1: 后端 — 考勤编辑接口 + 分页

**新增文件：**
`Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/attendance/AttendanceUpdateRequest.java`

```java
package com.shuzi.managementplatform.web.dto.attendance;

import com.shuzi.managementplatform.domain.enums.AttendanceStatus;
import jakarta.validation.constraints.NotNull;

public record AttendanceUpdateRequest(
        @NotNull AttendanceStatus status,
        String note
) {}
```

**修改 `AttendanceService.java`：**
- 新增 `update(Long id, AttendanceUpdateRequest request)` 方法
- 将 `search()` 改为 `page(Long studentId, Long courseId, LocalDate startDate, LocalDate endDate, int page, int size)` 返回 `IPage<AttendanceResponse>`

**修改 `AttendanceController.java`：**
- 新增 `PUT /{id}` 接口，调用 `attendanceService.update()`
- `GET /` 接口增加 `page`（默认0）和 `size`（默认20）参数，响应改为 `ApiResponse<PageResponse<AttendanceResponse>>`

**验证：** 用 curl 或 Postman 测试 `PUT /api/v1/attendances/1` 和 `GET /api/v1/attendances?page=0&size=20`

---

## Step 2: 前端 — AttendanceView.vue 增加编辑 + 分页

**修改 `Code/admin-panel/src/views/attendances/AttendanceView.vue`：**

1. `search()` 函数改为传 `page` 和 `size` 参数，`rows.value` 改为 `rows.value = data.content`，新增 `total` ref 存 `data.totalElements`
2. 表格操作列新增"编辑"按钮（`type="primary"`），点击打开编辑对话框
3. 新增编辑对话框（复用状态/备注字段），提交调用 `updateAttendance(editRow.id, payload)`
4. 表格下方新增 `<el-pagination>` 组件，绑定 `currentPage`、`pageSize`、`total`，`@current-change` 触发 `search()`
5. 表格无数据时显示 `<el-empty description="暂无考勤记录" />`

**修改 `Code/admin-panel/src/api/modules.js`：**
- 新增 `updateAttendance(id, payload)` 函数
- `searchAttendances(params)` 改名为 `listAttendances(params)`，params 增加 page/size

**验证：** 浏览器打开考勤管理页，确认分页正常、编辑对话框可保存

---

## Step 3: 后端 — 体测编辑 + 删除接口 + 分页

**新增文件：**
`Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/fitness/FitnessTestUpdateRequest.java`

```java
package com.shuzi.managementplatform.web.dto.fitness;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;

public record FitnessTestUpdateRequest(
        @NotNull LocalDate testDate,
        @NotBlank @Size(max = 100) String itemName,
        @NotNull @DecimalMin(value = "0.00", inclusive = false) BigDecimal testValue,
        @NotBlank @Size(max = 32) String unit,
        @Size(max = 255) String comment
) {}
```

**修改 `FitnessTestService.java`：**
- 新增 `update(Long id, FitnessTestUpdateRequest request)` 方法
- 新增 `delete(Long id)` 方法（`FitnessTestRecord` 已有 `@TableLogic`，直接 `deleteById` 即可触发逻辑删除）
- `listByStudent()` 改为支持分页，返回 `IPage<FitnessTestResponse>`

**修改 `FitnessTestController.java`：**
- 新增 `PUT /{id}` 接口
- 新增 `DELETE /{id}` 接口
- `GET /` 接口增加 `page`（默认0）和 `size`（默认20）参数

**验证：** 测试 PUT / DELETE / GET 分页接口

---

## Step 4: 前端 — FitnessView.vue 增加编辑 + 删除 + 分页

**修改 `Code/admin-panel/src/views/fitness/FitnessView.vue`：**

1. `search()` 改为传 page/size，`rows.value = data.content`，新增 `total` ref
2. 表格操作列新增"编辑"和"删除"按钮
3. 新增编辑对话框（所有字段可编辑）
4. 项目输入改为 `<el-select>` + 自定义输入组合：
   - 下拉选项为预设项目列表（`FITNESS_ITEMS` 常量）
   - 选择后自动填充 `unit` 字段
   - 支持手动输入自定义项目
5. 删除按钮触发 `ElMessageBox.confirm` 确认后调用 `deleteFitnessTest(id)`
6. 表格下方新增 `<el-pagination>`
7. 无数据时显示 `<el-empty>`

**修改 `Code/admin-panel/src/api/modules.js`：**
- 新增 `updateFitnessTest(id, payload)`
- 新增 `deleteFitnessTest(id)`
- `listFitnessTests(params)` 增加 page/size 参数

**验证：** 浏览器测试编辑、删除、分页功能

---

## Step 5: 后端 — 课程删除接口

**修改 `CourseService.java`：**
新增 `delete(Long id, boolean force)` 方法：
```java
// 检查关联考勤记录数
long attendanceCount = attendanceRecordMapper.selectCount(
    Wrappers.<AttendanceRecord>lambdaQuery().eq(AttendanceRecord::getCourseId, id)
);
// 检查关联训练记录数
long trainingCount = trainingRecordMapper.selectCount(
    Wrappers.<TrainingRecord>lambdaQuery().eq(TrainingRecord::getCourseId, id)
);
if (!force && (attendanceCount > 0 || trainingCount > 0)) {
    throw new BusinessException(HttpStatus.CONFLICT,
        "课程存在关联数据（考勤:" + attendanceCount + "，训练:" + trainingCount + "），请先删除关联数据或使用强制删除");
}
if (force) {
    attendanceRecordMapper.delete(...);
    trainingRecordMapper.delete(...);
}
courseMapper.deleteById(id);
```

注意：`CourseService` 需注入 `AttendanceRecordMapper` 和 `TrainingRecordMapper`。

**修改 `CourseController.java`：**
新增：
```java
@PreAuthorize("hasRole('ADMIN')")
@DeleteMapping("/{id}")
public ApiResponse<Void> delete(
    @PathVariable Long id,
    @RequestParam(defaultValue = "false") boolean force
) {
    courseService.delete(id, force);
    return ApiResponse.ok("course deleted", null);
}
```

**验证：** 测试删除有关联数据的课程（应返回 409），测试 `?force=true` 强制删除

---

## Step 6: 前端 — CourseListView.vue 增加删除

**修改 `Code/admin-panel/src/views/courses/CourseListView.vue`：**

1. 操作列新增"删除"按钮（`type="danger"`，仅 ADMIN 可见）
2. 点击删除先调用 `deleteCourse(id)` 不带 force：
   - 成功：提示"课程已删除"，刷新列表
   - 失败且错误信息包含"关联数据"：弹出二次确认框，说明影响范围，确认后调用 `deleteCourse(id, true)`
3. 正常删除前显示 `ElMessageBox.confirm`

**修改 `Code/admin-panel/src/api/modules.js`：**
新增 `deleteCourse(id, force = false)`

**验证：** 测试删除无关联课程、有关联课程（强制删除）

---

## Step 7: 后端 — 训练记录删除 + 分页

**修改 `TrainingRecordService.java`：**
新增 `delete(Long id)` 方法（selectById 检查存在后 deleteById）。
将 `search()` 改为支持分页，返回 `IPage<TrainingRecordResponse>`。

**修改 `TrainingRecordController.java`：**
- 新增 `DELETE /{id}` 接口
- `GET /` 增加 page/size 参数

**验证：** 测试删除和分页接口

---

## Step 8: 前端 — TrainingRecordView.vue 增加删除 + 分页

**修改 `Code/admin-panel/src/views/training/TrainingRecordView.vue`：**

1. `search()` 改为传 page/size，`rows.value = data.content`，新增 `total` ref
2. 操作列新增"删除"按钮，确认后调用 `deleteTrainingRecord(id)`
3. 表格下方新增 `<el-pagination>`
4. 无数据时显示 `<el-empty>`

**修改 `Code/admin-panel/src/api/modules.js`：**
- 新增 `deleteTrainingRecord(id)`
- `listTrainingRecords(params)` 增加 page/size 参数

**验证：** 浏览器测试删除和分页

---

## 完成标准

- [ ] 考勤记录可编辑（状态、备注），列表有分页
- [ ] 体测记录可编辑（所有字段）、可删除，列表有分页，项目有预设下拉
- [ ] 课程可删除（有关联数据时提示并支持强制删除）
- [ ] 训练记录可删除，列表有分页
- [ ] 所有列表无数据时显示空状态提示
