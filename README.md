# Parrots Enterprise Agent Profiles

企业级 AI Agent 配置仓库，遵循 [Hermes Agent Profile 分发规范](https://hermes-agent.nousresearch.com/docs/zh-Hans/user-guide/profile-distributions)。
每个分支对应一种业务角色的 Agent 配置，可作为完整分发仓库直接安装。

## 分支说明

| 分支 | 角色 | 描述 |
|------|------|------|
| `main` | 基础 | 默认配置模板 |
| `customer_service` | 客服 | 客服团队专用 AI Agent |
| `sales` | 销售 | 销售团队专用 AI Agent |
| `hr` | 人力资源 | 人力资源专用 AI Agent |
| `finance` | 财务 | 财务团队专用 AI Agent |
| `engineer` | 工程师 | 工程师团队专用 AI Agent |

## 配置结构

每个分支根目录包含 Hermes 标准分发结构：

```
├── distribution.yaml    # manifest: name, version, env-var requirements
├── SOUL.md              # the agent's personality / system prompt
├── config.yaml          # model, temperature, reasoning, tool defaults
├── skills/              # bundled skills that come with the agent
│   └── <skill>/SKILL.md
├── cron/                # scheduled tasks the agent runs
└── mcp.json             # MCP servers the agent connects to
```

### distribution.yaml 示例

```yaml
name: agent-name
version: 1.0.0
description: Agent description
author: Parrots Enterprise
hermes_requires: ">=0.1.0"
env_requires:
  - name: OPENAI_API_KEY
    description: OpenAI API Key
    required: true
  - name: AGENT_PORT
    description: Agent 服务端口
    default: "9000"
  - name: WEBUI_PORT
    description: WebUI 服务端口
    default: "8000"
```

## 使用方式

NodeHub 全局配置中设置此仓库地址，创建 Agent 时选择"使用全局配置"即可自动继承。

也可使用 Hermes CLI 安装某个角色的完整 Agent：

```bash
hermes profile install github.com/zhouwenzhu/parrots-ent-agent-profiles --ref customer_service --alias customer-service-agent
```

## 维护

修改分支配置后，运行 `./update-branches.sh` 可重新生成所有分支的 Hermes 标准分发结构并提交。
