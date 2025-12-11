# Claude Code Workflow

> Fork from [cexll/myclaude](https://github.com/cexll/myclaude)

这是一个个人日常使用的 Claude Code 工作流。

## 安装

### 方式一：Python 安装（推荐）

```bash
# 克隆仓库
git clone https://github.com/qingchengliu/risk-claude.git
cd risk-claude

# 安装（需要 Python 3.6+）
python install.py

# 可选：安装 jsonschema 以启用配置验证
pip install jsonschema
```

### 方式二：Shell 脚本安装

**Linux/macOS:**
```bash
git clone https://github.com/qingchengliu/risk-claude.git
cd risk-claude
bash install.sh
```

**Windows:**
```cmd
git clone https://github.com/qingchengliu/risk-claude.git
cd risk-claude
install.bat
```

### 安装选项

```bash
# 指定安装目录
python install.py --install-dir ~/.claude

# 强制覆盖已存在的文件
python install.py --force

# 查看可用模块
python install.py --list-modules

# 安装指定模块
python install.py --module workflow
```

## 目录结构

```
risk-claude/
├── commands/       # 自定义命令
├── agents/         # 代理配置
├── skills/         # 技能配置
├── config.json     # 安装配置
├── install.py      # Python 安装脚本
├── install.sh      # Linux/macOS 安装脚本
└── install.bat     # Windows 安装脚本
```
