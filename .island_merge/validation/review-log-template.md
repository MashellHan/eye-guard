# Review Log Template

> 复制此模板到 `.island_merge/review_log/YYYY-MM-DD-HHMM-phase-N.md`

---

# Review Log — Phase N — YYYY-MM-DD HH:MM

**Reviewer**: Claude (PM)
**Duration**: ~X minutes
**Trigger**: scheduled / manual
**Last reviewed HEAD**: `<sha>`
**Current HEAD**: `<sha>`

## Progress Since Last Review

- 新增 commits: N
- 关键变更文件: `...`

## Build & Test

| Check | Result | Time | Notes |
|-------|--------|------|-------|
| `swift build` | ✅/❌ | Xs | warnings: N |
| `swift test` | ✅/❌ | Xs | X/Y passed |

失败测试：
- `TestName` — reason

## Code Review

### 文件清单对齐

| Required File | Exists | Lines | Pass |
|--------------|--------|-------|------|
| `Notch/NotchModule.swift` | ✅/❌ | N | ✅/❌ |
| ... | | | |

### 规范检查

- [ ] 所有文件 ≤ 400 行
- [ ] 无 `print()`
- [ ] 无硬编码密钥
- [ ] `@Observable` 使用正确
- [ ] `@MainActor` 隔离正确
- [ ] 无循环引用（`[weak self]`）
- [ ] `let` over `var`
- [ ] 无 `Combine`（换成 `Observation`）

### 关键 issue（CRITICAL/HIGH/MEDIUM/LOW）

- [SEVERITY] 描述 @ file:line

## UI Verification

### 期望截图存在性

| File | Exists | Looks correct | Notes |
|------|--------|---------------|-------|
| `01-boot-collapsed.png` | ✅/❌ | ✅/❌ | |
| ... | | | |

## Regression

运行 `regression-matrix.md` 对应 Phase 的项：
- [✅] 现有 186 测试通过
- [✅/❌] 项目 X
- ...

## Decision

- [ ] Phase N 通过 → 更新 README 当前 Phase 到 N+1
- [ ] 有修复项，Agent 下次读取
- [ ] 停滞警告
- [ ] 建议回滚

## 修复指令 (for next Agent)

1. 具体指令 1
2. 具体指令 2

## 备注

自由文本
