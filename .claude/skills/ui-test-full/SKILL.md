---
name: ui-test-full
description: Run the full daily UI regression — captures all UI states defined in test-matrix.md, runs full perf suite, runs all unit tests. Designed to be invoked daily (cron / loop) when no specific change is being tested.
user-invocable: true
argument-hint: [task_id]
---

每日全量 UI 回归测试。**默认每天触发一次**，覆盖 test-matrix 中**所有** UI 状态（不依赖 git diff 判断 scope）。

## 工作流（你扮演 lead 简化版）

1. 生成 task_id：`daily-$(date +%Y%m%d)`（或用 $1 覆盖）
2. 创建 handoff 标记 `.agent_workspace/handoff/<task_id>.json`，stage=test, mode=full
3. 计算 full scope：读 `docs/conventions/test-matrix.md`，把所有 UI 状态聚合成 `test_scope.ui` 全集
4. 调 `Agent(subagent_type="tester", prompt=...)`：
   - task_id
   - test_scope.mode = "full"
   - test_scope.ui = <所有状态>
   - test_scope.perf = <全部 perf 指标>
   - test_scope.unit = ["ALL"]
   - iteration = 1
5. 读 tester 返回的 `report.json`
6. **不调 dev 修复**（每日报告只做留痕）
7. 输出摘要：
   - PASS → 一句话日志即可
   - FAIL → **highlight critical issues**，建议用户起一个修复任务（`/feature 修 daily test 报告中的 X`）
8. 把报告路径 echo 到 stdout，便于 cron 抓取

## 用法
```bash
# 手动跑
/ui-test-full

# cron 跑（推荐每天凌晨 3 点）
0 3 * * * cd /path/to/eye-guard && claude -p "/ui-test-full" --bare --output-format text >> .agent_workspace/daily-test.log 2>&1
```

## 输出
最后一行：
```
DAILY_TEST_DONE task_id=<id> verdict=<PASS|FAIL> critical=<n> report=<path>
```
