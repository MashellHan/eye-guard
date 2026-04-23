# EyeGuard 开发准则

## 技术栈
- Swift 6.0 strict concurrency
- macOS 14+ (Sonoma)
- SwiftUI + AppKit（菜单栏、悬浮窗、Notch overlay）
- Swift Testing 框架
- 协议导向 + 依赖注入

## 架构边界（硬约束）
- 业务逻辑（`BreakScheduler` / `ActivityMonitor` / `HealthScore`）必须**两种显示模式共享**
- Mascot 和 Notch 是纯 view 层，**不能反向依赖业务逻辑修改**（只读）
- 新加 module 必须在 `EyeGuard/Sources/<Module>/` 下
- 详细规则见 `docs/conventions/architecture-rules.md`

## 工作流（多 agent 协作）

> 已启用 **dev + reviewer + tester** 三个 subagent。

### 触发方式
- 用户发出"实现/修复/重构"类需求 → 用 `/feature` skill 启动完整流程
- 每日全量 UI 回归 → `/ui-test-full`（建议挂 cron，每天凌晨 3 点）
- 简单问答、读代码、调试 → 不走 multi-agent 流程，主 Claude 直接处理

### 流程
1. **PLAN**：lead 拆解需求，写 plan 到 `.agent_workspace/plans/<task_id>.md`，**等用户确认**
2. **DEV ↔ REVIEW**（最多 3 轮）：dev 实现 → reviewer 评审 → 不过则回 dev
3. **TEST**：lead 根据 `git diff` + `docs/conventions/test-matrix.md` 算出 `test_scope`，调 tester
   - tester 跑单测 + UI 截图 + 性能采样
   - 输出结构化 `report.json`，含 critical issues 和 `suggested_files`
   - **FAIL → 自动触发 dev 修复循环**：lead 把 critical issues 拼成修复 plan → dev 修 → reviewer review → tester 重跑（最多 2 轮）
4. **COMMIT**（自动）：tester pass 后按 Conventional Commits 拆分 commit
5. **PUSH**：必须用户显式确认才 push

### 通信约定
- 三个 agent **不直接对话**，全部通过 `.agent_workspace/` 文件交换
- 每次调 subagent 前，lead 更新 `.agent_workspace/handoff/<task_id>.json`
- 状态行（最后一行）作为 subagent 的"返回值"：
  - `DEV_DONE task_id=<id> iteration=<n> files_modified=<n> build_status=<pass|warn>`
  - `REVIEW_DONE task_id=<id> iteration=<n> verdict=<PASS|CHANGES_REQUESTED> critical=<n> warning=<n>`
  - `TEST_DONE task_id=<id> iteration=<n> verdict=<PASS|FAIL> critical=<n> warning=<n> report=<path>`
- tester 的 `report.json` 是 dev 修复 test 失败时的**核心输入**，dev 要按 issue id 逐条回应

### 升级规则（停止条件）
- review 第 4 轮还没过 → **停**，分歧报给用户
- test 第 3 轮还没过 → **停**，所有报告给用户
- dev build 连续 3 次失败 → **停**
- 任何 subagent 输出格式不对 → 重试 1 次，仍不对就停
- 任何阶段拿不准 → 问用户

### 测试范围计算
见 `docs/conventions/test-matrix.md`。基本规则：
- 改了什么模块，跑对应的 UI 截图 + 性能项 + 单测
- baseline UI（menubar-popover、mascot-idle）+ baseline 性能（launch、idle-rss、idle-cpu）**永远跑**
- 改 `Models/`、`Protocols/`、`Constants.swift`、`Package.swift` → **跑全部单测**
- 改 `Utils/Colors.swift` → **跑全部 baseline UI**（颜色全局影响）
- 只改文档 / `.claude/` → 跳过 TEST 阶段，直接 COMMIT

## Commit 规范
- Conventional Commits: `<type>(<scope>): <subject>`
- type: `feat` / `fix` / `docs` / `refactor` / `test` / `chore` / `perf`
- scope: 模块名（`menubar` / `mascot` / `notch` / `scheduling` / `report` 等）
- body 引用 plan + review 路径
- **push 前必须问用户确认**

## 医学/科学依据
- 任何提醒/break 时间逻辑改动必须标注 source（AAO / OSHA / EU 90/270/EEC / NIOSH）
- 不要凭直觉改医学相关的常量

## 常用命令
```bash
swift build                              # 编译
swift test                               # 单测
bash scripts/build-app.sh                # 打包 .app
pkill -f EyeGuard.app && open EyeGuard.app  # 重启
```
