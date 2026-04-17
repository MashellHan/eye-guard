# 迭代时间表

> PM 的长期运行排期。每 30 分钟一次 review，不同阶段分配不同 review 次数。

## 时间分配

| 阶段 | 预计时长 | Review 次数 (每 30 分钟一次) | 说明 |
|------|---------|-----|------|
| **Phase 1** (Notch Shell) | 1 小时 | 2-3 次 | 核心基建，必须稳 |
| **Phase 2** (数据注入) | 2 小时 | 3-4 次 | 多数据链路要对齐 |
| **Phase 3** (模式切换) | 2 小时 | 3-4 次 | ModeManager 不稳定会回溯很贵 |
| **Phase 4** (休息流) | 2 小时 | 3-4 次 | E2E 链路最长 |
| **Phase 5** (打磨) | 2-3 小时 | 4-6 次 | 多项细粒度 |
| **最终 QA 循环** | 持续 | 每 30 分钟 | 所有 Phase 完后进入守护模式 |

总计：**~10-12 小时**开发 + 持续 QA。

## Cron 设置

```
*/30 * * * *   → 每 30 分钟触发 review
```

- **First hour**：Phase 1 迭代 2 次（30min、60min）
- **Hours 2-3**：Phase 2 迭代 3 次（90min、120min、150min）
- **Hours 4-5**：Phase 3 迭代 3 次
- **Hours 6-7**：Phase 4 迭代 3 次
- **Hours 8-10**：Phase 5 迭代 4-6 次
- **Hours 10+**：全项目 QA 循环每 30min

## 触发行为

每次 cron 触发，Claude 按 `validation-protocol.md` 的 7 步走：
1. Git 状态
2. Build/Test
3. Code Review
4. UI Verification
5. Regression
6. Write Review Log
7. Decision

## 停滞检测

- 连续 2 次 review（1 小时）无进展 → log 警告
- 连续 4 次 review（2 小时）无进展 → 建议回滚

## 最终 QA 模式

当 `README.md` 的 "current phase" 为 "ALL DONE" 时：
- 每 30 分钟跑完整回归 matrix（随机抽 20%）
- 每 3 小时跑完全量回归 + 性能基线
- 每 6 小时截齐所有 Phase 截图，对比初始期望

## 用户可见报告

每次 cron 结束后，Claude 的会话末尾应包括一行摘要：
```
[Island Merge Review] Phase 1 — 3/8 acceptance items passed, blocked on P1.2 (hover).
Next action: Agent to fix NotchEventMonitors throttle.
```
