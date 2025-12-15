# Dev Code Workflow for Java8 + Spring + TestNG Projects

这是一个针对 Java8 + Spring + TestNG 项目的开发工作流命令。

---

## Step 0: 方案输入验证

**必须要求用户提供方案输入**

检查用户是否提供了方案输入：
- 如果用户输入了 `@.claude/specs/{feature_name}/dev-plan.md` 文件路径，则直接使用该方案
- 如果用户输入了其他形式的方案描述（需求文档、技术方案等），则需要在 Step 1 进行任务拆解
- 如果用户**没有提供任何方案输入**，则使用 `AskUserQuestion` 工具询问用户：
  ```
  请提供开发方案输入，可以是以下形式之一：
  1. dev-plan.md 文件路径（如 @.claude/specs/feature_name/dev-plan.md）
  2. 需求文档或技术方案描述
  3. 功能描述和实现要求
  ```

---

## Step 1: 开发计划生成阶段

**根据方案输入类型处理：**

1. **如果用户提供的是 `@.claude/specs/{feature_name}/dev-plan.md` 文件路径**：
   - 直接读取该文件作为开发计划
   - 跳过任务拆解，进入 Step 2

2. **如果用户提供的是其他形式的方案**：
   - 分析用户提供的方案内容
   - 使用 `spec-plan-generator` agent 进行技术分析和任务拆解：
     ```
     Task tool with subagent_type='spec-plan-generator'
     prompt: 基于用户提供的方案，生成技术方案和开发计划文档
     ```
   - 生成的文档将保存到 `.claude/specs/{feature_name}/`：
     - `tech-spec.md` - 技术方案
     - `dev-plan.md` - 开发计划
   - 展示生成的开发计划给用户确认

---

## Step 2: 并行开发阶段

### 2.1 用户选择确认

使用 `AskUserQuestion` 工具询问用户两个问题：

**问题 A：选择代码编写方式**
- **Claude 主 Agent**：在当前上下文窗口串行编写代码（推荐，适合需要深度上下文理解的任务）
- **Codex 子代理**：使用 OpenAI Codex 进行代码生成（适合大量并行任务）
- **Claude 子代理**：使用 Claude 子代理进行代码生成

记住用户选择为 `${backend}`（main / codex / claude）

**问题 B：单元测试时机**
- **马上编码单元测试**：每个任务完成后立即编写对应的单元测试
- **稍后统一处理**：先完成所有功能代码，最后统一编写单元测试

### 2.2 执行开发任务

#### 如果用户选择 Claude 主 Agent：

在当前上下文窗口对多个任务串行进行代码编写：
1. 按照 dev-plan.md 中的任务顺序逐个完成
2. 每个任务完成后更新 TodoWrite
3. 如果用户选择马上编码单元测试，则每个任务后立即编写测试

#### 如果用户选择 Codex 或 Claude 子代理：

使用 `codeagent` skill 调用 codeagent-wrapper 完成任务：

```bash
# Backend task (use ${backend} backend)
codeagent-wrapper --backend ${backend} - <<'EOF'
Task: [task-id]
Reference: @.claude/specs/{feature_name}/dev-plan.md
Scope: [task file scope]
Deliverables: code + unit tests（如果用户选择马上编码）
Context: [context detail if task may need]
EOF
```

**并发策略：**
- 可并行的任务同时执行，**最大三并发**
- 存在依赖关系的任务串行执行
- 使用 Task tool 的 `run_in_background` 参数实现并行

**任务调度示例：**
```
# 并行执行示例（3个独立任务）
Task 1: 实现 UserService ─┐
Task 2: 实现 OrderService ─┼─→ 并行执行
Task 3: 实现 ProductService ─┘

# 串行执行示例（有依赖关系）
Task 4: 实现 BaseRepository → Task 5: 实现 UserRepository
```

---

## Step 3: 任务总结

### 3.1 代码编译验证

使用 Subagent 运行代码编译：

```bash
# 对于 Maven 项目
mvn compile -q

# 如果编译失败，Subagent 返回详细的报错信息
```

**编译失败处理：**
- Subagent 收集完整的编译错误信息
- 分析错误原因（语法错误、依赖缺失、类型不匹配等）
- 提供修复建议
- 如有需要，自动修复简单的编译错误

### 3.2 任务完成总结

提供以下信息：

**任务完成列表：**
```
✅ 已完成任务：
  - [Task-1] 实现 UserService
  - [Task-2] 实现 OrderService
  - [Task-3] 编写 UserServiceTest

❌ 未完成任务（如有）：
  - [Task-4] 原因：xxx
```

**关键文件修改：**
```
📁 修改文件列表：
  - src/main/java/com/example/service/UserService.java (新增)
  - src/main/java/com/example/repository/UserRepository.java (修改)
  - src/test/java/com/example/service/UserServiceTest.java (新增)
```

---

## 异常处理

### Codeagent 失败处理
- **重试策略**：失败后自动重试一次
- **重试仍失败**：记录错误日志，继续执行下一个任务
- **错误记录格式**：
  ```
  ⚠️ Task [task-id] 执行失败
  错误信息：[error message]
  已跳过，继续执行后续任务
  ```

### 依赖冲突处理
- 检测到任务间存在依赖冲突时，**自动序列化执行**
- 示例：Task B 依赖 Task A 的输出，则等待 Task A 完成后再执行 Task B

---

## Communication Style

- **直接简洁**：报告进度时使用简短明了的语言
- **进度汇报**：每个工作流步骤完成后汇报状态
- **问题高亮**：遇到阻塞问题立即高亮显示
- **可执行建议**：覆盖率检查失败时提供具体的修复步骤
- **速度优先**：通过并行化提升执行速度，同时确保覆盖率验证

---

## 单元测试规范

### 运行测试

多模块 Maven 项目需从根目录运行测试，避免依赖模块未编译的问题：

```bash
# 1. 创建临时 testng xml（指定要运行的测试类）
# 文件路径: {starter-module}/src/test/resources/testng_ut_checkin_temp.xml

# 2. 从根目录运行
mvn test -DsuiteXmlFile=src/test/resources/testng_ut_checkin_temp.xml

# 3. 测试后删除临时文件（不要提交到 git）
rm {starter-module}/src/test/resources/testng_ut_checkin_temp.xml
```

### 编写规范（TestNG + Mockito）

- **@BeforeMethod 重建 SUT**：每个用例全新构造被测类及其 mock 依赖，避免用例间状态污染
- **静态方法 mock**：使用 `try (MockedStatic<Xxx> m = mockStatic(Xxx.class)) { ... }` 限定作用域
- **静态配置归位**：在 @BeforeMethod/@AfterMethod 重置静态字段，避免用例间影响

---

## 使用示例

```bash
# 示例 1：使用已有的 dev-plan.md
/dev-code @.claude/specs/user-management/dev-plan.md

# 示例 2：提供需求描述
/dev-code 实现用户登录功能，包含：1. 用户名密码验证 2. JWT token 生成 3. 登录日志记录

# 示例 3：无参数调用（会提示输入方案）
/dev-code
```
