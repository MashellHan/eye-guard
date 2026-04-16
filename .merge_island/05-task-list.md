# 开发任务清单

## Phase 0: Fork + 项目重命名

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 0.1 | Fork MioIsland repo 到 MashellHan | P0 | 30m | ✅ MashellHan/mio-guard |
| 0.2 | 重命名 Xcode target/scheme ClaudeIsland → MioGuard | P0 | 1h | 🚧 需要 Xcode（非 CLT） |
| 0.3 | 更新 Bundle ID + Info.plist | P0 | 30m | 🚧 需要 Xcode（非 CLT） |
| 0.4 | 创建 Core/ModeManager.swift | P0 | 2h | ✅ @Observable, UserDefaults 持久化 |
| 0.5 | 右键菜单添加模式切换 | P1 | 1h | ✅ ModeSwitchRow in NotchMenuView |
| 0.6 | 验证所有 MioIsland 功能正常 | P0 | 1h | 🚧 需要 Xcode build |

## Phase 1: 精灵系统统一

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 1.1 | 创建 Mascot/MascotProtocol.swift | P0 | 1h | ✅ MascotRenderable + Expression(11) + Container + Voice |
| 1.2 | 移植阿普到 Mascot/Apu/ （5 files） | P0 | 3h | 🔄 ApuMiniView done, 完整 MascotView 待移植 |
| 1.3 | 创建 ApuMiniView (30pt Notch 版) | P0 | 2h | ✅ 220行，瞳孔追踪+11种表情+耳朵 |
| 1.4 | 创建 MascotContainer 统一容器 | P0 | 2h | ✅ 含在 MascotProtocol.swift |
| 1.5 | NotchViewModel 集成精灵切换 | P1 | 2h | ✅ Eye Guard 模式显示 ApuMiniView |
| 1.6 | 模式切换精灵动画 | P2 | 1h | ⬜ |
| 1.7 | 移植 SpeechBubbleView | P2 | 1h | ⬜ |

## Phase 2: 护眼核心

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 2.1 | 移植 BreakScheduler.swift | P0 | 2h | ✅ 解耦回调，含 HealthScoreCalculator + DataPersistence |
| 2.2 | 移植 ActivityMonitor.swift | P0 | 1h | ✅ CGEventTap + ScreenLockObserver + 节流 |
| 2.3 | 移植 Models (BreakType, ReminderMode 等) | P0 | 1h | ✅ BreakType + ReminderMode + EyeGuardModels |
| 2.4 | 移植 Protocols/ (5 files) | P0 | 1h | ✅ EyeGuardProtocols + AppModule |
| 2.5 | 创建 EyeGuardModule.swift 模块入口 | P0 | 2h | ✅ @Observable, activate/deactivate lifecycle |
| 2.6 | ModeManager ↔ EyeGuardModule 接入 | P0 | 1h | ✅ AppDelegate 集成，模式切换联动 |
| 2.7 | 合并 SoundManager | P1 | 2h | ✅ EyeGuardSoundManager 独立于 MioIsland (Phase 4 完成) |
| 2.8 | 移植 NightModeManager | P2 | 1h | ✅ @Observable, nightStartHour/EndHour, bilingual messages |
| 2.9 | 移植 Constants + TimeFormatting | P1 | 30m | ✅ EyeGuardConstants.swift |

## Phase 3: 休息覆盖层

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 3.1 | 移植 BreakOverlayView | P0 | 2h | ✅ 解耦 SoundManager，英文 UI |
| 3.2 | 移植 FullScreenOverlayView | P0 | 2h | ✅ ApuMiniView 替代 MascotView |
| 3.3 | 移植 OverlayWindow | P0 | 1h | ✅ OverlayWindowController + KeyableWindow |
| 3.4 | 移植 MandatoryShakeModifier | P1 | 30m | ✅ 直接复制 |
| 3.5 | 移植 EyeGuardOverlayManager | P0 | 1h | ✅ 替代 NotificationManager，路由 break→UI |
| 3.6 | Notch 休息状态适配 | P1 | 2h | ✅ 收起态显示 Resting + eye.slash |

## Phase 4: 眼保健操 + TTS

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 4.1 | 移植 Exercises/ (3 files) | P0 | 2h | ✅ EyeExercise + ExerciseView + ExerciseSessionView |
| 4.2 | 移植 TTS 功能到统一 SoundManager | P0 | 2h | ✅ EyeGuardSoundManager with TTS |
| 4.3 | 移植 Tips/ (3 files) | P1 | 1h | ✅ EyeHealthTip + TipDatabase + TipBubbleView |
| 4.4 | 全屏覆盖多显示器适配 | P1 | 1h | ✅ 主屏交互+副屏 dimmed overlay |

## Phase 5: Notch 护眼面板

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 5.1 | Eye Guard Notch 展开面板 UI | P0 | 4h | ✅ EyeGuardNotchView + ContinuousTimeSection + HealthScoreSection |
| 5.2 | 连续使用时间大字体 + 进度条 | P0 | 2h | ✅ 含在 ContinuousTimeSection |
| 5.3 | 健康评分显示 | P0 | 1h | ✅ 含在 HealthScoreSection |
| 5.4 | 移植 HealthScoreCalculator | P0 | 1h | ✅ 已在 Phase 2 完成 |
| 5.5 | Notch 收起状态 — 颜色分级 | P1 | 1h | ✅ EyeGuardCollapsedContent + 状态点颜色分级 |

## Phase 6: Dashboard + 报告 + 设置

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 6.1 | 移植 Dashboard/ (3 files) | P1 | 2h | ✅ DashboardView + WindowController + HistoryManager |
| 6.2 | 移植 Reporting/ (3 files) | P1 | 2h | ✅ DailyReportGenerator + ReportDataProvider (无 AI) |
| 6.3 | 移植 DataPersistenceManager | P1 | 1h | ✅ 已在 Phase 2 完成 |
| 6.4 | 合并 PreferencesView | P1 | 3h | ✅ PreferencesView + WindowController + ReminderMode extensions |
| 6.5 | 移植 ColorAnalyzer (可选) | P3 | 1h | ⬜ |
| 6.6 | 移植 AI/InsightGenerator (可选) | P3 | 1h | ⬜ |

## Phase 7: Dual 模式 + 打磨

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 7.1 | Dual Mode Notch 分区布局 | P0 | 4h | ✅ DualModeNotchView split layout + NotchContentType.dualMode |
| 7.2 | 双精灵交互动画 | P2 | 3h | ⬜ |
| 7.3 | 模式间事件联动 | P1 | 2h | ✅ AppEvent dispatch: idle, activity, modeChanged |
| 7.4 | 性能优化 | P1 | 2h | ✅ Timer overhead fix, memory leak fix, dedup observers |
| 7.5 | 暗色/亮色主题 | P2 | 2h | ⬜ |
| 7.6 | 中英本地化 | P2 | 2h | ⬜ |
| 7.7 | 清理死代码 | P1 | 2h | ✅ Removed unused singletons, dead methods, simplified ReportDataProvider |
| 7.8 | 完整测试 | P0 | 3h | ⬜ |

## Phase 8: 发布

| # | Task | Priority | Est | Status |
|---|------|----------|-----|--------|
| 8.1 | 更新 README | P0 | 1h | ⬜ |
| 8.2 | 更新 Homebrew tap | P0 | 30m | ⬜ |
| 8.3 | GitHub Release v4.0.0 | P0 | 30m | ⬜ |

---

**总计**: ~42 tasks, ~75h estimated
