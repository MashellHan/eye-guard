# Validation Protocol — Agent 验证流程

> 每次 30 分钟 PM (Claude) 运行此流程，检查实现 Agent 的进度、代码质量、测试结果、UI 效果。

## 触发方式

- **自动**：cron `*/30 * * * *` → 触发 Claude 运行 `/loop island-review`
- **手动**：用户说 "review 一下 island merge" 时

## 当前 Phase 定位

1. 读 `.island_merge/README.md` 找到当前 Phase
2. 读 `.island_merge/phases/phase-N.md`
3. 读最近 3 份 `.island_merge/review_log/*.md` 了解迭代历史

## 验证步骤

### Step 1: Git 状态

```bash
git log --oneline -10
git status
```

- 有没有新 commit？涉及 `EyeGuard/Sources/Notch/` 或 `.island_merge/` 吗？
- 如果无变化且未到预期迭代时间：只记录 "no progress"，不做 review

### Step 2: Build / Test

```bash
swift build 2>&1 | tail -30
swift test 2>&1 | tail -50
```

记录：
- Build：✅/❌，耗时
- Tests：通过/总数，失败名单
- 警告数量、未解决的 TODO

### Step 3: 代码审查

对比 `.island_merge/phases/phase-N.md` 的交付物清单：
- [ ] 每个要求的新文件是否存在？
- [ ] 每个文件是否 ≤ 400 行？
- [ ] 是否有 `print()` / 硬编码密钥？
- [ ] `@Observable` 是否正确用？
- [ ] `@MainActor` 隔离是否正确？
- [ ] 是否有 memory leak 风险（循环引用）？

### Step 4: UI 验证

如果 Agent 已 commit 截图到 `.island_merge/screenshots/actual/phase-N/`：
- 对比该 Phase 的期望截图清单
- 缺失的列出来
- 已有的：尺寸、风格、刘海对齐合理吗？

如果需要亲自截图：
- 尝试 `swift run EyeGuard` 启动（如果能无 GUI 运行）
- 或者在 review_log 记录"需要用户手动验证截图"

### Step 5: 回归

读 `.island_merge/validation/regression-matrix.md`：
- 对应 Phase 的回归项每一条运行
- 失败项列出

### Step 6: 写 Review Log

模板存在 `.island_merge/validation/review-log-template.md`。

保存路径：`.island_merge/review_log/YYYY-MM-DD-HHMM-phase-N.md`

### Step 7: 决策

| 情况 | 行动 |
|------|------|
| 全部 ✅ | 更新 `README.md` 的"当前 Phase"，把下一个 Phase 任务从 `blocked` 改为 `pending` |
| 有失败项但可修 | 写具体修复指令到 review log，下次 Agent 读取 |
| 连续 2 次 review 停滞 | 标记 "blocked"，通知用户（留言到 log） |
| 连续 3 次 review 严重失败 | 建议回滚 Phase，重新设计 |

## 长期（所有 Phase 完成后）循环

当 `README.md` 记录全部 5 个 Phase ✅：

### 最终 QA 模式（每 30 分钟）

1. 全量构建 + 测试
2. 随机选 1 个 Phase 的回归项跑一遍
3. 扫描近 24h 的 review_log，找累计的 known issues
4. 写入 `.island_merge/review_log/final-qa/YYYY-MM-DD-HHMM.md`

### 最终 QA 提纲（一次性）

触发：用户说 "最终验收"

1. 跑全量回归（`regression-matrix.md` 每一条）
2. 截齐 5 个 Phase 所有要求的截图
3. 跑性能基准（启动时间、CPU、内存）
4. 生成 `.island_merge/final-report.md`
5. 对比初始愿景（`README.md` 的"主旨"），回答"是不是用户想要的"
