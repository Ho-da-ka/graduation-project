# Display Nickname on Coach Welcome Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Change the welcome screen for coaches (and other roles) to display their actual name (nickname) instead of their system account username.

**Architecture:** 
1. **Backend:** Update `AuthTokenResponse` DTO to include a `nickname` field.
2. **Backend:** Update `AuthService` to fetch the nickname from the corresponding profile (Coach/Student/Admin) during login/refresh.
3. **Frontend:** Update `AuthPayload` type to include `nickname`.
4. **Frontend:** Update `AuthService.loginWithJwt` to store the nickname.
5. **Frontend:** Update `admin/home.vue` and `student/home.vue` to display the nickname.

**Tech Stack:** Java, Spring Boot, Vue 3, TypeScript, Uni-app.

---

### Task 1: Backend - Update AuthTokenResponse DTO

**Files:**
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/web/dto/auth/AuthTokenResponse.java`

- [ ] **Step 1: Add nickname field to AuthTokenResponse**

```java
public record AuthTokenResponse(
        String tokenType,
        String accessToken,
        long accessTokenExpiresIn,
        String refreshToken,
        String username,
        String nickname, // Add this
        String role
) {
}
```

### Task 2: Backend - Update AuthService Implementation

**Files:**
- Modify: `Code/backend-service/ManagementPlatform/src/main/java/com/shuzi/managementplatform/security/AuthService.java`

- [ ] **Step 1: Update login method to populate nickname**

Need to fetch Coach/Student name if applicable.

- [ ] **Step 2: Update refresh method to populate nickname**

### Task 3: Frontend - Update Auth Types and Store

**Files:**
- Modify: `Code/mobile-app/src/store/auth.ts`
- Modify: `Code/mobile-app/src/api/modules/auth.ts`

- [ ] **Step 1: Add nickname to AuthPayload interface in `store/auth.ts`**
- [ ] **Step 2: Update getAuth() and setAuth() in `store/auth.ts`**
- [ ] **Step 3: Add nickname to AuthTokenData interface in `api/modules/auth.ts`**

### Task 4: Frontend - Update UI Components

**Files:**
- Modify: `Code/mobile-app/src/pages/admin/home.vue`
- Modify: `Code/mobile-app/src/pages/student/home.vue`

- [ ] **Step 1: Update `admin/home.vue` to use nickname**
- [ ] **Step 2: Update `student/home.vue` to use nickname**
