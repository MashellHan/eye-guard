---
name: feature
description: Orchestrate the full dev→review→test→commit workflow for a code change in EyeGuard. Computes test scope from git diff via test-matrix.md. Auto-commits after tests pass. Push always requires user confirmation. Use when user asks to implement/add/fix/refactor.
user-invocable: true
argument-hint: <一句话需求描述>
---

你扮演 **LEAD**，按以下流程协调 `dev` / `reviewer` / `tester` 三个 subagent。

## 0. 准备
- 生成 `task_id = $(date +%Y%m%d-%H%M)-<slug>`
- 创建 `.agent_workspace/{plans,reviews,tests,handoff}/`（如不存在）
- 初始化 handoff JSON：`.agent_workspace/handoff/<task_id>.json`
- 读 `docs/conventions/architecture-rules.md`、`swift-style.md`、`test-matrix.md`

## 1. PLAN（你自己干）
分析需求 `$ARGUMENTS`，写 `.agent_workspace/plans/<task_id>.md`，含：
- 需求理解、涉及模块、实现步骤、验收标准、风险点、不在范围内

完整读给用户听，**等用户确认**再继续。

## 2. DEV ↔ REVIEW 循环（最多 3 轮）
更新 handoff：`stage="dev"`, iteration+=1

调 `Agent(subagent_type="dev", prompt=...)`：传 task_id / plan_path / iteration / (review_path 如果是返工)。

读 `DEV_DONE` 行：build_status=pass 才进 review。

调 `Agent(subagent_type="reviewer", prompt=...)`：传 task_id / plan_path / impl_path / iteration。

读 `REVIEW_DONE` 行：
- `verdict=PASS` → 进 TEST
- `verdict=CHANGES_REQUESTED` → 回 DEV，iteration+=1
- 第 4 轮还没过 → **停止**，把分歧报给用户

## 3. TEST 阶段 ⭐ 新增

### 3a. 计算 test_scope
基于 `git diff --name-only HEAD`：
```bash
git diff --name-only HEAD
```

读 `docs/conventions/test-matrix.md` 的路径模式，对每个改动文件查表，并集得 `test_scope`：
```json
{
  "mode": "scoped",
  "ui":   ["menubar-popover", "overlay-tier2-micro"],
  "perf": ["launch", "idle-rss", "idle-cpu", "overlay-render-cpu"],
  "unit": ["NotificationsTests"]
}
```

> 如果 diff 只涉及文档/配置（无 Swift 文件），跳过 TEST 阶段（直接到 COMMIT）。

### 3b. 调 tester
更新 handoff：`stage="test"`, `test_iteration=1`

调 `Agent(subagent_type="tester", prompt=...)`：传 task_id / plan_path / test_scope JSON / iteration。

读 `TEST_DONE` 行 + 解析 `report.json`：

#### `verdict=PASS` → 进 COMMIT

#### `verdict=FAIL` → **自动触发 dev 修复循环**
1. 读 `report.json`，提取所有 `severity=critical` 的 issues
2. 写"修复 plan"到 `.agent_workspace/plans/<task_id>-test-fix-r<n>.md`：
   - 列出每个 critical issue（id、description、suggested_files、suggested_fix）
   - 范围 = test 报告中所有 critical issue 的 suggested_files 合集
3. 调 `Agent(subagent_type="dev", prompt=...)`：传 plan_path 指向修复 plan，**额外传 `test_report_path` 指向 report.json**
   - dev 要在 impl 笔记中逐 issue id 回应
4. dev 完成后，**走 reviewer 一轮**（test fix 也需要 review）
5. reviewer pass → **重跑 tester**（同 scope，iteration+=1）
6. tester pass → COMMIT
7. **test 循环最多 2 轮**（首次 + 1 次修复重测）。第 3 次还 FAIL → 停止，把所有报告给用户

## 4. COMMIT 阶段（自动）⭐ 新增

> 用户约定：tester pass 后**自动 commit**，但 push 仍需用户确认。

### 4a. 拆分 commit
按 Conventional Commits + 按改动性质拆：
- 业务代码改动 → `<type>(<scope>): <subject>`
- 测试代码改动 → `test(<scope>): <subject>`
- 配置/文档 → 单独一个 `chore(...)` 或 `docs(...)`

如果改动只属于一类，单 commit 即可。

### 4b. 执行
```bash
git add <related files>
git commit -m "<type>(<scope>): <subject>

<body 引用 plan + test report 路径>

Test: .agent_workspace/tests/<task_id>/report.md
Plan: .agent_workspace/plans/<task_id>.md

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

> ⚠️ **永远不要** `git add .` 或 `git add -A`。明确列出本次任务相关的文件。
> ⚠️ **永远不要** 自动 push。push 必须用户显式确认。

### 4c. 输出
```
✅ Task <task_id> 完成

Plan:    .agent_workspace/plans/<task_id>.md
Review:  .agent_workspace/reviews/<task_id>-r<n>.md (verdict=PASS)
Test:    .agent_workspace/tests/<task_id>/report.md (verdict=PASS)
Commits: <hash1>, <hash2>

下一步：要 push 到 origin/main 吗？(yes/no)
```

## 升级规则
- review 第 4 轮还没过 → 停
- test 第 3 轮还没过 → 停
- dev build 连续 3 次失败 → 停
- 任何 subagent 输出格式不对 → 重试 1 次，仍不对就停
- 任何拿不准 → 问用户

## 通信协议
- 三个 subagent 通过 `.agent_workspace/` 文件通信，不直接对话
- tester 的 `report.json` 是 dev 修复时的**核心输入**，dev 要逐 issue id 回应
- 每次调 subagent 前更新 handoff JSON
