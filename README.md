# Parrots Enterprise Agent Profiles

企业级 AI Agent 配置仓库。每个分支对应一种业务角色的 Agent 配置。

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

每个分支根目录包含 `distribution.yaml`，定义 Agent 的完整配置：

```yaml
name: agent-name
version: 1.0.0
description: Agent description
author: Parrots
hermes_requires: ">=0.1.0"
env_requires:
  - name: OPENAI_API_KEY
    description: OpenAI API Key
    required: true
  - name: AGENT_PORT
    description: Agent 服务端口
    default: "9000"
```

## 使用方式

NodeHub 全局配置中设置此仓库地址，创建 Agent 时选择"使用全局配置"即可自动继承。