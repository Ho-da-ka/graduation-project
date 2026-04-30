# Parent Account And Binding Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement phone-based parent accounts, explicit automatic/manual student bindings, admin parent management, and synchronized mini-program parent login behavior.

**Architecture:** Add a backend parent-sync service that owns phone normalization, parent account creation, and `AUTO` / `MANUAL` / `AUTO_MANUAL` reconciliation; wire that service into student lifecycle updates; expose a separate admin parent-management API for listing, detail, and manual binding operations; then add an admin-panel parent management page and update the mini-program login copy to match the new phone-first parent identity.

**Tech Stack:** Spring Boot 3, MyBatis-Plus, Java 17, Vue 3, Element Plus, Vite, uni-app, Vitest

---

## File Structure

- `Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql`
  Adds the parent phone uniqueness rule and the `binding_type` column for relation semantics.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/enums/ParentBindingType.java`
  Defines the `AUTO`, `MANUAL`, and `AUTO_MANUAL` states plus merge/downgrade helpers.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/ParentStudentRelation.java`
  Persists the new binding type on each parent-student relation.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/UserAccountService.java`
  Adds phone-based parent account creation and parent initial-password reset behavior.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentAccountSyncService.java`
  Owns guardian-phone normalization, parent-account upsert, automatic binding creation, and old-phone cleanup.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StudentService.java`
  Calls the parent sync service after create, update, and import flows.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentPortalService.java`
  Stops login-time implicit student binding so the portal uses explicit sync results only.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminListItemResponse.java`
  Represents one parent row in the admin list.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminDetailResponse.java`
  Represents the parent detail payload with bound-student rows.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminBoundStudentResponse.java`
  Represents one bound student row including `bindingType`.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentManualBindingCreateRequest.java`
  Validates the admin manual-bind request.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentAdminService.java`
  Implements the parent admin list/detail/manual bind/manual unbind use cases.
- `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/ParentAdminController.java`
  Exposes the new admin-only parent-management REST endpoints.
- `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentAccountSyncServiceTest.java`
  Covers automatic parent creation and binding-type transitions.
- `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StudentServiceTest.java`
  Verifies student lifecycle flows call the sync service with the correct previous phone.
- `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentPortalServiceTest.java`
  Verifies the parent portal no longer inserts fallback bindings at login time.
- `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentAdminServiceTest.java`
  Covers manual bind/unbind semantics and list/detail mapping.
- `Code/admin-panel/package.json`
  Adds a lightweight `vitest` script for parent-row action rules.
- `Code/admin-panel/package-lock.json`
  Locks the new frontend test dependency.
- `Code/admin-panel/vitest.config.js`
  Adds a minimal Vitest config for admin-panel helper tests.
- `Code/admin-panel/src/api/modules/parents.js`
  Wraps the new parent-admin backend endpoints.
- `Code/admin-panel/src/views/parents/parent-binding-actions.js`
  Centralizes row-action semantics for `AUTO`, `MANUAL`, and `AUTO_MANUAL`.
- `Code/admin-panel/src/views/parents/parent-binding-actions.test.js`
  Covers the unbind button behavior text and disable rules.
- `Code/admin-panel/src/views/parents/ParentListView.vue`
  Implements the parent list, detail, manual bind/unbind, and password actions.
- `Code/admin-panel/src/router/index.js`
  Registers the `/parents` route.
- `Code/admin-panel/src/layouts/AdminLayout.vue`
  Adds the “家长管理” menu item.
- `Code/admin-panel/src/views/LoginView.vue`
  Updates the login tip so admin users know parents now log in via mini-program phone credentials.
- `Code/mobile-app/src/pages/login/index.vue`
  Updates the parent login hints to “手机号 + 密码” and “初始密码为手机号后 6 位”.

### Task 1: Add Backend Binding Types And Parent Sync Foundation

**Files:**
- Modify: `Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/enums/ParentBindingType.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/ParentStudentRelation.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/UserAccountService.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentAccountSyncService.java`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentAccountSyncServiceTest.java`

- [ ] **Step 1: Write the failing backend sync tests**

```java
// Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentAccountSyncServiceTest.java
package com.shuzi.managementplatform.domain.service;

import com.shuzi.managementplatform.domain.entity.ParentAccount;
import com.shuzi.managementplatform.domain.entity.ParentStudentRelation;
import com.shuzi.managementplatform.domain.entity.Student;
import com.shuzi.managementplatform.domain.entity.UserAccount;
import com.shuzi.managementplatform.domain.enums.ParentBindingType;
import com.shuzi.managementplatform.domain.mapper.ParentAccountMapper;
import com.shuzi.managementplatform.domain.mapper.ParentStudentRelationMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ParentAccountSyncServiceTest {

    @Mock
    private ParentAccountMapper parentAccountMapper;
    @Mock
    private ParentStudentRelationMapper parentStudentRelationMapper;
    @Mock
    private UserAccountService userAccountService;

    @InjectMocks
    private ParentAccountSyncService parentAccountSyncService;

    @Test
    void syncStudentGuardianBindingShouldCreateParentAccountAndAutoRelation() {
        Student student = new Student();
        ReflectionTestUtils.setField(student, "id", 7L);
        student.setGuardianName("Parent Li");
        student.setGuardianPhone("13800138000");

        UserAccount parentLogin = new UserAccount();
        ReflectionTestUtils.setField(parentLogin, "id", 19L);
        parentLogin.setUsername("13800138000");
        parentLogin.setRole("PARENT");

        when(parentAccountMapper.selectOne(any())).thenReturn(null);
        when(userAccountService.upsertParentAccount("13800138000", "Parent Li")).thenReturn(parentLogin);
        when(parentAccountMapper.insert(any(ParentAccount.class))).thenAnswer(invocation -> {
            ParentAccount account = invocation.getArgument(0);
            ReflectionTestUtils.setField(account, "id", 31L);
            return 1;
        });
        when(parentStudentRelationMapper.selectOne(any())).thenReturn(null);

        parentAccountSyncService.syncStudentGuardianBinding(student, null);

        verify(userAccountService).upsertParentAccount("13800138000", "Parent Li");
        verify(parentStudentRelationMapper).insert(argThat(relation ->
                relation.getParentAccountId().equals(31L)
                        && relation.getStudentId().equals(7L)
                        && relation.getBindingType() == ParentBindingType.AUTO
        ));
    }

    @Test
    void syncStudentGuardianBindingShouldDowngradeOldAutoManualRelationAndCreateNewAutoRelation() {
        Student student = new Student();
        ReflectionTestUtils.setField(student, "id", 8L);
        student.setGuardianName("Parent Wang");
        student.setGuardianPhone("13900139000");

        ParentAccount oldAccount = new ParentAccount();
        ReflectionTestUtils.setField(oldAccount, "id", 41L);
        oldAccount.setPhone("13700137000");

        ParentStudentRelation oldRelation = new ParentStudentRelation();
        ReflectionTestUtils.setField(oldRelation, "id", 51L);
        oldRelation.setParentAccountId(41L);
        oldRelation.setStudentId(8L);
        oldRelation.setBindingType(ParentBindingType.AUTO_MANUAL);

        UserAccount newParentLogin = new UserAccount();
        ReflectionTestUtils.setField(newParentLogin, "id", 61L);
        newParentLogin.setUsername("13900139000");
        newParentLogin.setRole("PARENT");

        when(parentAccountMapper.selectOne(any()))
                .thenReturn(oldAccount)
                .thenReturn(null);
        when(parentStudentRelationMapper.selectOne(any()))
                .thenReturn(oldRelation)
                .thenReturn(null);
        when(userAccountService.upsertParentAccount("13900139000", "Parent Wang")).thenReturn(newParentLogin);
        when(parentAccountMapper.insert(any(ParentAccount.class))).thenAnswer(invocation -> {
            ParentAccount account = invocation.getArgument(0);
            ReflectionTestUtils.setField(account, "id", 71L);
            return 1;
        });

        parentAccountSyncService.syncStudentGuardianBinding(student, "13700137000");

        verify(parentStudentRelationMapper).updateById(argThat(relation ->
                relation.getId().equals(51L) && relation.getBindingType() == ParentBindingType.MANUAL
        ));
        verify(parentStudentRelationMapper).insert(argThat(relation ->
                relation.getParentAccountId().equals(71L)
                        && relation.getStudentId().equals(8L)
                        && relation.getBindingType() == ParentBindingType.AUTO
        ));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd Code/backend-service/ManagementPlatform
.\mvnw.cmd -Dtest=ParentAccountSyncServiceTest test
```

Expected: FAIL with missing `ParentBindingType`, missing `ParentAccountSyncService`, and/or missing `getBindingType()` accessors on `ParentStudentRelation`.

- [ ] **Step 3: Write the minimal sync implementation**

```sql
-- Code/backend-service/ManagementPlatform/src/main/resources/schema-mysql.sql
CREATE TABLE IF NOT EXISTS parent_accounts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_account_id BIGINT NOT NULL,
    display_name VARCHAR(64) NULL,
    phone VARCHAR(32) NULL,
    status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_parent_accounts_user_account_id (user_account_id),
    UNIQUE KEY uk_parent_accounts_phone (phone),
    CONSTRAINT fk_parent_accounts_user_account FOREIGN KEY (user_account_id) REFERENCES user_accounts(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE parent_student_relations
    ADD COLUMN IF NOT EXISTS binding_type VARCHAR(16) NOT NULL DEFAULT 'AUTO';
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/enums/ParentBindingType.java
package com.shuzi.managementplatform.domain.enums;

public enum ParentBindingType {
    AUTO,
    MANUAL,
    AUTO_MANUAL;

    public ParentBindingType mergeAutomatic() {
        return this == MANUAL ? AUTO_MANUAL : this;
    }

    public ParentBindingType removeAutomatic() {
        return this == AUTO_MANUAL ? MANUAL : this;
    }

    public ParentBindingType mergeManual() {
        return this == AUTO ? AUTO_MANUAL : this;
    }

    public ParentBindingType removeManual() {
        return this == AUTO_MANUAL ? AUTO : null;
    }
}
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/entity/ParentStudentRelation.java
package com.shuzi.managementplatform.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.shuzi.managementplatform.common.model.BaseEntity;
import com.shuzi.managementplatform.domain.enums.ParentBindingType;

@TableName("parent_student_relations")
public class ParentStudentRelation extends BaseEntity {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    @TableField("parent_account_id")
    private Long parentAccountId;

    @TableField("student_id")
    private Long studentId;

    @TableField("binding_type")
    private ParentBindingType bindingType = ParentBindingType.AUTO;

    public Long getId() {
        return id;
    }

    public Long getParentAccountId() {
        return parentAccountId;
    }

    public void setParentAccountId(Long parentAccountId) {
        this.parentAccountId = parentAccountId;
    }

    public Long getStudentId() {
        return studentId;
    }

    public void setStudentId(Long studentId) {
        this.studentId = studentId;
    }

    public ParentBindingType getBindingType() {
        return bindingType;
    }

    public void setBindingType(ParentBindingType bindingType) {
        this.bindingType = bindingType;
    }
}
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/UserAccountService.java
@Transactional
public UserAccount upsertParentAccount(String phone, String displayName) {
    String normalizedPhone = normalizeUsername(phone);
    UserAccount account = userAccountMapper.selectOne(
            Wrappers.<UserAccount>lambdaQuery()
                    .eq(UserAccount::getUsername, normalizedPhone)
                    .eq(UserAccount::getRole, "PARENT")
    );
    if (account == null) {
        account = new UserAccount();
        account.setUsername(normalizedPhone);
        account.setRole("PARENT");
        account.setStatus(STATUS_ACTIVE);
        account.setPasswordHash(passwordEncoder.encode(buildParentInitialPassword(normalizedPhone)));
        userAccountMapper.insert(account);
    }
    return account;
}

public String buildParentInitialPassword(String phone) {
    String normalizedPhone = normalizeUsername(phone);
    return normalizedPhone.substring(Math.max(0, normalizedPhone.length() - 6));
}

private String resolveInitialPassword(UserAccount account) {
    if ("PARENT".equals(account.getRole()) && StringUtils.hasText(account.getUsername())) {
        return buildParentInitialPassword(account.getUsername());
    }
    // keep the existing coach/student/system branches below this line
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentAccountSyncService.java
package com.shuzi.managementplatform.domain.service;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.shuzi.managementplatform.domain.entity.ParentAccount;
import com.shuzi.managementplatform.domain.entity.ParentStudentRelation;
import com.shuzi.managementplatform.domain.entity.Student;
import com.shuzi.managementplatform.domain.entity.UserAccount;
import com.shuzi.managementplatform.domain.enums.ParentBindingType;
import com.shuzi.managementplatform.domain.mapper.ParentAccountMapper;
import com.shuzi.managementplatform.domain.mapper.ParentStudentRelationMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class ParentAccountSyncService {

    private final ParentAccountMapper parentAccountMapper;
    private final ParentStudentRelationMapper parentStudentRelationMapper;
    private final UserAccountService userAccountService;

    public ParentAccountSyncService(
            ParentAccountMapper parentAccountMapper,
            ParentStudentRelationMapper parentStudentRelationMapper,
            UserAccountService userAccountService
    ) {
        this.parentAccountMapper = parentAccountMapper;
        this.parentStudentRelationMapper = parentStudentRelationMapper;
        this.userAccountService = userAccountService;
    }

    @Transactional
    public void syncStudentGuardianBinding(Student student, String previousGuardianPhone) {
        String currentPhone = normalizePhone(student.getGuardianPhone());
        String oldPhone = normalizePhone(previousGuardianPhone);

        if (StringUtils.hasText(oldPhone) && !oldPhone.equals(currentPhone)) {
            removeAutomaticBinding(student.getId(), oldPhone);
        }
        if (!StringUtils.hasText(currentPhone)) {
            return;
        }

        ParentAccount parentAccount = ensureParentAccount(currentPhone, student.getGuardianName());
        ParentStudentRelation relation = parentStudentRelationMapper.selectOne(
                Wrappers.<ParentStudentRelation>lambdaQuery()
                        .eq(ParentStudentRelation::getParentAccountId, parentAccount.getId())
                        .eq(ParentStudentRelation::getStudentId, student.getId())
        );
        if (relation == null) {
            ParentStudentRelation created = new ParentStudentRelation();
            created.setParentAccountId(parentAccount.getId());
            created.setStudentId(student.getId());
            created.setBindingType(ParentBindingType.AUTO);
            parentStudentRelationMapper.insert(created);
            return;
        }
        ParentBindingType merged = relation.getBindingType().mergeAutomatic();
        if (merged != relation.getBindingType()) {
            relation.setBindingType(merged);
            parentStudentRelationMapper.updateById(relation);
        }
    }

    private void removeAutomaticBinding(Long studentId, String oldPhone) {
        ParentAccount oldParent = parentAccountMapper.selectOne(
                Wrappers.<ParentAccount>lambdaQuery().eq(ParentAccount::getPhone, oldPhone)
        );
        if (oldParent == null) {
            return;
        }
        ParentStudentRelation relation = parentStudentRelationMapper.selectOne(
                Wrappers.<ParentStudentRelation>lambdaQuery()
                        .eq(ParentStudentRelation::getParentAccountId, oldParent.getId())
                        .eq(ParentStudentRelation::getStudentId, studentId)
        );
        if (relation == null) {
            return;
        }
        if (relation.getBindingType() == ParentBindingType.AUTO) {
            parentStudentRelationMapper.deleteById(relation.getId());
            return;
        }
        if (relation.getBindingType() == ParentBindingType.AUTO_MANUAL) {
            relation.setBindingType(ParentBindingType.MANUAL);
            parentStudentRelationMapper.updateById(relation);
        }
    }

    private ParentAccount ensureParentAccount(String phone, String displayName) {
        ParentAccount existing = parentAccountMapper.selectOne(
                Wrappers.<ParentAccount>lambdaQuery().eq(ParentAccount::getPhone, phone)
        );
        if (existing != null) {
            if (StringUtils.hasText(displayName) && !StringUtils.hasText(existing.getDisplayName())) {
                existing.setDisplayName(displayName.trim());
                parentAccountMapper.updateById(existing);
            }
            return existing;
        }
        UserAccount login = userAccountService.upsertParentAccount(phone, displayName);
        ParentAccount created = new ParentAccount();
        created.setUserAccountId(login.getId());
        created.setDisplayName(StringUtils.hasText(displayName) ? displayName.trim() : "家长-" + phone.substring(phone.length() - 4));
        created.setPhone(phone);
        created.setStatus(UserAccountService.STATUS_ACTIVE);
        parentAccountMapper.insert(created);
        return created;
    }

    private String normalizePhone(String phone) {
        if (!StringUtils.hasText(phone)) {
            return null;
        }
        return phone.trim().replace(" ", "");
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
cd Code/backend-service/ManagementPlatform
.\mvnw.cmd -Dtest=ParentAccountSyncServiceTest test
```

Expected: PASS with both parent sync cases green.

- [ ] **Step 5: Commit**

```bash
git -C Code/backend-service/ManagementPlatform add src/main/resources/schema-mysql.sql src/main/java/com/shuzi/managementplatform/domain/enums/ParentBindingType.java src/main/java/com/shuzi/managementplatform/domain/entity/ParentStudentRelation.java src/main/java/com/shuzi/managementplatform/domain/service/UserAccountService.java src/main/java/com/shuzi/managementplatform/domain/service/ParentAccountSyncService.java src/test/java/com/shuzi/managementplatform/domain/service/ParentAccountSyncServiceTest.java
git -C Code/backend-service/ManagementPlatform commit -m "feat: add parent account sync foundation"
```

### Task 2: Wire Student Lifecycle Sync And Stop Login-Time Implicit Binding

**Files:**
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StudentService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentPortalService.java`
- Modify: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StudentServiceTest.java`
- Modify: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentPortalServiceTest.java`

- [ ] **Step 1: Write the failing lifecycle tests**

```java
// Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/StudentServiceTest.java
@Mock
private ParentAccountSyncService parentAccountSyncService;

@Test
void createShouldSyncParentAccountByGuardianPhone() {
    when(studentMapper.selectCount(any())).thenReturn(0L);
    when(studentMapper.insert(any(Student.class))).thenAnswer(invocation -> {
        Student saved = invocation.getArgument(0);
        org.springframework.test.util.ReflectionTestUtils.setField(saved, "id", 101L);
        return 1;
    });

    studentService.create(new StudentCreateRequest(
            "S1001",
            "Li Lei",
            Gender.MALE,
            LocalDate.of(2016, 5, 12),
            "Parent Li",
            "13800138000",
            StudentStatus.ACTIVE,
            "base class",
            null,
            null,
            null,
            null,
            null
    ));

    verify(parentAccountSyncService).syncStudentGuardianBinding(any(Student.class), isNull());
}

@Test
void updateShouldSyncParentAccountWhenGuardianPhoneChanges() {
    Student existing = new Student();
    org.springframework.test.util.ReflectionTestUtils.setField(existing, "id", 102L);
    existing.setStudentNo("S1002");
    existing.setGuardianPhone("13700137000");

    when(studentMapper.selectById(102L)).thenReturn(existing);

    studentService.update(102L, new StudentUpdateRequest(
            "Han Meimei",
            Gender.FEMALE,
            LocalDate.of(2016, 3, 9),
            "Parent Han",
            "13900139000",
            StudentStatus.ACTIVE,
            "remarks",
            null,
            null,
            null,
            null,
            null
    ));

    verify(parentAccountSyncService).syncStudentGuardianBinding(existing, "13700137000");
}
```

```java
// Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentPortalServiceTest.java
import static org.mockito.Mockito.never;

@Test
void listChildrenShouldNotInsertBindingsDuringLogin() {
    UserAccount userAccount = new UserAccount();
    userAccount.setUsername("13800138000");
    userAccount.setRole("PARENT");
    userAccount.setStatus("ACTIVE");

    ParentAccount parentAccount = new ParentAccount();
    org.springframework.test.util.ReflectionTestUtils.setField(parentAccount, "id", 88L);
    parentAccount.setPhone("13800138000");

    when(userAccountMapper.selectOne(any())).thenReturn(userAccount);
    when(parentAccountMapper.selectOne(any())).thenReturn(parentAccount);
    when(parentStudentRelationMapper.selectList(any())).thenReturn(List.of());

    Assertions.assertTrue(parentPortalService.listChildren("13800138000").isEmpty());
    verify(parentStudentRelationMapper, never()).insert(any());
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
cd Code/backend-service/ManagementPlatform
.\mvnw.cmd -Dtest=StudentServiceTest,ParentPortalServiceTest test
```

Expected: FAIL because `StudentService` does not yet depend on `ParentAccountSyncService`, and `ParentPortalService` still performs implicit binding during account resolution.

- [ ] **Step 3: Write the lifecycle wiring**

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/StudentService.java
private final ParentAccountSyncService parentAccountSyncService;

public StudentService(
        StudentMapper studentMapper,
        AttendanceRecordMapper attendanceRecordMapper,
        FitnessTestRecordMapper fitnessTestRecordMapper,
        TrainingRecordMapper trainingRecordMapper,
        UserAccountService userAccountService,
        ParentAccountSyncService parentAccountSyncService
) {
    this.studentMapper = studentMapper;
    this.attendanceRecordMapper = attendanceRecordMapper;
    this.fitnessTestRecordMapper = fitnessTestRecordMapper;
    this.trainingRecordMapper = trainingRecordMapper;
    this.userAccountService = userAccountService;
    this.parentAccountSyncService = parentAccountSyncService;
}

@Transactional
public StudentResponse create(StudentCreateRequest request) {
    // keep the existing uniqueness and insert logic
    studentMapper.insert(student);
    userAccountService.upsertStudentAccount(student);
    parentAccountSyncService.syncStudentGuardianBinding(student, null);
    return toResponse(student);
}

@Transactional
public StudentResponse update(Long id, StudentUpdateRequest request) {
    Student student = studentMapper.selectById(id);
    String previousGuardianPhone = student.getGuardianPhone();
    // keep the existing field updates
    studentMapper.updateById(student);
    userAccountService.upsertStudentAccount(student);
    parentAccountSyncService.syncStudentGuardianBinding(student, previousGuardianPhone);
    return toResponse(student);
}
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentPortalService.java
private ParentAccount resolveParentAccount(String username) {
    if (!StringUtils.hasText(username)) {
        throw new BusinessException(HttpStatus.UNAUTHORIZED, "未登录或登录状态已失效");
    }
    String normalizedUsername = username.trim().toLowerCase(Locale.ROOT);
    UserAccount userAccount = userAccountMapper.selectOne(
            Wrappers.<UserAccount>lambdaQuery().eq(UserAccount::getUsername, normalizedUsername)
    );
    if (userAccount == null) {
        throw new BusinessException(HttpStatus.UNAUTHORIZED, "登录账号不存在");
    }
    if (!ROLE_PARENT.equalsIgnoreCase(userAccount.getRole())) {
        throw new BusinessException(HttpStatus.FORBIDDEN, "当前账号不是家长角色");
    }

    ParentAccount parentAccount = parentAccountMapper.selectOne(
            Wrappers.<ParentAccount>lambdaQuery().eq(ParentAccount::getUserAccountId, userAccount.getId())
    );
    if (parentAccount == null) {
        parentAccount = new ParentAccount();
        parentAccount.setUserAccountId(userAccount.getId());
        parentAccount.setDisplayName("家长-" + userAccount.getUsername());
        parentAccount.setPhone(extractPhoneFromUsername(userAccount.getUsername()));
        parentAccount.setStatus(STATUS_ACTIVE);
        parentAccountMapper.insert(parentAccount);
    }
    return parentAccount;
}

// remove ensureDefaultStudentBinding(...) and its invocation entirely
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
cd Code/backend-service/ManagementPlatform
.\mvnw.cmd -Dtest=StudentServiceTest,ParentPortalServiceTest test
```

Expected: PASS with student lifecycle sync verification and no-login-side-effect verification both green.

- [ ] **Step 5: Commit**

```bash
git -C Code/backend-service/ManagementPlatform add src/main/java/com/shuzi/managementplatform/domain/service/StudentService.java src/main/java/com/shuzi/managementplatform/domain/service/ParentPortalService.java src/test/java/com/shuzi/managementplatform/domain/service/StudentServiceTest.java src/test/java/com/shuzi/managementplatform/domain/service/ParentPortalServiceTest.java
git -C Code/backend-service/ManagementPlatform commit -m "feat: sync parent bindings from student lifecycle"
```

### Task 3: Add Backend Parent Admin APIs

**Files:**
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminListItemResponse.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminBoundStudentResponse.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminDetailResponse.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentManualBindingCreateRequest.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentAdminService.java`
- Create: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/ParentAdminController.java`
- Test: `Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentAdminServiceTest.java`

- [ ] **Step 1: Write the failing admin service tests**

```java
// Code/backend-service/ManagementPlatform/src/test/java/com/shuzi/managementplatform/domain/service/ParentAdminServiceTest.java
package com.shuzi.managementplatform.domain.service;

import com.shuzi.managementplatform.domain.entity.ParentStudentRelation;
import com.shuzi.managementplatform.domain.enums.ParentBindingType;
import com.shuzi.managementplatform.domain.mapper.ParentAccountMapper;
import com.shuzi.managementplatform.domain.mapper.ParentStudentRelationMapper;
import com.shuzi.managementplatform.domain.mapper.StudentMapper;
import com.shuzi.managementplatform.domain.mapper.UserAccountMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ParentAdminServiceTest {

    @Mock
    private ParentAccountMapper parentAccountMapper;
    @Mock
    private ParentStudentRelationMapper parentStudentRelationMapper;
    @Mock
    private StudentMapper studentMapper;
    @Mock
    private UserAccountMapper userAccountMapper;

    @InjectMocks
    private ParentAdminService parentAdminService;

    @Test
    void addManualBindingShouldUpgradeAutoRelationToAutoManual() {
        ParentStudentRelation relation = new ParentStudentRelation();
        ReflectionTestUtils.setField(relation, "id", 9L);
        relation.setParentAccountId(5L);
        relation.setStudentId(7L);
        relation.setBindingType(ParentBindingType.AUTO);

        when(parentStudentRelationMapper.selectOne(any())).thenReturn(relation);

        parentAdminService.addManualBinding(5L, 7L);

        verify(parentStudentRelationMapper).updateById(org.mockito.ArgumentMatchers.argThat(updated ->
                updated.getId().equals(9L) && updated.getBindingType() == ParentBindingType.AUTO_MANUAL
        ));
    }

    @Test
    void removeManualBindingShouldDowngradeAutoManualToAuto() {
        ParentStudentRelation relation = new ParentStudentRelation();
        ReflectionTestUtils.setField(relation, "id", 10L);
        relation.setParentAccountId(5L);
        relation.setStudentId(8L);
        relation.setBindingType(ParentBindingType.AUTO_MANUAL);

        when(parentStudentRelationMapper.selectOne(any())).thenReturn(relation);

        parentAdminService.removeManualBinding(5L, 8L);

        verify(parentStudentRelationMapper).updateById(org.mockito.ArgumentMatchers.argThat(updated ->
                updated.getId().equals(10L) && updated.getBindingType() == ParentBindingType.AUTO
        ));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd Code/backend-service/ManagementPlatform
.\mvnw.cmd -Dtest=ParentAdminServiceTest test
```

Expected: FAIL with missing `ParentAdminService` and missing admin DTO/controller files.

- [ ] **Step 3: Write the admin API implementation**

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentManualBindingCreateRequest.java
package com.shuzi.managementplatform.web.dto.parentadmin;

import jakarta.validation.constraints.NotNull;

public record ParentManualBindingCreateRequest(
        @NotNull Long parentId,
        @NotNull Long studentId
) {
}
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminListItemResponse.java
package com.shuzi.managementplatform.web.dto.parentadmin;

import java.time.LocalDateTime;
import java.util.List;

public record ParentAdminListItemResponse(
        Long id,
        String displayName,
        String phone,
        String username,
        int studentCount,
        List<String> studentNames,
        LocalDateTime lastLoginAt,
        LocalDateTime updatedAt
) {
}
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminBoundStudentResponse.java
package com.shuzi.managementplatform.web.dto.parentadmin;

public record ParentAdminBoundStudentResponse(
        Long studentId,
        String studentNo,
        String studentName,
        String guardianPhone,
        String bindingType
) {
}
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/parentadmin/ParentAdminDetailResponse.java
package com.shuzi.managementplatform.web.dto.parentadmin;

import java.time.LocalDateTime;
import java.util.List;

public record ParentAdminDetailResponse(
        Long id,
        String displayName,
        String phone,
        String username,
        LocalDateTime lastLoginAt,
        LocalDateTime updatedAt,
        List<ParentAdminBoundStudentResponse> students
) {
}
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/domain/service/ParentAdminService.java
package com.shuzi.managementplatform.domain.service;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.shuzi.managementplatform.common.exception.BusinessException;
import com.shuzi.managementplatform.common.exception.ResourceNotFoundException;
import com.shuzi.managementplatform.domain.entity.ParentAccount;
import com.shuzi.managementplatform.domain.entity.ParentStudentRelation;
import com.shuzi.managementplatform.domain.entity.Student;
import com.shuzi.managementplatform.domain.entity.UserAccount;
import com.shuzi.managementplatform.domain.enums.ParentBindingType;
import com.shuzi.managementplatform.domain.mapper.ParentAccountMapper;
import com.shuzi.managementplatform.domain.mapper.ParentStudentRelationMapper;
import com.shuzi.managementplatform.domain.mapper.StudentMapper;
import com.shuzi.managementplatform.domain.mapper.UserAccountMapper;
import com.shuzi.managementplatform.web.dto.parentadmin.ParentAdminBoundStudentResponse;
import com.shuzi.managementplatform.web.dto.parentadmin.ParentAdminDetailResponse;
import com.shuzi.managementplatform.web.dto.parentadmin.ParentAdminListItemResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ParentAdminService {

    private final ParentAccountMapper parentAccountMapper;
    private final ParentStudentRelationMapper parentStudentRelationMapper;
    private final StudentMapper studentMapper;
    private final UserAccountMapper userAccountMapper;

    public ParentAdminService(
            ParentAccountMapper parentAccountMapper,
            ParentStudentRelationMapper parentStudentRelationMapper,
            StudentMapper studentMapper,
            UserAccountMapper userAccountMapper
    ) {
        this.parentAccountMapper = parentAccountMapper;
        this.parentStudentRelationMapper = parentStudentRelationMapper;
        this.studentMapper = studentMapper;
        this.userAccountMapper = userAccountMapper;
    }

    @Transactional(readOnly = true)
    public IPage<ParentAdminListItemResponse> page(String keyword, String studentName, int page, int size) {
        List<Long> scopedParentIds = resolveParentIdsByStudentName(studentName);
        Page<ParentAccount> request = new Page<>(page + 1L, size);
        Page<ParentAccount> result = parentAccountMapper.selectPage(
                request,
                Wrappers.<ParentAccount>lambdaQuery()
                        .and(StringUtils.hasText(keyword), wrapper -> wrapper
                                .like(ParentAccount::getDisplayName, keyword)
                                .or()
                                .like(ParentAccount::getPhone, keyword)
                        )
                        .in(scopedParentIds != null && !scopedParentIds.isEmpty(), ParentAccount::getId, scopedParentIds)
                        .orderByDesc(ParentAccount::getId)
        );

        List<Long> parentIds = result.getRecords().stream().map(ParentAccount::getId).toList();
        List<ParentStudentRelation> relations = parentIds.isEmpty() ? List.of() : parentStudentRelationMapper.selectList(
                Wrappers.<ParentStudentRelation>lambdaQuery().in(ParentStudentRelation::getParentAccountId, parentIds)
        );
        List<Long> studentIds = relations.stream().map(ParentStudentRelation::getStudentId).distinct().toList();
        Map<Long, Student> studentMap = studentIds.isEmpty() ? Map.of() : studentMapper.selectBatchIds(studentIds).stream()
                .collect(Collectors.toMap(Student::getId, student -> student));
        Map<Long, UserAccount> userMap = result.getRecords().stream()
                .map(ParentAccount::getUserAccountId)
                .distinct()
                .map(userAccountMapper::selectById)
                .collect(Collectors.toMap(UserAccount::getId, user -> user));

        Page<ParentAdminListItemResponse> response = new Page<>(result.getCurrent(), result.getSize(), result.getTotal());
        response.setRecords(result.getRecords().stream().map(account -> {
            List<String> names = relations.stream()
                    .filter(relation -> relation.getParentAccountId().equals(account.getId()))
                    .map(relation -> studentMap.get(relation.getStudentId()))
                    .filter(student -> student != null)
                    .map(Student::getName)
                    .toList();
            UserAccount login = userMap.get(account.getUserAccountId());
            return new ParentAdminListItemResponse(
                    account.getId(),
                    account.getDisplayName(),
                    account.getPhone(),
                    login == null ? "" : login.getUsername(),
                    names.size(),
                    names.stream().limit(3).toList(),
                    login == null ? null : login.getLastLoginAt(),
                    account.getUpdatedAt()
            );
        }).toList());
        return response;
    }

    @Transactional(readOnly = true)
    public ParentAdminDetailResponse getDetail(Long id) {
        ParentAccount account = parentAccountMapper.selectById(id);
        if (account == null) {
            throw new ResourceNotFoundException("parent account not found: " + id);
        }
        UserAccount login = userAccountMapper.selectById(account.getUserAccountId());
        List<ParentStudentRelation> relations = parentStudentRelationMapper.selectList(
                Wrappers.<ParentStudentRelation>lambdaQuery()
                        .eq(ParentStudentRelation::getParentAccountId, id)
                        .orderByAsc(ParentStudentRelation::getId)
        );
        List<Long> studentIds = relations.stream().map(ParentStudentRelation::getStudentId).toList();
        Map<Long, Student> studentMap = studentIds.isEmpty() ? Map.of() : studentMapper.selectBatchIds(studentIds).stream()
                .collect(Collectors.toMap(Student::getId, student -> student));

        List<ParentAdminBoundStudentResponse> students = relations.stream().map(relation -> {
            Student student = studentMap.get(relation.getStudentId());
            return new ParentAdminBoundStudentResponse(
                    relation.getStudentId(),
                    student == null ? "" : student.getStudentNo(),
                    student == null ? "" : student.getName(),
                    student == null ? "" : student.getGuardianPhone(),
                    relation.getBindingType().name()
            );
        }).toList();

        return new ParentAdminDetailResponse(
                account.getId(),
                account.getDisplayName(),
                account.getPhone(),
                login == null ? "" : login.getUsername(),
                login == null ? null : login.getLastLoginAt(),
                account.getUpdatedAt(),
                students
        );
    }

    @Transactional
    public void addManualBinding(Long parentId, Long studentId) {
        ParentStudentRelation relation = parentStudentRelationMapper.selectOne(
                Wrappers.<ParentStudentRelation>lambdaQuery()
                        .eq(ParentStudentRelation::getParentAccountId, parentId)
                        .eq(ParentStudentRelation::getStudentId, studentId)
        );
        if (relation == null) {
            ParentStudentRelation created = new ParentStudentRelation();
            created.setParentAccountId(parentId);
            created.setStudentId(studentId);
            created.setBindingType(ParentBindingType.MANUAL);
            parentStudentRelationMapper.insert(created);
            return;
        }
        ParentBindingType merged = relation.getBindingType().mergeManual();
        if (merged != relation.getBindingType()) {
            relation.setBindingType(merged);
            parentStudentRelationMapper.updateById(relation);
        }
    }

    @Transactional
    public void removeManualBinding(Long parentId, Long studentId) {
        ParentStudentRelation relation = parentStudentRelationMapper.selectOne(
                Wrappers.<ParentStudentRelation>lambdaQuery()
                        .eq(ParentStudentRelation::getParentAccountId, parentId)
                        .eq(ParentStudentRelation::getStudentId, studentId)
        );
        if (relation == null) {
            throw new ResourceNotFoundException("parent binding not found");
        }
        if (relation.getBindingType() == ParentBindingType.AUTO) {
            throw new BusinessException(HttpStatus.CONFLICT, "该关系由学员监护人手机号自动生成，请修改学员档案中的监护人手机号后再解除");
        }
        ParentBindingType downgraded = relation.getBindingType().removeManual();
        if (downgraded == null) {
            parentStudentRelationMapper.deleteById(relation.getId());
            return;
        }
        relation.setBindingType(downgraded);
        parentStudentRelationMapper.updateById(relation);
    }

    private List<Long> resolveParentIdsByStudentName(String studentName) {
        if (!StringUtils.hasText(studentName)) {
            return null;
        }
        List<Student> students = studentMapper.selectList(
                Wrappers.<Student>lambdaQuery().like(Student::getName, studentName.trim())
        );
        if (students.isEmpty()) {
            return List.of(-1L);
        }
        List<Long> studentIds = students.stream().map(Student::getId).toList();
        return parentStudentRelationMapper.selectList(
                Wrappers.<ParentStudentRelation>lambdaQuery().in(ParentStudentRelation::getStudentId, studentIds)
        ).stream().map(ParentStudentRelation::getParentAccountId).distinct().toList();
    }
}
```

```java
// Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/controller/ParentAdminController.java
package com.shuzi.managementplatform.web.controller;

import com.shuzi.managementplatform.common.api.ApiResponse;
import com.shuzi.managementplatform.common.api.PageResponse;
import com.shuzi.managementplatform.domain.service.ParentAdminService;
import com.shuzi.managementplatform.web.dto.parentadmin.ParentAdminDetailResponse;
import com.shuzi.managementplatform.web.dto.parentadmin.ParentAdminListItemResponse;
import com.shuzi.managementplatform.web.dto.parentadmin.ParentManualBindingCreateRequest;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/parents")
@PreAuthorize("hasRole('ADMIN')")
public class ParentAdminController {

    private final ParentAdminService parentAdminService;

    public ParentAdminController(ParentAdminService parentAdminService) {
        this.parentAdminService = parentAdminService;
    }

    @GetMapping
    public ApiResponse<PageResponse<ParentAdminListItemResponse>> page(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String studentName
    ) {
        return ApiResponse.ok(PageResponse.from(parentAdminService.page(keyword, studentName, page, size)));
    }

    @GetMapping("/{id}")
    public ApiResponse<ParentAdminDetailResponse> getDetail(@PathVariable Long id) {
        return ApiResponse.ok(parentAdminService.getDetail(id));
    }

    @PostMapping("/manual-bindings")
    public ApiResponse<Void> addManualBinding(@Valid @RequestBody ParentManualBindingCreateRequest request) {
        parentAdminService.addManualBinding(request.parentId(), request.studentId());
        return ApiResponse.ok("parent binding created", null);
    }

    @DeleteMapping("/{id}/students/{studentId}/manual-binding")
    public ApiResponse<Void> removeManualBinding(@PathVariable Long id, @PathVariable Long studentId) {
        parentAdminService.removeManualBinding(id, studentId);
        return ApiResponse.ok("parent binding updated", null);
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
cd Code/backend-service/ManagementPlatform
.\mvnw.cmd -Dtest=ParentAdminServiceTest test
```

Expected: PASS with both manual binding transition cases green.

- [ ] **Step 5: Commit**

```bash
git -C Code/backend-service/ManagementPlatform add src/main/java/com/shuzi/managementplatform/web/dto/parentadmin src/main/java/com/shuzi/managementplatform/domain/service/ParentAdminService.java src/main/java/com/shuzi/managementplatform/web/controller/ParentAdminController.java src/test/java/com/shuzi/managementplatform/domain/service/ParentAdminServiceTest.java
git -C Code/backend-service/ManagementPlatform commit -m "feat: add parent admin management api"
```

### Task 4: Build Admin-Panel Parent Management

**Files:**
- Modify: `Code/admin-panel/package.json`
- Modify: `Code/admin-panel/package-lock.json`
- Create: `Code/admin-panel/vitest.config.js`
- Create: `Code/admin-panel/src/api/modules/parents.js`
- Create: `Code/admin-panel/src/views/parents/parent-binding-actions.js`
- Create: `Code/admin-panel/src/views/parents/parent-binding-actions.test.js`
- Create: `Code/admin-panel/src/views/parents/ParentListView.vue`
- Modify: `Code/admin-panel/src/router/index.js`
- Modify: `Code/admin-panel/src/layouts/AdminLayout.vue`
- Modify: `Code/admin-panel/src/views/LoginView.vue`

- [ ] **Step 1: Write the failing parent-row action test**

```js
// Code/admin-panel/src/views/parents/parent-binding-actions.test.js
import { describe, expect, it } from 'vitest'
import { describeUnbindAction } from './parent-binding-actions'

describe('describeUnbindAction', () => {
  it('blocks direct unbind for AUTO relations', () => {
    expect(describeUnbindAction('AUTO')).toEqual({
      allowed: false,
      confirmText: '该关系由学员监护人手机号自动生成，请修改学员档案中的监护人手机号后再解除'
    })
  })

  it('downgrades AUTO_MANUAL relations instead of deleting them', () => {
    expect(describeUnbindAction('AUTO_MANUAL')).toEqual({
      allowed: true,
      confirmText: '移除人工绑定后将保留自动绑定'
    })
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd Code/admin-panel
npx vitest run src/views/parents/parent-binding-actions.test.js
```

Expected: FAIL with missing `vitest` package and/or missing `parent-binding-actions.js`.

- [ ] **Step 3: Write the admin-panel implementation**

```json
// Code/admin-panel/package.json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "test:unit": "vitest run"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.2.1",
    "vite": "^6.0.5",
    "vitest": "^2.1.8"
  }
}
```

```js
// Code/admin-panel/vitest.config.js
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'node',
    include: ['src/**/*.test.js']
  }
})
```

```js
// Code/admin-panel/src/views/parents/parent-binding-actions.js
export function describeUnbindAction(bindingType) {
  if (bindingType === 'AUTO') {
    return {
      allowed: false,
      confirmText: '该关系由学员监护人手机号自动生成，请修改学员档案中的监护人手机号后再解除'
    }
  }

  if (bindingType === 'AUTO_MANUAL') {
    return {
      allowed: true,
      confirmText: '移除人工绑定后将保留自动绑定'
    }
  }

  return {
    allowed: true,
    confirmText: '确认解除人工绑定关系吗？'
  }
}

export function bindingTypeLabel(bindingType) {
  return (
    {
      AUTO: '自动绑定',
      MANUAL: '人工绑定',
      AUTO_MANUAL: '自动 + 人工'
    }[bindingType] || '-'
  )
}
```

```js
// Code/admin-panel/src/api/modules/parents.js
import http from '../http'

function unwrap(response) {
  const body = response.data
  if (!body?.success) {
    throw new Error(body?.message || '请求失败')
  }
  return body.data
}

export async function listParents(params) {
  return unwrap(await http.get('/parents', { params }))
}

export async function getParent(id) {
  return unwrap(await http.get(`/parents/${id}`))
}

export async function createManualParentBinding(payload) {
  return unwrap(await http.post('/parents/manual-bindings', payload))
}

export async function removeManualParentBinding(parentId, studentId) {
  return unwrap(await http.delete(`/parents/${parentId}/students/${studentId}/manual-binding`))
}
```

```js
// Code/admin-panel/src/router/index.js
{
  path: 'parents',
  name: 'parents',
  component: () => import('../views/parents/ParentListView.vue'),
  meta: { title: '家长管理' }
}
```

```vue
<!-- Code/admin-panel/src/views/parents/ParentListView.vue -->
<template>
  <div class="page-panel">
    <h2 class="page-title">家长管理</h2>

    <div class="toolbar">
      <el-input v-model="query.keyword" placeholder="按家长姓名或手机号搜索" clearable @keyup.enter="fetchData" />
      <el-input v-model="query.studentName" placeholder="按绑定学员搜索" clearable @keyup.enter="fetchData" />
      <el-button type="primary" @click="fetchData">查询</el-button>
    </div>

    <el-table :data="rows" v-loading="loading" stripe>
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="displayName" label="家长姓名" width="160" />
      <el-table-column prop="phone" label="手机号" width="160" />
      <el-table-column prop="username" label="登录账号" width="160" />
      <el-table-column prop="studentCount" label="已绑学员数" width="110" />
      <el-table-column label="绑定学员" min-width="220">
        <template #default="{ row }">{{ (row.studentNames || []).join('、') || '-' }}</template>
      </el-table-column>
      <el-table-column prop="lastLoginAt" label="最近登录" width="180" />
      <el-table-column label="操作" width="360" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="openDetail(row.id)">详情</el-button>
          <el-button size="small" type="primary" @click="openBindDialog(row)">绑定学生</el-button>
          <el-button size="small" type="warning" @click="handleResetPassword(row)">重置密码</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { adminResetPassword } from '../../api/modules/auth'
import { getParent, listParents, createManualParentBinding, removeManualParentBinding } from '../../api/modules/parents'
import { listStudents } from '../../api/modules/students'
import { bindingTypeLabel, describeUnbindAction } from './parent-binding-actions'

const loading = ref(false)
const rows = ref([])
const total = ref(0)
const query = reactive({ page: 0, size: 10, keyword: '', studentName: '' })
const detailVisible = ref(false)
const bindVisible = ref(false)
const currentParent = ref(null)
const detail = ref(null)
const studentOptions = ref([])

async function fetchData() {
  loading.value = true
  try {
    const data = await listParents({ ...query, keyword: query.keyword || undefined, studentName: query.studentName || undefined })
    rows.value = data.content
    total.value = data.totalElements
  } finally {
    loading.value = false
  }
}

async function openDetail(id) {
  detail.value = await getParent(id)
  detailVisible.value = true
}

async function openBindDialog(row) {
  currentParent.value = row
  const students = await listStudents({ page: 0, size: 100 })
  studentOptions.value = students.content
  bindVisible.value = true
}

async function handleResetPassword(row) {
  const result = await adminResetPassword({ username: row.username })
  await ElMessageBox.alert(`账号：${result.username}\n新密码：${result.newPassword}`, '重置成功')
}

async function handleManualUnbind(studentRow) {
  const action = describeUnbindAction(studentRow.bindingType)
  if (!action.allowed) {
    ElMessage.warning(action.confirmText)
    return
  }
  await ElMessageBox.confirm(action.confirmText, '解绑确认', { type: 'warning' })
  await removeManualParentBinding(currentParent.value.id, studentRow.studentId)
  await openDetail(currentParent.value.id)
  ElMessage.success('绑定关系已更新')
}

onMounted(fetchData)
</script>
```

```vue
<!-- Code/admin-panel/src/layouts/AdminLayout.vue -->
<el-menu-item index="/parents">家长管理</el-menu-item>
```

```vue
<!-- Code/admin-panel/src/views/LoginView.vue -->
<div class="tips">管理后台仅支持管理员与教练登录，家长请在小程序端使用手机号登录。</div>
```

Then update the lockfile:

```bash
cd Code/admin-panel
npm install
```

- [ ] **Step 4: Run tests and build to verify they pass**

Run:

```bash
cd Code/admin-panel
npm run test:unit -- src/views/parents/parent-binding-actions.test.js
npm run build
```

Expected:

1. `test:unit` passes the `AUTO` and `AUTO_MANUAL` row-action cases.
2. `build` completes successfully with the new parent management route and page.

- [ ] **Step 5: Commit**

```bash
git -C Code/admin-panel add package.json package-lock.json vitest.config.js src/api/modules/parents.js src/views/parents/parent-binding-actions.js src/views/parents/parent-binding-actions.test.js src/views/parents/ParentListView.vue src/router/index.js src/layouts/AdminLayout.vue src/views/LoginView.vue
git -C Code/admin-panel commit -m "feat: add admin parent management page"
```

### Task 5: Sync Mini-Program Parent Login Copy And Run Full Verification

**Files:**
- Modify: `Code/mobile-app/src/pages/login/index.vue`

- [ ] **Step 1: Update the mini-program login copy**

```vue
<!-- Code/mobile-app/src/pages/login/index.vue -->
<template>
  <view class="page">
    <view class="card">
      <view class="title">统一登录</view>
      <view class="sub-title" style="margin-top: 8rpx">ZF 青少年体能培训教务管理平台</view>

      <view style="margin-top: 28rpx">
        <view class="required">用户名</view>
        <input class="input" v-model="form.username" placeholder="管理员/教练请输入账号，家长请输入手机号" />
      </view>

      <view style="margin-top: 20rpx">
        <view class="required">密码</view>
        <view class="password-row">
          <input
            class="input password-input"
            v-model="form.password"
            :password="!showPassword"
            placeholder="请输入密码"
          />
          <view class="toggle-password" @click="togglePassword">
            <u-icon :name="showPassword ? 'eye-off' : 'eye'" color="#6b7280" size="34rpx" />
          </view>
        </view>
      </view>

      <view class="form-actions">
        <u-button type="primary" :loading="loading" text="登录并进入系统" @click="handleLogin" />
      </view>

      <view class="tip">家长请使用手机号登录；首次自动创建的账号初始密码为手机号后 6 位。</view>
      <view class="tip">认证方式：JWT（Bearer Token）。登录状态本地保存 7 天，超时后需重新登录。</view>
    </view>
  </view>
</template>
```

- [ ] **Step 2: Run the full verification suite**

Run:

```bash
cd Code/backend-service/ManagementPlatform
.\mvnw.cmd -Dtest=ParentAccountSyncServiceTest,StudentServiceTest,ParentPortalServiceTest,ParentAdminServiceTest test

cd ..\..\admin-panel
npm run test:unit -- src/views/parents/parent-binding-actions.test.js
npm run build

cd ..\mobile-app
npm run type-check
npm run build:mp-weixin
```

Expected:

1. Backend parent-sync, lifecycle, portal, and admin-service tests all pass.
2. Admin-panel helper test passes and the parent management page builds successfully.
3. Mini-program type-check passes and the mp-weixin build completes with the updated login copy.

- [ ] **Step 3: Commit**

```bash
git -C Code/mobile-app add src/pages/login/index.vue
git -C Code/mobile-app commit -m "feat: sync parent phone login copy"
```

## Self-Review

### Spec Coverage

1. Phone-based parent identity, auto-created parent accounts, and initial password rules are implemented in Task 1.
2. Student-driven automatic binding, old-phone cleanup, and removal of login-time fallback binding are implemented in Task 2.
3. Admin list/detail/manual bind/manual unbind APIs are implemented in Task 3.
4. Admin-panel parent management UI and row-action semantics are implemented in Task 4.
5. Mini-program parent login copy synchronization and full-stack verification are implemented in Task 5.

No confirmed spec requirement is left without a corresponding task.

### Placeholder Scan

1. No `TODO`, `TBD`, or “similar to above” placeholders remain.
2. Each task includes exact files, concrete code snippets, commands, and expected outcomes.

### Type Consistency

1. `ParentBindingType` is the single source of truth for `AUTO`, `MANUAL`, and `AUTO_MANUAL`.
2. `ParentAccountSyncService` is the only lifecycle sync entrypoint called by `StudentService`.
3. Admin unbind behavior matches the design exactly:
   - `MANUAL` deletes
   - `AUTO_MANUAL` downgrades to `AUTO`
   - `AUTO` rejects direct unbind
