# EyeGuard × MioIsland 合并项目

## 愿景

将 EyeGuard（护眼精灵阿普）与 MioIsland（Notch 灵动岛 AI 监控）合并为一个统一的 macOS 桌面伴侣应用。两个模式可自由切换：

- **🛡 Eye Guard Mode** — 护眼模式，阿普在屏幕角落/Notch 陪伴，提醒休息、做操
- **🏝 Island Mode** — 灵动岛模式，在 Notch 监控 Claude Code 会话状态

## 文档目录

| # | 文档 | 内容 | 状态 |
|---|------|------|------|
| 1 | [00-vision.md](00-vision.md) | 本文档，总体愿景 | ✅ |
| 2 | [01-architecture.md](01-architecture.md) | 合并后架构设计 | ✅ |
| 3 | [02-mode-system.md](02-mode-system.md) | 双模式切换系统设计 | ✅ |
| 4 | [03-mascot-unification.md](03-mascot-unification.md) | 精灵系统统一（阿普 + 像素猫） | ✅ |
| 5 | [04-migration-plan.md](04-migration-plan.md) | 分阶段迁移计划 | ✅ |
| 6 | [05-task-list.md](05-task-list.md) | 开发任务清单 | ✅ |
| 7 | [06-review-log.md](06-review-log.md) | Review 记录 | 🔄 持续更新 |
| 8 | [07-phase2-spec.md](07-phase2-spec.md) | Phase 2 护眼核心移植详细规格 | ✅ |
| 9 | [08-phase5-spec.md](08-phase5-spec.md) | Phase 5 Notch 护眼面板详细规格 | ✅ |
| 10 | [09-phase3-spec.md](09-phase3-spec.md) | Phase 3 休息覆盖层详细规格 | ✅ |
| 11 | [10-phase4-spec.md](10-phase4-spec.md) | Phase 4 眼保健操+TTS+Sound 详细规格 | ✅ |

## 关键决策

1. **以 MioIsland 为底座** — 它的 Notch 窗口管理、插件系统、Actor 架构更成熟
2. **EyeGuard 作为内置模块集成** — 护眼功能作为一等公民模块，不是插件
3. **共享精灵系统** — 统一的 mascot 渲染层，两个模式各自的表情/动画
4. **保留两个独立运行能力** — 用户可以只用一个模式
