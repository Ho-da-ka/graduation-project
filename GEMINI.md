# ZF 青少年体能培训教务管理平台 - 项目准则

## 项目技术栈
- 后端：Spring Boot 3.3.8 + MyBatis-Plus + MySQL
- 前端：Vue 3 + Element Plus + Vite
- 移动端：uni-app + uView Plus

## 最近更新与维护
### 2026-05-04 修复与优化
- **异常处理优化**：
  - 增强 `GlobalExceptionHandler`，显式处理 `AccessDeniedException`，确保越权访问时返回 403 错误码而非 500 服务器错误。
- **权限与 RBAC 精细化**：
  - **学员管理**：隐藏教练角色的“下载导入模板”和“导入 Excel”按钮（仅管理员可见）。
  - **侧边栏导航**：隐藏教练角色的“教练管理”和“家长管理”菜单项。
- **自助功能**：
  - 验证并确保教练角色可以通过顶栏“修改密码”功能自主更新登录密码。
