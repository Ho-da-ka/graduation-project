# Training Closed-Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the approved closed-loop training workflow: student goals, themed courses, structured training feedback, stage evaluations, parent growth view, lightweight AI summaries, and attention alerts.

**Architecture:** Extend the current Spring Boot + MyBatis-Plus monolith instead of introducing a new service boundary. Persist the new closed-loop fields in the existing MySQL bootstrap schema, expose them through the current admin and parent controllers, then surface the workflow in the Vue admin panel and UniApp parent mini-program. AI remains optional through a fallback-safe adapter so the workflow stays usable when external generation is disabled or unavailable.

**Tech Stack:** Spring Boot 3.3, MyBatis-Plus, MySQL schema bootstrap, JUnit 5 + Mockito, Vue 3 + Element Plus + Vite, UniApp + TypeScript

---

## File Map

### Backend domain and API

- Modify: `Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/Student.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/Course.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/TrainingRecord.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/StageEvaluation.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/CareAlert.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/mapper/StageEvaluationMapper.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/mapper/CareAlertMapper.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StudentService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/CourseService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/TrainingRecordService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentPortalService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/FitnessTestService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/AttendanceService.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StageEvaluationService.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/CareAlertService.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/GeneratedContentService.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/config/AiGenerationProperties.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/AiTextClient.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/NoopAiTextClient.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/OpenAiCompatibleAiTextClient.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/ParentPortalController.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/TrainingRecordController.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/StageEvaluationController.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/CareAlertController.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentCreateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentUpdateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentProfileResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseCreateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseUpdateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordCreateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordUpdateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordResponse.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationCreateRequest.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationUpdateRequest.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationResponse.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parent/ParentGrowthOverviewResponse.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/alert/CareAlertResponse.java`

### Backend tests

- Create: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StudentServiceTest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/CourseServiceTest.java`
- Create: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/TrainingRecordServiceTest.java`
- Create: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StageEvaluationServiceTest.java`
- Create: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentPortalServiceTest.java`
- Create: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/GeneratedContentServiceTest.java`
- Create: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/CareAlertServiceTest.java`

### Admin panel

- Modify: `Code/admin-panel/src/layouts/AdminLayout.vue`
- Modify: `Code/admin-panel/src/router/index.js`
- Modify: `Code/admin-panel/src/api/modules/students.js`
- Modify: `Code/admin-panel/src/api/modules/courses.js`
- Modify: `Code/admin-panel/src/api/modules/training.js`
- Create: `Code/admin-panel/src/api/modules/evaluations.js`
- Modify: `Code/admin-panel/src/views/students/StudentProfileView.vue`
- Modify: `Code/admin-panel/src/views/courses/CourseListView.vue`
- Modify: `Code/admin-panel/src/views/training/TrainingRecordView.vue`
- Modify: `Code/admin-panel/src/views/DashboardView.vue`
- Create: `Code/admin-panel/src/views/evaluations/StageEvaluationView.vue`

### Parent mini-program

- Modify: `Code/mobile-app/src/pages.json`
- Modify: `Code/mobile-app/src/api/modules/parent.ts`
- Modify: `Code/mobile-app/src/types/parent.ts`
- Modify: `Code/mobile-app/src/pages/parent/home.vue`
- Modify: `Code/mobile-app/src/pages/parent/messages/list.vue`
- Create: `Code/mobile-app/src/pages/parent/growth/index.vue`

---

### Task 1: Extend Student Goals And Course Themes

**Files:**
- Modify: `Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/Student.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/Course.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentCreateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentUpdateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentProfileResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseCreateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseUpdateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StudentService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/CourseService.java`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StudentServiceTest.java`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/CourseServiceTest.java`

- [ ] **Step 1: Write the failing tests**

```java
@ExtendWith(MockitoExtension.class)
class StudentServiceTest {

    @Mock private StudentMapper studentMapper;
    @Mock private AttendanceRecordMapper attendanceRecordMapper;
    @Mock private FitnessTestRecordMapper fitnessTestRecordMapper;
    @Mock private TrainingRecordMapper trainingRecordMapper;
    @Mock private UserAccountService userAccountService;

    @InjectMocks
    private StudentService studentService;

    @Test
    void createShouldExposeGoalFieldsInResponse() {
        when(studentMapper.selectCount(any())).thenReturn(0L);
        when(studentMapper.insert(any(Student.class))).thenReturn(1);

        StudentResponse response = studentService.create(new StudentCreateRequest(
                "S1001",
                "李雷",
                Gender.MALE,
                LocalDate.of(2016, 5, 12),
                "李妈妈",
                "13800138000",
                StudentStatus.ACTIVE,
                "基础班",
                "协调性提升",
                "核心稳定,柔韧性",
                "膝关节敏感",
                LocalDate.of(2026, 4, 14),
                LocalDate.of(2026, 5, 12)
        ));

        assertEquals("协调性提升", response.goalFocus());
        assertEquals("核心稳定,柔韧性", response.trainingTags());
        assertEquals(LocalDate.of(2026, 5, 12), response.goalEndDate());
    }
}
```

```java
@Test
void createShouldExposeTrainingThemeFields() {
    CourseCreateRequest request = new CourseCreateRequest(
            "C1001",
            "基础敏捷课",
            "GROUP",
            "王教练",
            "一号馆",
            LocalDateTime.of(2026, 4, 20, 18, 0),
            60,
            12,
            LocalDate.of(2026, 4, 20),
            LocalTime.of(18, 0),
            LocalTime.of(19, 0),
            CourseStatus.PLANNED,
            "基础协调课程",
            "协调敏捷",
            "7-9岁",
            "协调性提升,核心稳定",
            "梯子步频,落地稳定"
    );

    Coach coach = new Coach();
    coach.setCoachCode("T001");
    coach.setName("王教练");
    coach.setStatus(CoachStatus.ACTIVE);

    when(courseMapper.selectCount(any())).thenReturn(0L);
    when(coachMapper.selectOne(any())).thenReturn(coach);
    when(courseMapper.insert(any(Course.class))).thenReturn(1);

    CourseResponse response = courseService.create(request, false);

    assertEquals("协调敏捷", response.trainingTheme());
    assertEquals("7-9岁", response.targetAgeRange());
    assertEquals("梯子步频,落地稳定", response.focusPoints());
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `.\mvnw.cmd -Dtest=StudentServiceTest,CourseServiceTest test`

Expected: FAIL with constructor/accessor compilation errors such as `cannot find symbol method goalFocus()` and `constructor CourseCreateRequest cannot be applied to given types`.

- [ ] **Step 3: Write minimal implementation**

```sql
ALTER TABLE students ADD COLUMN goal_focus VARCHAR(255) NULL;
ALTER TABLE students ADD COLUMN training_tags VARCHAR(255) NULL;
ALTER TABLE students ADD COLUMN risk_notes VARCHAR(255) NULL;
ALTER TABLE students ADD COLUMN goal_start_date DATE NULL;
ALTER TABLE students ADD COLUMN goal_end_date DATE NULL;

ALTER TABLE courses ADD COLUMN training_theme VARCHAR(100) NULL;
ALTER TABLE courses ADD COLUMN target_age_range VARCHAR(32) NULL;
ALTER TABLE courses ADD COLUMN target_goals VARCHAR(255) NULL;
ALTER TABLE courses ADD COLUMN focus_points VARCHAR(255) NULL;
```

```java
@TableField("goal_focus")
private String goalFocus;

@TableField("training_tags")
private String trainingTags;

@TableField("risk_notes")
private String riskNotes;

@TableField("goal_start_date")
private LocalDate goalStartDate;

@TableField("goal_end_date")
private LocalDate goalEndDate;
```

```java
public record StudentCreateRequest(
        String studentNo,
        String name,
        Gender gender,
        LocalDate birthDate,
        String guardianName,
        String guardianPhone,
        StudentStatus status,
        String remarks,
        @Size(max = 255, message = "goalFocus max length is 255") String goalFocus,
        @Size(max = 255, message = "trainingTags max length is 255") String trainingTags,
        @Size(max = 255, message = "riskNotes max length is 255") String riskNotes,
        LocalDate goalStartDate,
        LocalDate goalEndDate
) {}
```

```java
public record StudentResponse(
        Long id,
        String studentNo,
        String name,
        Gender gender,
        LocalDate birthDate,
        String guardianName,
        String guardianPhone,
        StudentStatus status,
        String remarks,
        String goalFocus,
        String trainingTags,
        String riskNotes,
        LocalDate goalStartDate,
        LocalDate goalEndDate,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {}
```

```java
student.setGoalFocus(request.goalFocus());
student.setTrainingTags(request.trainingTags());
student.setRiskNotes(request.riskNotes());
student.setGoalStartDate(request.goalStartDate());
student.setGoalEndDate(request.goalEndDate());
```

```java
public record CourseCreateRequest(
        String courseCode,
        String name,
        String courseType,
        String coachName,
        String venue,
        LocalDateTime startTime,
        Integer durationMinutes,
        Integer maxCapacity,
        LocalDate courseDate,
        LocalTime classStartTime,
        LocalTime classEndTime,
        CourseStatus status,
        String description,
        @Size(max = 100, message = "trainingTheme max length is 100") String trainingTheme,
        @Size(max = 32, message = "targetAgeRange max length is 32") String targetAgeRange,
        @Size(max = 255, message = "targetGoals max length is 255") String targetGoals,
        @Size(max = 255, message = "focusPoints max length is 255") String focusPoints
) {}
```

```java
course.setTrainingTheme(request.trainingTheme());
course.setTargetAgeRange(request.targetAgeRange());
course.setTargetGoals(request.targetGoals());
course.setFocusPoints(request.focusPoints());
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `.\mvnw.cmd -Dtest=StudentServiceTest,CourseServiceTest test`

Expected: PASS with both tests green and no schema-related compilation errors.

- [ ] **Step 5: Commit**

```bash
git add Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/Student.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/Course.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentCreateRequest.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentUpdateRequest.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentResponse.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/student/StudentProfileResponse.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseCreateRequest.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseUpdateRequest.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/course/CourseResponse.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StudentService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/CourseService.java ^
  Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StudentServiceTest.java ^
  Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/CourseServiceTest.java
git commit -m "feat: add student goals and course themes"
```

### Task 2: Enrich Training Records Into Structured Feedback Sheets

**Files:**
- Modify: `Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/TrainingRecord.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordCreateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordUpdateRequest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/TrainingRecordService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/TrainingRecordController.java`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/TrainingRecordServiceTest.java`

- [ ] **Step 1: Write the failing test**

```java
@ExtendWith(MockitoExtension.class)
class TrainingRecordServiceTest {

    @Mock private TrainingRecordMapper trainingRecordMapper;
    @Mock private StudentService studentService;
    @Mock private CourseService courseService;

    @InjectMocks
    private TrainingRecordService trainingRecordService;

    @Test
    void createShouldPersistStructuredFeedbackFields() {
        Student student = new Student();
        student.setStudentNo("S001");
        student.setName("测试学员");
        Course course = new Course();
        course.setCourseCode("C001");
        course.setName("敏捷训练");

        when(studentService.getEntityById(1L)).thenReturn(student);
        when(courseService.getEntityById(2L)).thenReturn(course);
        when(trainingRecordMapper.insert(any(TrainingRecord.class))).thenReturn(1);

        TrainingRecordResponse response = trainingRecordService.create(new TrainingRecordCreateRequest(
                1L,
                2L,
                LocalDate.of(2026, 4, 15),
                "敏捷梯+跳绳",
                60,
                "MEDIUM",
                "完成度高",
                "步频稳定",
                "后程体能下降",
                "晚间做两组拉伸",
                "下节课强化髋稳定",
                "课堂专注，落地控制比上周更稳定",
                "保持热身节奏"
        ));

        assertEquals("步频稳定", response.highlightNote());
        assertEquals("后程体能下降", response.improvementNote());
        assertEquals("晚间做两组拉伸", response.parentAction());
        assertNull(response.parentReadAt());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\mvnw.cmd -Dtest=TrainingRecordServiceTest test`

Expected: FAIL with constructor/accessor compilation errors for `highlightNote`, `improvementNote`, `parentAction`, `nextStepSuggestion`, `aiSummary`, or `parentReadAt`.

- [ ] **Step 3: Write minimal implementation**

```sql
ALTER TABLE training_records ADD COLUMN highlight_note VARCHAR(255) NULL;
ALTER TABLE training_records ADD COLUMN improvement_note VARCHAR(255) NULL;
ALTER TABLE training_records ADD COLUMN parent_action VARCHAR(255) NULL;
ALTER TABLE training_records ADD COLUMN next_step_suggestion VARCHAR(255) NULL;
ALTER TABLE training_records ADD COLUMN ai_summary VARCHAR(500) NULL;
ALTER TABLE training_records ADD COLUMN parent_read_at DATETIME NULL;
```

```java
@TableField("highlight_note")
private String highlightNote;

@TableField("improvement_note")
private String improvementNote;

@TableField("parent_action")
private String parentAction;

@TableField("next_step_suggestion")
private String nextStepSuggestion;

@TableField("ai_summary")
private String aiSummary;

@TableField("parent_read_at")
private LocalDateTime parentReadAt;
```

```java
public record TrainingRecordCreateRequest(
        Long studentId,
        Long courseId,
        LocalDate trainingDate,
        String trainingContent,
        Integer durationMinutes,
        String intensityLevel,
        String performanceSummary,
        @Size(max = 255, message = "highlightNote max length is 255") String highlightNote,
        @Size(max = 255, message = "improvementNote max length is 255") String improvementNote,
        @Size(max = 255, message = "parentAction max length is 255") String parentAction,
        @Size(max = 255, message = "nextStepSuggestion max length is 255") String nextStepSuggestion,
        @Size(max = 500, message = "coachComment max length is 500") String coachComment,
        @Size(max = 255, message = "summaryForParent max length is 255") String summaryForParent
) {}
```

```java
record.setHighlightNote(normalize(request.highlightNote()));
record.setImprovementNote(normalize(request.improvementNote()));
record.setParentAction(normalize(request.parentAction()));
record.setNextStepSuggestion(normalize(request.nextStepSuggestion()));
record.setCoachComment(normalize(request.coachComment()));
record.setAiSummary(normalize(request.summaryForParent()));
record.setParentReadAt(null);
```

```java
return new TrainingRecordResponse(
        record.getId(),
        student.getId(),
        student.getName(),
        course.getId(),
        course.getName(),
        record.getTrainingDate(),
        record.getTrainingContent(),
        record.getDurationMinutes(),
        record.getIntensityLevel(),
        record.getPerformanceSummary(),
        record.getHighlightNote(),
        record.getImprovementNote(),
        record.getParentAction(),
        record.getNextStepSuggestion(),
        record.getCoachComment(),
        record.getAiSummary(),
        record.getParentReadAt(),
        record.getCreatedAt(),
        record.getUpdatedAt()
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `.\mvnw.cmd -Dtest=TrainingRecordServiceTest test`

Expected: PASS with the new structured feedback fields mapped in create and response flow.

- [ ] **Step 5: Commit**

```bash
git add Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/TrainingRecord.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordCreateRequest.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordUpdateRequest.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/training/TrainingRecordResponse.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/TrainingRecordService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/TrainingRecordController.java ^
  Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/TrainingRecordServiceTest.java
git commit -m "feat: add structured training feedback fields"
```

### Task 3: Add Stage Evaluations And Parent Growth Overview APIs

**Files:**
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/StageEvaluation.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/mapper/StageEvaluationMapper.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StageEvaluationService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentPortalService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/ParentPortalController.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/StageEvaluationController.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationCreateRequest.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationUpdateRequest.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationResponse.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parent/ParentGrowthOverviewResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StageEvaluationServiceTest.java`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentPortalServiceTest.java`

- [ ] **Step 1: Write the failing tests**

```java
@ExtendWith(MockitoExtension.class)
class StageEvaluationServiceTest {

    @Mock private StageEvaluationMapper stageEvaluationMapper;
    @Mock private AttendanceRecordMapper attendanceRecordMapper;
    @Mock private TrainingRecordMapper trainingRecordMapper;
    @Mock private FitnessTestRecordMapper fitnessTestRecordMapper;
    @Mock private StudentService studentService;

    @InjectMocks
    private StageEvaluationService stageEvaluationService;

    @Test
    void createShouldCalculateAttendanceRateAndPersistNarrative() {
        Student student = new Student();
        student.setName("测试学员");
        when(studentService.getEntityById(1L)).thenReturn(student);
        when(attendanceRecordMapper.selectCount(any())).thenReturn(8L, 6L);
        when(trainingRecordMapper.selectCount(any())).thenReturn(5L);
        when(fitnessTestRecordMapper.selectList(any())).thenReturn(List.of());
        when(stageEvaluationMapper.insert(any(StageEvaluation.class))).thenReturn(1);

        StageEvaluationResponse response = stageEvaluationService.create(new StageEvaluationCreateRequest(
                1L,
                "2026春季一期",
                LocalDate.of(2026, 4, 1),
                LocalDate.of(2026, 4, 30),
                "5/6 节课完成",
                "50米跑提升 0.4 秒",
                "核心更稳定",
                "下阶段强化下肢爆发"
        ));

        assertEquals(0.75, response.attendanceRate());
        assertEquals("50米跑提升 0.4 秒", response.fitnessSummary());
        assertEquals("下阶段强化下肢爆发", response.nextStagePlan());
    }
}
```

```java
@Test
void getGrowthOverviewShouldAggregateGoalFeedbackAndEvaluation() {
    ParentGrowthOverviewResponse overview = parentPortalService.getGrowthOverview("parent", 1L);

    assertEquals("协调性提升", overview.goalFocus());
    assertEquals(1, overview.recentTrainingFeedback().size());
    assertNotNull(overview.latestEvaluation());
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `.\mvnw.cmd -Dtest=StageEvaluationServiceTest,ParentPortalServiceTest test`

Expected: FAIL because `StageEvaluationService`, `StageEvaluationResponse`, and `getGrowthOverview` do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```sql
CREATE TABLE IF NOT EXISTS stage_evaluations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    student_id BIGINT NOT NULL,
    cycle_name VARCHAR(100) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    attendance_rate DECIMAL(5,4) NOT NULL,
    training_summary VARCHAR(255) NOT NULL,
    fitness_summary VARCHAR(255) NOT NULL,
    coach_evaluation VARCHAR(500) NOT NULL,
    next_stage_plan VARCHAR(500) NOT NULL,
    ai_interpretation VARCHAR(1000) NULL,
    parent_report VARCHAR(1000) NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_stage_evaluations_student_period (student_id, period_start, period_end),
    CONSTRAINT fk_stage_evaluations_student FOREIGN KEY (student_id) REFERENCES students(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

```java
@TableName("stage_evaluations")
public class StageEvaluation extends BaseEntity {
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    @TableField("student_id")
    private Long studentId;
    @TableField("cycle_name")
    private String cycleName;
    @TableField("period_start")
    private LocalDate periodStart;
    @TableField("period_end")
    private LocalDate periodEnd;
    @TableField("attendance_rate")
    private BigDecimal attendanceRate;
    @TableField("training_summary")
    private String trainingSummary;
    @TableField("fitness_summary")
    private String fitnessSummary;
    @TableField("coach_evaluation")
    private String coachEvaluation;
    @TableField("next_stage_plan")
    private String nextStagePlan;
    @TableField("ai_interpretation")
    private String aiInterpretation;
    @TableField("parent_report")
    private String parentReport;
}
```

```java
public record StageEvaluationResponse(
        Long id,
        Long studentId,
        String studentName,
        String cycleName,
        LocalDate periodStart,
        LocalDate periodEnd,
        double attendanceRate,
        String trainingSummary,
        String fitnessSummary,
        String coachEvaluation,
        String nextStagePlan,
        String aiInterpretation,
        String parentReport,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {}
```

```java
public record ParentGrowthOverviewResponse(
        Long studentId,
        String studentName,
        String goalFocus,
        String trainingTags,
        String riskNotes,
        LocalDate goalStartDate,
        LocalDate goalEndDate,
        List<TrainingFeedbackItem> recentTrainingFeedback,
        GrowthEvaluation latestEvaluation
) {
    public record TrainingFeedbackItem(
            Long id,
            LocalDate trainingDate,
            String trainingContent,
            String highlightNote,
            String improvementNote,
            String parentAction,
            String nextStepSuggestion,
            String aiSummary,
            LocalDateTime parentReadAt
    ) {}

    public record GrowthEvaluation(
            String cycleName,
            double attendanceRate,
            String fitnessSummary,
            String coachEvaluation,
            String nextStagePlan,
            String parentReport
    ) {}
}
```

```java
public StageEvaluationResponse create(StageEvaluationCreateRequest request) {
    Student student = studentService.getEntityById(request.studentId());
    long totalAttendance = attendanceRecordMapper.selectCount(
            Wrappers.<AttendanceRecord>lambdaQuery()
                    .eq(AttendanceRecord::getStudentId, request.studentId())
                    .between(AttendanceRecord::getAttendanceDate, request.periodStart(), request.periodEnd())
    );
    long effectiveAttendance = attendanceRecordMapper.selectCount(
            Wrappers.<AttendanceRecord>lambdaQuery()
                    .eq(AttendanceRecord::getStudentId, request.studentId())
                    .between(AttendanceRecord::getAttendanceDate, request.periodStart(), request.periodEnd())
                    .in(AttendanceRecord::getStatus, AttendanceStatus.PRESENT, AttendanceStatus.LATE)
    );
    double attendanceRate = totalAttendance == 0 ? 0.0 : (double) effectiveAttendance / totalAttendance;

    StageEvaluation entity = new StageEvaluation();
    entity.setStudentId(request.studentId());
    entity.setCycleName(request.cycleName());
    entity.setPeriodStart(request.periodStart());
    entity.setPeriodEnd(request.periodEnd());
    entity.setAttendanceRate(BigDecimal.valueOf(attendanceRate).setScale(4, RoundingMode.HALF_UP));
    entity.setTrainingSummary(request.trainingSummary());
    entity.setFitnessSummary(request.fitnessSummary());
    entity.setCoachEvaluation(request.coachEvaluation());
    entity.setNextStagePlan(request.nextStagePlan());
    stageEvaluationMapper.insert(entity);
    return toResponse(entity, student);
}
```

```java
@GetMapping("/growth-overview")
@PreAuthorize("hasRole('PARENT')")
public ApiResponse<ParentGrowthOverviewResponse> getGrowthOverview(
        Authentication authentication,
        @RequestParam Long studentId
) {
    return ApiResponse.ok(parentPortalService.getGrowthOverview(currentUsername(authentication), studentId));
}
```

```java
public ParentGrowthOverviewResponse getGrowthOverview(String username, Long studentId) {
    ParentAccount parentAccount = resolveParentAccount(username);
    assertStudentBound(parentAccount.getId(), studentId);

    Student student = studentMapper.selectById(studentId);
    List<TrainingRecord> feedback = trainingRecordMapper.selectList(
            Wrappers.<TrainingRecord>lambdaQuery()
                    .eq(TrainingRecord::getStudentId, studentId)
                    .orderByDesc(TrainingRecord::getTrainingDate, TrainingRecord::getId)
                    .last("limit 5")
    );
    StageEvaluation latestEvaluation = stageEvaluationMapper.selectOne(
            Wrappers.<StageEvaluation>lambdaQuery()
                    .eq(StageEvaluation::getStudentId, studentId)
                    .orderByDesc(StageEvaluation::getPeriodEnd, StageEvaluation::getId)
                    .last("limit 1")
    );

    return new ParentGrowthOverviewResponse(
            student.getId(),
            student.getName(),
            student.getGoalFocus(),
            student.getTrainingTags(),
            student.getRiskNotes(),
            student.getGoalStartDate(),
            student.getGoalEndDate(),
            feedback.stream().map(this::toTrainingFeedbackItem).toList(),
            latestEvaluation == null ? null : toGrowthEvaluation(latestEvaluation)
    );
}
```

```java
private ParentGrowthOverviewResponse.TrainingFeedbackItem toTrainingFeedbackItem(TrainingRecord record) {
    return new ParentGrowthOverviewResponse.TrainingFeedbackItem(
            record.getId(),
            record.getTrainingDate(),
            record.getTrainingContent(),
            record.getHighlightNote(),
            record.getImprovementNote(),
            record.getParentAction(),
            record.getNextStepSuggestion(),
            record.getAiSummary(),
            record.getParentReadAt()
    );
}

private ParentGrowthOverviewResponse.GrowthEvaluation toGrowthEvaluation(StageEvaluation evaluation) {
    return new ParentGrowthOverviewResponse.GrowthEvaluation(
            evaluation.getCycleName(),
            evaluation.getAttendanceRate().doubleValue(),
            evaluation.getFitnessSummary(),
            evaluation.getCoachEvaluation(),
            evaluation.getNextStagePlan(),
            evaluation.getParentReport()
    );
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `.\mvnw.cmd -Dtest=StageEvaluationServiceTest,ParentPortalServiceTest test`

Expected: PASS with new evaluation persistence and parent growth aggregation wired.

- [ ] **Step 5: Commit**

```bash
git add Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/StageEvaluation.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/mapper/StageEvaluationMapper.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StageEvaluationService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentPortalService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/StageEvaluationController.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/ParentPortalController.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationCreateRequest.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationUpdateRequest.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/evaluation/StageEvaluationResponse.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parent/ParentGrowthOverviewResponse.java ^
  Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StageEvaluationServiceTest.java ^
  Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentPortalServiceTest.java
git commit -m "feat: add stage evaluations and growth overview api"
```

### Task 4: Upgrade The Admin Panel For Closed-Loop Operations

**Files:**
- Modify: `Code/admin-panel/src/layouts/AdminLayout.vue`
- Modify: `Code/admin-panel/src/router/index.js`
- Modify: `Code/admin-panel/src/api/modules/students.js`
- Modify: `Code/admin-panel/src/api/modules/courses.js`
- Modify: `Code/admin-panel/src/api/modules/training.js`
- Create: `Code/admin-panel/src/api/modules/evaluations.js`
- Modify: `Code/admin-panel/src/views/students/StudentProfileView.vue`
- Modify: `Code/admin-panel/src/views/courses/CourseListView.vue`
- Modify: `Code/admin-panel/src/views/training/TrainingRecordView.vue`
- Create: `Code/admin-panel/src/views/evaluations/StageEvaluationView.vue`

- [ ] **Step 1: Add the new API wrappers and route references first**

```js
// Code/admin-panel/src/api/modules/evaluations.js
import http from '../http'

function unwrap(response) {
  const body = response.data
  if (!body?.success) throw new Error(body?.message || '请求失败')
  return body.data
}

export async function listStageEvaluations(params) {
  return unwrap(await http.get('/stage-evaluations', { params }))
}

export async function createStageEvaluation(payload) {
  return unwrap(await http.post('/stage-evaluations', payload))
}

export async function updateStageEvaluation(id, payload) {
  return unwrap(await http.put(`/stage-evaluations/${id}`, payload))
}
```

```js
// Code/admin-panel/src/router/index.js
{
  path: 'stage-evaluations',
  name: 'stage-evaluations',
  component: () => import('../views/evaluations/StageEvaluationView.vue'),
  meta: { title: '阶段评估' }
}
```

- [ ] **Step 2: Run build to verify it fails on the missing UI pieces**

Run: `npm run build`

Expected: FAIL with import resolution errors such as `Could not resolve "../views/evaluations/StageEvaluationView.vue"` or missing methods referenced by the updated route/API modules.

- [ ] **Step 3: Implement the admin UI changes**

```vue
<!-- Code/admin-panel/src/views/courses/CourseListView.vue -->
<el-form-item label="训练主题">
  <el-input v-model="form.trainingTheme" maxlength="100" />
</el-form-item>
<el-form-item label="适用年龄段">
  <el-input v-model="form.targetAgeRange" maxlength="32" placeholder="例如 7-9岁" />
</el-form-item>
<el-form-item label="适用目标">
  <el-input v-model="form.targetGoals" type="textarea" maxlength="255" />
</el-form-item>
<el-form-item label="训练重点">
  <el-input v-model="form.focusPoints" type="textarea" maxlength="255" />
</el-form-item>
```

```vue
<!-- Code/admin-panel/src/views/training/TrainingRecordView.vue -->
<el-form-item label="课堂亮点">
  <el-input v-model="form.highlightNote" type="textarea" maxlength="255" show-word-limit />
</el-form-item>
<el-form-item label="待改进点">
  <el-input v-model="form.improvementNote" type="textarea" maxlength="255" show-word-limit />
</el-form-item>
<el-form-item label="家长配合建议">
  <el-input v-model="form.parentAction" type="textarea" maxlength="255" show-word-limit />
</el-form-item>
<el-form-item label="下次训练建议">
  <el-input v-model="form.nextStepSuggestion" type="textarea" maxlength="255" show-word-limit />
</el-form-item>
<el-form-item label="家长可读摘要">
  <el-input v-model="form.summaryForParent" type="textarea" maxlength="255" show-word-limit />
</el-form-item>
```

```vue
<!-- Code/admin-panel/src/views/students/StudentProfileView.vue -->
<el-card shadow="never" header="训练目标">
  <el-descriptions :column="2" border>
    <el-descriptions-item label="阶段目标">{{ profile.student?.goalFocus || '-' }}</el-descriptions-item>
    <el-descriptions-item label="训练标签">{{ profile.student?.trainingTags || '-' }}</el-descriptions-item>
    <el-descriptions-item label="注意事项">{{ profile.student?.riskNotes || '-' }}</el-descriptions-item>
    <el-descriptions-item label="目标周期">{{ goalPeriodText }}</el-descriptions-item>
  </el-descriptions>
</el-card>
```

```js
const goalPeriodText = computed(() => {
  const start = profile.value.student?.goalStartDate
  const end = profile.value.student?.goalEndDate
  if (!start && !end) return '-'
  return `${start || '未设置'} 至 ${end || '未设置'}`
})
```

```vue
<!-- Code/admin-panel/src/views/evaluations/StageEvaluationView.vue -->
<template>
  <div class="page-panel">
    <h2 class="page-title">阶段评估</h2>
    <div class="toolbar">
      <el-select v-model="filters.studentId" clearable filterable placeholder="选择学员" style="width: 180px" @change="search" />
      <el-input v-model="filters.cycleName" placeholder="周期名称" style="width: 180px" @keyup.enter="search" />
      <el-button type="primary" @click="search">查询</el-button>
      <el-button type="success" @click="openCreate">新增评估</el-button>
    </div>
    <el-table :data="rows" v-loading="loading" stripe>
      <el-table-column prop="studentName" label="学员" width="120" />
      <el-table-column prop="cycleName" label="周期" min-width="160" />
      <el-table-column prop="attendanceRate" label="出勤率" width="100" />
      <el-table-column prop="fitnessSummary" label="体测变化" min-width="200" show-overflow-tooltip />
      <el-table-column prop="nextStagePlan" label="下阶段建议" min-width="220" show-overflow-tooltip />
    </el-table>
  </div>
</template>
```

```vue
<!-- Code/admin-panel/src/layouts/AdminLayout.vue -->
<el-menu-item index="/stage-evaluations">阶段评估</el-menu-item>
```

- [ ] **Step 4: Run build to verify it passes**

Run: `npm run build`

Expected: PASS and `dist/` updated without unresolved route or module errors.

- [ ] **Step 5: Commit**

```bash
git add Code/admin-panel/src/layouts/AdminLayout.vue ^
  Code/admin-panel/src/router/index.js ^
  Code/admin-panel/src/api/modules/students.js ^
  Code/admin-panel/src/api/modules/courses.js ^
  Code/admin-panel/src/api/modules/training.js ^
  Code/admin-panel/src/api/modules/evaluations.js ^
  Code/admin-panel/src/views/students/StudentProfileView.vue ^
  Code/admin-panel/src/views/courses/CourseListView.vue ^
  Code/admin-panel/src/views/training/TrainingRecordView.vue ^
  Code/admin-panel/src/views/evaluations/StageEvaluationView.vue
git commit -m "feat: add closed-loop admin views"
```

### Task 5: Add The Parent Growth Page In The Mini Program

**Files:**
- Modify: `Code/mobile-app/src/pages.json`
- Modify: `Code/mobile-app/src/api/modules/parent.ts`
- Modify: `Code/mobile-app/src/types/parent.ts`
- Modify: `Code/mobile-app/src/pages/parent/home.vue`
- Modify: `Code/mobile-app/src/pages/parent/messages/list.vue`
- Create: `Code/mobile-app/src/pages/parent/growth/index.vue`

- [ ] **Step 1: Define the new TypeScript contracts and navigation hook**

```ts
// Code/mobile-app/src/types/parent.ts
export interface ParentTrainingFeedbackItem {
  id: number
  trainingDate: string
  trainingContent: string
  highlightNote: string
  improvementNote: string
  parentAction: string
  nextStepSuggestion: string
  aiSummary?: string
  parentReadAt?: string
}

export interface ParentGrowthOverview {
  studentId: number
  studentName: string
  goalFocus: string
  trainingTags: string
  riskNotes: string
  goalStartDate?: string
  goalEndDate?: string
  recentTrainingFeedback: ParentTrainingFeedbackItem[]
  latestEvaluation?: {
    cycleName: string
    attendanceRate: number
    fitnessSummary: string
    coachEvaluation: string
    nextStagePlan: string
    parentReport?: string
  }
}
```

```ts
// Code/mobile-app/src/api/modules/parent.ts
export function getParentGrowthOverview(studentId: number): Promise<ParentGrowthOverview> {
  return request<ParentGrowthOverview>({
    url: `/api/v1/parent/growth-overview?studentId=${studentId}`,
    method: 'GET'
  })
}
```

```vue
<!-- Code/mobile-app/src/pages/parent/home.vue -->
<u-button text="成长视图" @click="goGrowth" />
```

- [ ] **Step 2: Run type-check to verify it fails**

Run: `npm run type-check`

Expected: FAIL because `pages/parent/growth/index.vue` does not exist and the new type/API imports are not yet fully wired.

- [ ] **Step 3: Implement the page and route**

```json
{
  "path": "pages/parent/growth/index",
  "style": {
    "navigationBarTitleText": "成长视图"
  }
}
```

```vue
<!-- Code/mobile-app/src/pages/parent/growth/index.vue -->
<template>
  <view class="page">
    <view class="card">
      <view class="title">{{ overview.studentName || '成长视图' }}</view>
      <view class="sub-title">阶段目标：{{ overview.goalFocus || '未设置' }}</view>
      <view class="sub-title">训练标签：{{ overview.trainingTags || '未设置' }}</view>
      <view class="sub-title">注意事项：{{ overview.riskNotes || '无' }}</view>
    </view>

    <view class="card" v-if="overview.latestEvaluation">
      <view class="title" style="font-size: 30rpx">最新阶段评估</view>
      <view class="sub-title">周期：{{ overview.latestEvaluation.cycleName }}</view>
      <view class="sub-title">出勤率：{{ (overview.latestEvaluation.attendanceRate * 100).toFixed(1) }}%</view>
      <view class="sub-title">体测变化：{{ overview.latestEvaluation.fitnessSummary }}</view>
      <view class="sub-title">教练评价：{{ overview.latestEvaluation.coachEvaluation }}</view>
      <view class="sub-title">下阶段建议：{{ overview.latestEvaluation.nextStagePlan }}</view>
      <view class="content" v-if="overview.latestEvaluation.parentReport">{{ overview.latestEvaluation.parentReport }}</view>
    </view>

    <view v-for="item in overview.recentTrainingFeedback" :key="item.id" class="card">
      <view class="name">{{ item.trainingDate }} {{ item.trainingContent }}</view>
      <view class="sub-title">课堂亮点：{{ item.highlightNote || '无' }}</view>
      <view class="sub-title">待改进点：{{ item.improvementNote || '无' }}</view>
      <view class="sub-title">家长配合：{{ item.parentAction || '无' }}</view>
      <view class="content" v-if="item.aiSummary">{{ item.aiSummary }}</view>
    </view>
  </view>
</template>
```

```ts
const studentId = ref(0)
const overview = ref<ParentGrowthOverview>({
  studentId: 0,
  studentName: '',
  goalFocus: '',
  trainingTags: '',
  riskNotes: '',
  recentTrainingFeedback: []
})

async function fetchGrowth() {
  overview.value = await getParentGrowthOverview(studentId.value)
}

onLoad((options) => {
  studentId.value = Number(options?.studentId || 0)
  fetchGrowth()
})
```

- [ ] **Step 4: Run type-check and build**

Run: `npm run type-check`

Expected: PASS with the new parent growth types and page wired correctly.

Run: `npm run build:mp-weixin`

Expected: PASS and `dist/build/mp-weixin` refreshed.

- [ ] **Step 5: Commit**

```bash
git add Code/mobile-app/src/pages.json ^
  Code/mobile-app/src/api/modules/parent.ts ^
  Code/mobile-app/src/types/parent.ts ^
  Code/mobile-app/src/pages/parent/home.vue ^
  Code/mobile-app/src/pages/parent/messages/list.vue ^
  Code/mobile-app/src/pages/parent/growth/index.vue
git commit -m "feat: add parent growth view"
```

### Task 6: Add Optional AI Summary Generation With Safe Fallbacks

**Files:**
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/config/AiGenerationProperties.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/AiTextClient.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/NoopAiTextClient.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/OpenAiCompatibleAiTextClient.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/GeneratedContentService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/TrainingRecordService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StageEvaluationService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/resources/application.properties`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/GeneratedContentServiceTest.java`

- [ ] **Step 1: Write the failing test**

```java
@ExtendWith(MockitoExtension.class)
class GeneratedContentServiceTest {

    @Mock private AiTextClient aiTextClient;

    @Test
    void summarizeTrainingShouldFallBackToTemplateWhenClientFails() {
        AiGenerationProperties properties = new AiGenerationProperties();
        properties.setEnabled(true);
        properties.setModel("gpt-4o-mini");

        GeneratedContentService service = new GeneratedContentService(aiTextClient, properties);

        when(aiTextClient.complete(anyString(), anyString())).thenThrow(new IllegalStateException("down"));

        String summary = service.generateTrainingSummary(
                "敏捷梯+跳绳",
                "步频稳定",
                "后程体能下降",
                "晚间做两组拉伸",
                "下节课强化髋稳定"
        );

        assertTrue(summary.contains("课堂亮点"));
        assertTrue(summary.contains("家长可配合"));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\mvnw.cmd -Dtest=GeneratedContentServiceTest test`

Expected: FAIL because `GeneratedContentService`, `AiTextClient`, and `AiGenerationProperties` do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```java
@ConfigurationProperties(prefix = "app.ai")
public class AiGenerationProperties {
    private boolean enabled;
    private String baseUrl;
    private String apiKey;
    private String model;
    private Duration timeout = Duration.ofSeconds(20);
}
```

```java
public interface AiTextClient {
    String complete(String systemPrompt, String userPrompt);
}
```

```java
@Primary
@Component
class NoopAiTextClient implements AiTextClient {
    @Override
    public String complete(String systemPrompt, String userPrompt) {
        throw new IllegalStateException("AI client disabled");
    }
}
```

```java
@Component
@ConditionalOnProperty(prefix = "app.ai", name = "enabled", havingValue = "true")
class OpenAiCompatibleAiTextClient implements AiTextClient {

    private final RestClient restClient;
    private final AiGenerationProperties properties;

    OpenAiCompatibleAiTextClient(AiGenerationProperties properties) {
        this.properties = properties;
        this.restClient = RestClient.builder()
                .baseUrl(properties.getBaseUrl())
                .build();
    }

    @Override
    public String complete(String systemPrompt, String userPrompt) {
        ChatCompletionResponse response = restClient.post()
                .uri("/chat/completions")
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + properties.getApiKey())
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of(
                        "model", properties.getModel(),
                        "messages", List.of(
                                Map.of("role", "system", "content", systemPrompt),
                                Map.of("role", "user", "content", userPrompt)
                        ),
                        "temperature", 0.3
                ))
                .retrieve()
                .body(ChatCompletionResponse.class);
        return response.choices().get(0).message().content();
    }

    record ChatCompletionResponse(List<Choice> choices) {
        record Choice(Message message) {}
        record Message(String content) {}
    }
}
```

```java
public String generateTrainingSummary(
        String trainingContent,
        String highlightNote,
        String improvementNote,
        String parentAction,
        String nextStepSuggestion
) {
    String systemPrompt = "你是一名青少年体能训练反馈助手，只输出对家长友好的中文总结。";
    String userPrompt = """
            训练内容：%s
            课堂亮点：%s
            待改进点：%s
            家长配合：%s
            下次建议：%s
            """.formatted(trainingContent, highlightNote, improvementNote, parentAction, nextStepSuggestion);
    try {
        return aiTextClient.complete(systemPrompt, userPrompt);
    } catch (Exception ex) {
        return "课堂亮点：" + defaultText(highlightNote) + "；待改进点：" + defaultText(improvementNote)
                + "；家长可配合：" + defaultText(parentAction) + "；下次建议：" + defaultText(nextStepSuggestion);
    }
}
```

```java
private String defaultText(String value) {
    return StringUtils.hasText(value) ? value : "无";
}
```

```java
record.setAiSummary(generatedContentService.generateTrainingSummary(
        record.getTrainingContent(),
        record.getHighlightNote(),
        record.getImprovementNote(),
        record.getParentAction(),
        record.getNextStepSuggestion()
));

entity.setAiInterpretation(generatedContentService.generateStageInterpretation(
        entity.getTrainingSummary(),
        entity.getFitnessSummary(),
        entity.getCoachEvaluation(),
        entity.getNextStagePlan()
));
entity.setParentReport(generatedContentService.generateParentReport(
        student.getName(),
        entity.getCycleName(),
        entity.getAttendanceRate().doubleValue(),
        entity.getFitnessSummary(),
        entity.getCoachEvaluation(),
        entity.getNextStagePlan()
));
```

```properties
app.ai.enabled=false
app.ai.base-url=http://localhost:11434/v1
app.ai.api-key=replace-me
app.ai.model=gpt-4o-mini
app.ai.timeout=20s
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `.\mvnw.cmd -Dtest=GeneratedContentServiceTest,TrainingRecordServiceTest,StageEvaluationServiceTest test`

Expected: PASS with deterministic fallback summaries when the AI client is unavailable.

- [ ] **Step 5: Commit**

```bash
git add Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/config/AiGenerationProperties.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/AiTextClient.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/NoopAiTextClient.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/integration/ai/OpenAiCompatibleAiTextClient.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/GeneratedContentService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/TrainingRecordService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StageEvaluationService.java ^
  Code/backend-service/ManagementPlatform/src/main/resources/application.properties ^
  Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/GeneratedContentServiceTest.java
git commit -m "feat: add ai-generated summaries"
```

### Task 7: Add Attention Alerts And Surface Them In Admin Views

**Files:**
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/CareAlert.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/mapper/CareAlertMapper.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/CareAlertService.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/CareAlertController.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/alert/CareAlertResponse.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/AttendanceService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/FitnessTestService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StageEvaluationService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql`
- Modify: `Code/admin-panel/src/api/modules/students.js`
- Modify: `Code/admin-panel/src/views/students/StudentProfileView.vue`
- Modify: `Code/admin-panel/src/views/DashboardView.vue`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/CareAlertServiceTest.java`

- [ ] **Step 1: Write the failing test**

```java
@ExtendWith(MockitoExtension.class)
class CareAlertServiceTest {

    @Mock private CareAlertMapper careAlertMapper;
    @Mock private AttendanceRecordMapper attendanceRecordMapper;
    @Mock private FitnessTestRecordMapper fitnessTestRecordMapper;
    @Mock private StageEvaluationMapper stageEvaluationMapper;

    @InjectMocks
    private CareAlertService careAlertService;

    @Test
    void refreshStudentAlertsShouldCreateAbsenceStreakAlert() {
        AttendanceRecord a1 = new AttendanceRecord();
        a1.setAttendanceDate(LocalDate.of(2026, 4, 10));
        a1.setStatus(AttendanceStatus.ABSENT);
        AttendanceRecord a2 = new AttendanceRecord();
        a2.setAttendanceDate(LocalDate.of(2026, 4, 8));
        a2.setStatus(AttendanceStatus.ABSENT);

        when(attendanceRecordMapper.selectList(any())).thenReturn(List.of(a1, a2));
        when(fitnessTestRecordMapper.selectList(any())).thenReturn(List.of());
        when(stageEvaluationMapper.selectCount(any())).thenReturn(0L);

        careAlertService.refreshStudentAlerts(1L, LocalDate.of(2026, 4, 20), LocalDate.of(2026, 4, 15));

        verify(careAlertMapper).insert(argThat(alert ->
                "ABSENCE_STREAK".equals(alert.getAlertType())
                        && alert.getAlertTitle().contains("连续缺勤")));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\mvnw.cmd -Dtest=CareAlertServiceTest test`

Expected: FAIL because alert entity, mapper, and service do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```sql
CREATE TABLE IF NOT EXISTS care_alerts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    student_id BIGINT NOT NULL,
    alert_type VARCHAR(32) NOT NULL,
    alert_title VARCHAR(100) NOT NULL,
    alert_content VARCHAR(500) NOT NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'OPEN',
    triggered_at DATETIME NOT NULL,
    resolved_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_care_alerts_student_status (student_id, status),
    CONSTRAINT fk_care_alerts_student FOREIGN KEY (student_id) REFERENCES students(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

```java
public void refreshStudentAlerts(Long studentId, LocalDate today, LocalDate goalEndDate) {
    if (hasAbsenceStreak(studentId)) {
        openAlert(studentId, "ABSENCE_STREAK", "连续缺勤提醒", "最近两次签到连续缺勤，请尽快跟进家长。", today.atStartOfDay());
    }
    if (hasFitnessRegression(studentId)) {
        openAlert(studentId, "FITNESS_REGRESSION", "体测回落提醒", "最近一次关键体测较上次回落，请复核训练负荷。", today.atStartOfDay());
    }
    if (goalEndDate != null && goalEndDate.isBefore(today) && !hasRecentEvaluation(studentId, goalEndDate)) {
        openAlert(studentId, "EVALUATION_OVERDUE", "阶段评估逾期", "学员目标周期已结束但尚未完成阶段评估。", today.atStartOfDay());
    }
}
```

```java
@GetMapping("/students/{studentId}/care-alerts")
@PreAuthorize("hasAnyRole('ADMIN','COACH')")
public ApiResponse<List<CareAlertResponse>> listStudentAlerts(@PathVariable Long studentId) {
    return ApiResponse.ok(careAlertService.listStudentAlerts(studentId));
}
```

```js
// Code/admin-panel/src/api/modules/students.js
export async function getStudentCareAlerts(id) {
  return unwrap(await http.get(`/students/${id}/care-alerts`))
}
```

```vue
<!-- Code/admin-panel/src/views/students/StudentProfileView.vue -->
<el-tab-pane label="异常提醒" name="alerts">
  <el-timeline>
    <el-timeline-item
      v-for="alert in careAlerts"
      :key="alert.id"
      :timestamp="alert.triggeredAt"
      :type="alert.status === 'OPEN' ? 'danger' : 'success'"
    >
      <div class="alert-title">{{ alert.alertTitle }}</div>
      <div class="alert-content">{{ alert.alertContent }}</div>
    </el-timeline-item>
  </el-timeline>
</el-tab-pane>
```

```js
const careAlerts = ref([])

async function loadCareAlerts() {
  careAlerts.value = await getStudentCareAlerts(id)
}

onMounted(async () => {
  await loadCareAlerts()
})
```

- [ ] **Step 4: Run tests and admin build**

Run: `.\mvnw.cmd -Dtest=CareAlertServiceTest test`

Expected: PASS with alert rules persisted.

Run: `npm run build`

Expected: PASS and the student profile alert tab compiles cleanly.

- [ ] **Step 5: Commit**

```bash
git add Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/CareAlert.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/mapper/CareAlertMapper.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/CareAlertService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/CareAlertController.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/alert/CareAlertResponse.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/AttendanceService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/FitnessTestService.java ^
  Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StageEvaluationService.java ^
  Code/admin-panel/src/api/modules/students.js ^
  Code/admin-panel/src/views/students/StudentProfileView.vue ^
  Code/admin-panel/src/views/DashboardView.vue ^
  Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/CareAlertServiceTest.java
git commit -m "feat: add care alert workflow"
```

## Final Verification Matrix

- [ ] Backend targeted tests

Run: `.\mvnw.cmd -Dtest=StudentServiceTest,CourseServiceTest,TrainingRecordServiceTest,StageEvaluationServiceTest,ParentPortalServiceTest,GeneratedContentServiceTest,CareAlertServiceTest test`

Expected: PASS with all new closed-loop service tests green.

- [ ] Backend full regression

Run: `.\mvnw.cmd test`

Expected: PASS with no existing statistics, attendance, course, or fitness tests regressing.

- [ ] Admin build

Run: `npm run build`

Expected: PASS and the `dist/` bundle contains updated student profile, course, training, evaluation, and dashboard views.

- [ ] Mobile type-check and build

Run: `npm run type-check`

Expected: PASS with no TypeScript errors in the parent growth page or updated API contracts.

Run: `npm run build:mp-weixin`

Expected: PASS and the mini-program output updates successfully.

- [ ] Manual smoke checklist

1. Create or edit a student with goal fields and confirm they appear in admin student profile.
2. Create or edit a course with training theme fields and confirm they appear in course list and form detail.
3. Save a training record with structured feedback and confirm parent-readable summary is present.
4. Create a stage evaluation and confirm it appears in admin evaluation list and parent growth view.
5. Open the parent growth page and confirm goals, recent feedback, and latest evaluation all render.
6. Simulate two consecutive absences or an overdue evaluation and confirm an alert appears in the admin student profile.
