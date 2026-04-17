# Phase 5 — 打磨 + 发布准备

> **目标**：把前 4 个 Phase 合成的产品打磨到发布质量。多屏、hover 速度偏好、位置微调、暗色/亮色、图标，以及发布清单。

## 前置

- Phase 1-4 全部 ✅

## 交付物

### 新增 / 修改

```
EyeGuard/Sources/Notch/
├── Preferences/
│   ├── NotchCustomization.swift       # horizontalOffset / hoverSpeed / screenID
│   └── NotchCustomizationStore.swift  # @Observable + UserDefaults
└── Views/
    └── NotchPreferencesSection.swift  # Preferences 面板里的 Notch 子节
```

- App 图标：用 SF Symbol 组合或代码绘制（SPM 不便用 Assets.xcassets）
- README 更新：加 "Notch mode" 章节 + 截图
- CHANGELOG：v4.0.0 条目

### 打磨清单

- [ ] 多屏：在外接屏（无刘海）显示"软件刘海" (38pt 黑条) 或者不显示（偏好开关）
- [ ] Hover 速度：instant / fast / normal / slow 四档
- [ ] 位置微调：左右 ±30pt 偏移滑块
- [ ] 暗色/亮色：跟随系统，Notch 面板用 `.ultraThinMaterial`
- [ ] 启动动画：Apu 的俏皮感 — boot 动画时 Notch 轻微弹跳
- [ ] 所有字体统一用 `.rounded` design
- [ ] 本地化：中文 + 英文全覆盖

## 验收

### A. 全量回归

- [ ] `swift test` 全绿（目标 ≥ 210 测试）
- [ ] 手动按 `.island_merge/validation/regression-matrix.md` 跑一遍全流程
- [ ] 3+ 小时真实使用无崩溃

### B. 性能

- [ ] 启动时间 < 1.5s
- [ ] 空闲 CPU < 1%
- [ ] 内存 < 150 MB

### C. 发布物

- [ ] `README.md` + `README.zh-CN.md` 更新
- [ ] `CHANGELOG.md` v4.0.0
- [ ] GitHub Release 草稿（含截图、GIF）
- [ ] Homebrew tap 更新 PR 草稿
- [ ] 发布公告文案（中/英）

### D. UI 截图

- `01-hero-notch.png`（首屏大图）
- `02-hero-apu.png`
- `03-mode-switch.gif`
- `04-break-flow.gif`
- `05-preferences.png`
- `06-multi-screen.png`
