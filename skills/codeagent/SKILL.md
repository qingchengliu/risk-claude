---
name: codeagent
description: Execute codeagent-wrapper for multi-backend AI code tasks. Supports Codex, Claude, and Gemini backends with file references (@syntax) and structured output.
---

# Codeagent Wrapper Integration

## Overview

Execute codeagent-wrapper commands with pluggable AI backends (Codex, Claude, Gemini). Supports file references via `@` syntax and parallel task execution.

## ⚠️ 重要：Bash 超时设置

**启动 codeagent-wrapper 时，必须将 Bash 工具的 timeout 参数设置为 2 小时（7200000 毫秒）**，否则任务可能因超时而中断。

```
Bash tool parameters:
- timeout: 7200000  # 2小时，必须设置！
```

---

## When to Use

- Complex code analysis requiring deep understanding
- Large-scale refactoring across multiple files
- Automated code generation with backend selection

## Usage

**HEREDOC syntax** (recommended):
```bash
codeagent-wrapper - [working_dir] <<'EOF'
<task content here>
EOF
```

**With backend selection**:
```bash
codeagent-wrapper --backend claude - <<'EOF'
<task content here>
EOF
```

**Simple tasks**:
```bash
codeagent-wrapper "simple task" [working_dir]
codeagent-wrapper --backend gemini "simple task"
```

## Backends

| Backend | Command | Description |
|---------|---------|-------------|
| codex | `--backend codex` | OpenAI Codex (default) |
| claude | `--backend claude` | Anthropic Claude |
| gemini | `--backend gemini` | Google Gemini |

## Parameters

- `task` (required): Task description, supports `@file` references
- `working_dir` (optional): Working directory (default: current)
- `--backend` (optional): Select AI backend (codex/claude/gemini)

## Return Format

```
Agent response text here...

---
SESSION_ID: 019a7247-ac9d-71f3-89e2-a823dbd8fd14
```

## Resume Session 

```bash
codeagent-wrapper resume <session_id> - <<'EOF'
<follow-up task>
EOF
```

## Parallel Execution

```bash
codeagent-wrapper --parallel <<'EOF'
---TASK---
id: task1
workdir: /path/to/dir
---CONTENT---
task content
---TASK---
id: task2
dependencies: task1
---CONTENT---
dependent task
EOF
```

## Environment Variables

- `CODEX_TIMEOUT`: Override timeout in milliseconds (default: 7200000)

## Invocation Pattern

```
Bash tool parameters:
- command: codeagent-wrapper --backend <backend> - [working_dir] <<'EOF'
  <task content>
  EOF
- timeout: 7200000
- description: <brief description>
```
