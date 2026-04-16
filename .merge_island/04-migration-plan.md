# 分阶段迁移计划

## 原则

- 以 **MioIsland** 仓库为主仓库（Notch/窗口/插件架构更成熟）
- EyeGuard 功能**逐模块移入**，每个阶段可独立运行
- 每阶段结束都有可运行的 app + 测试

---

## Phase 0: Fork + 项目重命名 (Day 1)

**目标**: 建立合并项目基础

- [ ] Fork MioIsland 到 MashellHan/mio-guard（或继续用 eye-guard repo）
- [ ] 重命名 Xcode target: ClaudeIsland → MioGuard
- [ ] 更新 Bundle ID: com.mioguard.app
- [ ] 添加 ModeManager.swift 到 Core/
- [ ] 添加模式切换 UI（右键菜单 + 设置）
- [ ] 验证 MioIsland 原有功能不受影响
- [ ] `swift build` 通过

**交付物**: MioIsland 功能完整 + 模式切换框架（Eye Guard mode 显示空白占位）

---

## Phase 1: 精灵系统统一 (Day 2-3)

**目标**: 阿普可以在 Notch 和浮动窗口显示

- [ ] 创建 MascotProtocol
- [ ] 移植 EyeGuard Mascot/ 到 Mascot/Apu/
- [ ] 创建 ApuMiniView（30pt Notch 版本）
- [ ] 创建 MascotContainer 统一容器
- [ ] Eye Guard Mode 下 Notch 显示阿普
- [ ] Island Mode 下保持像素猫
- [ ] Dual Mode 下两者并排
- [ ] 移植 SpeechBubbleView
- [ ] 测试：模式切换精灵渲染正确

**交付物**: 两个精灵可在 Notch 中切换显示

---

## Phase 2: 护眼核心功能移植 (Day 4-6)

**目标**: BreakScheduler + ActivityMonitor 在新架构中运行

- [ ] 移植 Scheduling/BreakScheduler.swift → Modules/EyeGuard/
- [ ] 移植 Monitoring/ActivityMonitor.swift
- [ ] 移植 Models/（BreakType, ReminderMode 等）
- [ ] 移植 Protocols/（ActivityMonitoring, SoundPlaying 等）
- [ ] 创建 EyeGuardModule.swift — 模块入口，管理生命周期
- [ ] 接入 ModeManager: Eye Guard 模式时激活 scheduler
- [ ] 移植 NightModeManager
- [ ] 移植 Constants, TimeFormatting
- [ ] 合并 SoundManager（EyeGuard 音效 + MioIsland 音效）
- [ ] 测试：20-20-20 计时正常，锁屏重置正常

**交付物**: 护眼计时 + 监控在后台运行

---

## Phase 3: 休息覆盖层移植 (Day 7-8)

**目标**: 休息提醒 UI 完整工作

- [ ] 移植 Notifications/BreakOverlayView.swift
- [ ] 移植 Notifications/FullScreenOverlayView.swift
- [ ] 移植 Notifications/OverlayWindow.swift
- [ ] 移植 Notifications/MandatoryShakeModifier.swift
- [ ] 移植 NotificationManager.swift
- [ ] 适配：休息覆盖出现时 Notch 显示休息状态
- [ ] 适配：Island 模式下休息时不挡住 Notch 状态查看
- [ ] ESC 键行为保持一致
- [ ] 测试：微休息/大休息/强制休息 UI 正确

**交付物**: 完整的休息提醒流程

---

## Phase 4: 眼保健操 + TTS (Day 9-10)

**目标**: 眼保健操功能完整移植

- [ ] 移植 Exercises/ 全部文件
- [ ] 移植 Audio/SoundManager.swift 的 TTS 部分
- [ ] 移植 Tips/ 全部文件
- [ ] 适配全屏覆盖：覆盖所有屏幕
- [ ] TTS 中文语音引导
- [ ] 休息 → 做操 流程
- [ ] 测试：5 种练习可完整走通

**交付物**: 眼保健操功能完整

---

## Phase 5: Notch 护眼信息面板 (Day 11-12)

**目标**: Eye Guard Mode 下 Notch 展示护眼信息

- [ ] 实现 Eye Guard Notch 展开面板
  - 连续使用时间（大字体）
  - 进度条 + 颜色分级
  - 健康评分
  - 下次休息倒计时
  - Dashboard / 做操 / 设置 按钮
- [ ] 实现 Eye Guard Notch 收起状态
  - 阿普表情 + 简要时间
- [ ] 移植健康评分计算 (HealthScoreCalculator)
- [ ] Notch 收起时进度条颜色随时间变化
- [ ] 测试：Notch 展开/收起正常

**交付物**: Notch 中完整的护眼信息展示

---

## Phase 6: Dashboard + 报告 + 设置 (Day 13-14)

**目标**: 数据展示和配置功能

- [ ] 移植 Dashboard/ → Notch 展开的子页面或独立窗口
- [ ] 移植 Reporting/ (DailyReport, HealthScore)
- [ ] 移植 Persistence/DataPersistenceManager
- [ ] 移植 Analysis/ColorAnalyzer
- [ ] 合并 PreferencesView（MioIsland 设置 + EyeGuard 设置）
- [ ] 移植 AI/InsightGenerator（可选）
- [ ] 测试：历史数据、日报、设置持久化

**交付物**: 完整的数据和设置功能

---

## Phase 7: Dual 模式 + 精细打磨 (Day 15-17)

**目标**: Dual 模式完善 + 整体 UX 打磨

- [ ] Dual Mode Notch 分区布局实现
- [ ] 两个精灵交互动画（互看、一起庆祝等）
- [ ] 模式间事件联动（休息时通知 Island、Claude 完成时通知 EyeGuard）
- [ ] 移除 EyeGuard 原有的 MenuBar（可选保留）
- [ ] 性能优化：两个模块同时运行时的资源占用
- [ ] 暗色/亮色主题适配
- [ ] 本地化（中/英）
- [ ] 完整 E2E 测试
- [ ] 清理死代码

**交付物**: 发布候选版本

---

## Phase 8: 发布 (Day 18)

- [ ] 版本号: v4.0.0
- [ ] 更新 README
- [ ] 更新 Homebrew tap
- [ ] 更新 Landing page
- [ ] GitHub Release

---

## 风险 & 缓解

| 风险 | 影响 | 缓解 |
|------|------|------|
| MioIsland 使用 Actor, EyeGuard 使用 @MainActor class | 架构冲突 | EyeGuard 模块内部保持 @MainActor，只在模块边界适配 Actor |
| 两边 SoundManager 有冲突 | 音频抢占 | 合并为统一 SoundManager，用 priority queue |
| Notch 空间有限 | Dual 模式拥挤 | 自适应布局，session 少时给 EyeGuard 更多空间 |
| EyeGuard 全屏覆盖挡住 Notch | Island 不可见 | 覆盖层在 Notch 区域留空或透明 |
| SPM (EyeGuard) vs Xcode project (MioIsland) | 构建系统不同 | 以 Xcode project 为准，EyeGuard 源码直接加入 |
