#!/bin/bash
set -e

# ============================================
# 更新各分支的 profile 为 Hermes 标准分发结构
# 与 hermes-agent 的 profile-distributions 规范保持一致
#
# 每个角色分支包含：
#   distribution.yaml   # manifest: name, version, env-var requirements
#   SOUL.md             # agent 人格 / 系统提示词
#   config.yaml         # model, temperature, reasoning, tool defaults
#   skills/             # 捆绑技能（每个技能一个目录，含 SKILL.md）
#   cron/               # 定时任务
#   mcp.json            # MCP 服务器连接
# ============================================

cd /workspace/parrots-enterprise-agent/parrots-ent-agent-profiles

# 生成 config.yaml 模板
write_config_yaml() {
  local welcome=$1
  cat > config.yaml <<YAML
# Hermes Agent 配置
# 每个安装者可调整 model/provider（config.yaml 在更新时默认保留本地覆盖）
model:
  model: ""
  provider: ""
  temperature: 0.7

agent:
  max_turns: 500

toolsets:
  - hermes-cli

# 兼容字段：WebUI 欢迎消息
welcome_message: "$welcome"
YAML
}

# 生成 mcp.json（空服务器配置）
write_mcp_json() {
  cat > mcp.json <<JSON
{
  "servers": {}
}
JSON
}

# 生成技能目录，参数为 "目录名|技能显示名|技能描述"
write_skills() {
  local skills=("$@")
  rm -rf skills
  mkdir -p skills
  for skill in "${skills[@]}"; do
    IFS='|' read -r skill_dir skill_title skill_desc <<< "$skill"
    mkdir -p "skills/$skill_dir"
    cat > "skills/$skill_dir/SKILL.md" <<SKILL
---
name: $skill_dir
description: "$skill_desc"
version: 1.0.0
author: Parrots Enterprise
license: MIT
metadata:
  hermes:
    tags: [$skill_title]
---

# $skill_title

$skill_desc

## 使用方式

1. 当任务涉及「$skill_desc」时，使用本技能。
2. 遵循技能中的步骤完成操作，遇到异常时向用户说明原因。
SKILL
  done
}

# 更新单个角色分支
update_branch() {
  local branch=$1
  local name=$2
  local desc=$3
  local soul=$4
  local welcome=$5
  local cron_file=$6
  local cron_schedule=$7
  local cron_name=$8
  local cron_prompt=$9
  shift 9
  local skills=("$@")

  git checkout "$branch" 2>/dev/null || git checkout -b "$branch" main

  # 1. distribution.yaml - Hermes 分发 manifest
  cat > distribution.yaml <<YAML
name: $name
version: 1.0.0
description: $desc
hermes_requires: ">=0.1.0"
author: Parrots Enterprise
license: MIT

# 兼容字段：WebUI 欢迎消息（非 Hermes 标准字段，被安全忽略）
welcome_message: "$welcome"

# 安装者需要配置的环境变量
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
YAML

  # 2. SOUL.md - 人格 / 系统提示词
  cat > SOUL.md <<MD
$soul
MD

  # 3. config.yaml - 模型与工具配置
  write_config_yaml "$welcome"

  # 4. skills/ - 捆绑技能
  write_skills "${skills[@]}"

  # 5. cron/ - 定时任务
  rm -rf cron
  mkdir -p cron
  cat > "cron/$cron_file" <<JSON
{
  "name": "$cron_name",
  "prompt": "$cron_prompt",
  "schedule": "$cron_schedule"
}
JSON

  # 6. mcp.json - MCP 服务器连接
  write_mcp_json

  git add distribution.yaml SOUL.md config.yaml skills cron mcp.json
  git commit -m "feat: $name profile 重构为 Hermes 标准分发结构" --allow-empty
  echo "✓ Branch '$branch' 已更新为 Hermes 标准分发结构"
}

# 1. 客服助手 (customer_service)
update_branch "customer_service" \
  "客服助手" \
  "客服团队专用 AI Agent 配置" \
  "你是一个专业的客服助手，负责处理客户咨询和问题反馈。请始终保持礼貌和耐心，准确理解客户需求，提供及时有效的帮助。对于无法解决的问题，及时创建工单并转交相关团队。" \
  "您好！我是客服助手，有什么可以帮助您的吗？" \
  "daily-ticket-summary.json" \
  "0 9 * * *" \
  "每日工单汇总" \
  "汇总昨日所有客户工单的处理情况，标记未解决的工单并提醒跟进。" \
  "faq_answer|常见问题解答|基于知识库快速回答客户常见问题" \
  "ticket_create|创建工单|根据客户反馈创建并转交工单" \
  "sentiment_analysis|情感分析|分析客户消息中的情感倾向以辅助应对"

# 2. 销售助手 (sales)
update_branch "sales" \
  "销售助手" \
  "销售团队专用 AI Agent 配置" \
  "你是一个专业的销售助手，帮助销售团队高效完成业务流程。支持客户信息查询、报价生成、交易跟踪等核心功能，助力销售团队提升业绩。" \
  "您好！我是销售助手，可以帮助您查询客户信息、生成报价等。" \
  "weekly-sales-report.json" \
  "0 18 * * 0" \
  "每周销售周报" \
  "生成本周销售数据周报：新增客户、成交金额、跟进中的交易，并给出下周建议。" \
  "customer_query|客户信息查询|查询客户基本信息与历史交易记录" \
  "quote_generate|报价生成|根据产品与数量生成报价单" \
  "deal_tracking|交易跟踪|跟踪销售漏斗中各阶段交易进展"

# 3. 人力资源助手 (hr)
update_branch "hr" \
  "人力资源助手" \
  "人力资源团队专用 AI Agent 配置" \
  "你是一个专业的人力资源助手，帮助 HR 团队处理日常事务。支持员工信息查询、简历解析、面试安排等核心功能，提升人力资源工作效率。" \
  "您好！我是人力资源助手，有什么可以帮助您的吗？" \
  "daily-interview-reminder.json" \
  "0 8 * * 1-5" \
  "每日面试提醒" \
  "列出当天安排的面试，提醒面试官准时参加并准备候选人简历摘要。" \
  "employee_query|员工信息查询|查询员工基础信息与组织架构" \
  "resume_parse|简历解析|解析候选人简历并提取关键信息" \
  "interview_schedule|面试安排|协调面试官与候选人时间安排面试"

# 4. 财务助手 (finance)
update_branch "finance" \
  "财务助手" \
  "财务团队专用 AI Agent 配置" \
  "你是一个专业的财务助手，帮助财务团队处理财务相关事务。支持财务报表查询、报销审核、预算分析等核心功能，确保财务工作准确高效。" \
  "您好！我是财务助手，可以帮助您查询报表、处理报销等。" \
  "monthly-financial-report.json" \
  "0 9 1 * *" \
  "月度财务报告" \
  "生成上月财务报告：收入支出汇总、预算执行情况、待处理报销提醒。" \
  "report_query|报表查询|查询财务报表与经营数据" \
  "expense_review|报销审核|审核报销单的合规性与金额" \
  "budget_analysis|预算分析|分析预算执行情况并预警超支"

# 5. 工程师助手 (engineer)
update_branch "engineer" \
  "工程师助手" \
  "工程师团队专用 AI Agent 配置" \
  "你是一个专业的工程助手，帮助开发团队提高工作效率。支持代码审查、技术文档查询、Bug 分析等核心功能，助力团队交付高质量代码。" \
  "您好！我是工程助手，可以帮助您进行代码审查、文档查询等。" \
  "weekly-code-review.json" \
  "0 17 * * 5" \
  "每周代码审查提醒" \
  "汇总本周待审查的 PR，按优先级提醒团队成员完成代码审查。" \
  "code_review|代码审查|审查代码质量、风格与潜在缺陷" \
  "doc_query|文档查询|查询技术文档与 API 使用说明" \
  "bug_analysis|Bug 分析|分析 Bug 根因并给出修复建议"

# 更新 main 分支的基础模板（同样为 Hermes 标准结构）
git checkout main
cat > distribution.yaml <<YAML
name: AI Agent 基础配置
version: 1.0.0
description: Parrots Enterprise AI Agent 基础配置模板
hermes_requires: ">=0.1.0"
author: Parrots Enterprise
license: MIT

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
YAML

cat > SOUL.md <<MD
你是一个智能的企业级 AI 助手，帮助团队成员高效完成工作。
MD

write_config_yaml "您好！我是您的智能 AI 助手，请告诉我需要帮助什么？"
rm -rf skills cron
mkdir -p skills cron
cat > skills/general-assistant/SKILL.md <<SKILL
---
name: general-assistant
description: "通用智能助手能力：对话、问答、信息整理"
version: 1.0.0
author: Parrots Enterprise
license: MIT
metadata:
  hermes:
    tags: [通用, 助手]
---

# 通用助手

提供通用的对话问答与信息整理能力。
SKILL
write_mcp_json

git add distribution.yaml SOUL.md config.yaml skills cron mcp.json
git commit -m "feat: 基础模板重构为 Hermes 标准分发结构" --allow-empty

echo ""
echo "========================================="
echo "所有分支已重构为 Hermes 标准分发结构"
echo "========================================="
git branch -a | grep -v remotes
