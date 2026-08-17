#!/bin/bash
set -e

cd /workspace/parrots-enterprise-agent/parrots-ent-agent-profiles

# 更新每个分支的 distribution.yaml 与数据库 Agent 模板一致
update_branch() {
  local branch=$1
  local name=$2
  local desc=$3
  local system_prompt=$4
  local welcome_message=$5
  shift 5
  local skills=("$@")

  git checkout "$branch" 2>/dev/null || git checkout -b "$branch" main

  # 构建 skills YAML
  skills_yaml=""
  for skill in "${skills[@]}"; do
    IFS='|' read -r skill_name skill_desc <<< "$skill"
    skills_yaml+="    - name: $skill_name${NL}      description: $skill_desc${NL}      enabled: true${NL}"
  done

  cat > distribution.yaml <<YAML
name: $name
version: 1.0.0
description: $desc
author: Parrots Enterprise
hermes_requires: ">=0.1.0"

system_prompt: |
  $system_prompt

welcome_message: "$welcome_message"

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
$skills_yaml
YAML

  git add distribution.yaml
  git commit -m "feat: update $name profile configuration"
  echo "✓ Branch '$branch' updated"
}

NL=$'\n'

# 1. 客服助手 (customer_service)
update_branch "customer_service" \
  "客服助手" \
  "客服团队专用 AI Agent 配置" \
  "你是一个专业的客服助手，负责处理客户咨询和问题反馈。请始终保持礼貌和耐心，准确理解客户需求，提供及时有效的帮助。对于无法解决的问题，及时创建工单并转交相关团队。" \
  "您好！我是客服助手，有什么可以帮助您的吗？" \
  "faq_answer|常见问题解答" \
  "ticket_create|创建工单" \
  "sentiment_analysis|情感分析"

# 2. 销售助手 (sales)
update_branch "sales" \
  "销售助手" \
  "销售团队专用 AI Agent 配置" \
  "你是一个专业的销售助手，帮助销售团队高效完成业务流程。支持客户信息查询、报价生成、交易跟踪等核心功能，助力销售团队提升业绩。" \
  "您好！我是销售助手，可以帮助您查询客户信息、生成报价等。" \
  "customer_query|客户信息查询" \
  "quote_generate|报价生成" \
  "deal_tracking|交易跟踪"

# 3. 人力资源助手 (hr)
update_branch "hr" \
  "人力资源助手" \
  "人力资源团队专用 AI Agent 配置" \
  "你是一个专业的人力资源助手，帮助 HR 团队处理日常事务。支持员工信息查询、简历解析、面试安排等核心功能，提升人力资源工作效率。" \
  "您好！我是人力资源助手，有什么可以帮助您的吗？" \
  "employee_query|员工信息查询" \
  "resume_parse|简历解析" \
  "interview_schedule|面试安排"

# 4. 财务助手 (finance)
update_branch "finance" \
  "财务助手" \
  "财务团队专用 AI Agent 配置" \
  "你是一个专业的财务助手，帮助财务团队处理财务相关事务。支持财务报表查询、报销审核、预算分析等核心功能，确保财务工作准确高效。" \
  "您好！我是财务助手，可以帮助您查询报表、处理报销等。" \
  "report_query|报表查询" \
  "expense_review|报销审核" \
  "budget_analysis|预算分析"

# 5. 工程师助手 (engineer)
update_branch "engineer" \
  "工程师助手" \
  "工程师团队专用 AI Agent 配置" \
  "你是一个专业的工程助手，帮助开发团队提高工作效率。支持代码审查、技术文档查询、Bug 分析等核心功能，助力团队交付高质量代码。" \
  "您好！我是工程助手，可以帮助您进行代码审查、文档查询等。" \
  "code_review|代码审查" \
  "doc_query|文档查询" \
  "bug_analysis|Bug 分析"

# 更新 main 分支的基础配置
git checkout main
cat > distribution.yaml <<YAML
name: AI Agent 基础配置
version: 1.0.0
description: Parrots Enterprise AI Agent 基础配置模板
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
YAML
git add distribution.yaml
git commit -m "feat: update base profile configuration"

echo ""
echo "========================================="
echo "所有分支配置已更新"
echo "========================================="
git branch -a | grep -v remotes