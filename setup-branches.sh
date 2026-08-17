#!/bin/bash
# 初始化 Agent Profiles 仓库，为每个角色创建独立分支

set -e

echo "=== 初始化 Git 仓库 ==="
cd "$(dirname "$0")"
git init
git checkout -b main

echo "=== 提交 main 分支 ==="
git add README.md distribution.yaml
git commit -m "feat: init base agent profile config"

# 定义角色分支配置
declare -A BRANCHES
BRANCHES[customer_service]="客服"
BRANCHES[sales]="销售"
BRANCHES[hr]="人力资源"
BRANCHES[finance]="财务"
BRANCHES[engineer]="工程师"

for branch in "${!BRANCHES[@]}"; do
    label="${BRANCHES[$branch]}"
    echo ""
    echo "=== 创建分支: $branch ($label) ==="

    git checkout -b "$branch" main

    # 创建该角色的 distribution.yaml
    cat > distribution.yaml <<YAML
name: ${label}助手
version: 1.0.0
description: ${label}团队专用 AI Agent 配置
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
skills:
  - name: 智能对话
    description: 基于大模型的智能对话能力
    enabled: true
  - name: 知识检索
    description: 企业知识库检索
    enabled: true
YAML

    git add distribution.yaml
    git commit -m "feat: add ${label} agent profile"
done

echo ""
echo "=== 切回 main 分支 ==="
git checkout main

echo ""
echo "=== 分支创建完成 ==="
git branch -a