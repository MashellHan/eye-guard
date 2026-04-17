# Regression Matrix

> 每次 Phase 验收和全量 QA 时要跑的回归项。按 Phase 累加。

## 全局基线（每次都跑）

| # | Check | Method |
|---|-------|--------|
| G1 | `swift build` 无 warning | 命令 |
| G2 | `swift test` 全部通过 | 命令 |
| G3 | Apu 精灵在菜单栏出现 | 手动启动 |
| G4 | BreakScheduler 每秒 tick 推进 | 日志 `/tmp/eyeguard-debug.log` 或加 @Test |
| G5 | Dashboard 可打开 | 手动 |
| G6 | Preferences 可打开 | 手动 |
| G7 | 眼保健操可启动 | 手动 |
| G8 | 锁屏恢复后不立即弹窗 | 手动 ⌘⌃Q |

## Phase 1 回归

| # | Check |
|---|-------|
| P1.1 | App 启动 boot 动画（300ms → 1s） |
| P1.2 | Hover 刘海自动展开 |
| P1.3 | Click 刘海展开 |
| P1.4 | 面板外 click 收起 + 穿透 |
| P1.5 | 多屏下只在内建屏显示 |
| P1.6 | 切换 Space 后 Notch 仍在顶 |
| P1.7 | 收起态下菜单栏图标可点 |
| P1.8 | 新增 ≥ 4 个 NotchGeometryTests |

## Phase 2 回归

| # | Check |
|---|-------|
| P2.1 | 收起态色点随时间切换绿→黄→红 |
| P2.2 | 连续用眼每秒 +1 |
| P2.3 | 展开态显示真实 HealthScore |
| P2.4 | 展开态下次休息倒计时正确 |
| P2.5 | "立即休息"按钮可用 |
| P2.6 | 休息中色点蓝 + eye.slash |
| P2.7 | 性能：空闲 CPU < 2% |

## Phase 3 回归

| # | Check |
|---|-------|
| P3.1 | 默认启动 = Apu 模式 |
| P3.2 | Preferences 切换到 Notch → Apu 消失 |
| P3.3 | 再重启保持 Notch |
| P3.4 | 来回切换 10 次无崩溃 |
| P3.5 | 右键菜单切换项可用 |
| P3.6 | 切换动画流畅 |

## Phase 4 回归

| # | Check |
|---|-------|
| P4.1 | 20 分钟到点 Notch pop |
| P4.2 | 打字机动画字符连续 |
| P4.3 | "立即休息" → 眼保健操全屏 |
| P4.4 | "延后 5 分钟" 正确 |
| P4.5 | 休息期间 Notch 收起倒计时 |
| P4.6 | 休息完成 pop 庆祝 |
| P4.7 | Apu 模式下旧 Banner 仍可用 |

## Phase 5 回归

| # | Check |
|---|-------|
| P5.1 | 外接屏显示软件刘海（可开关） |
| P5.2 | Hover 速度 4 档可选 |
| P5.3 | 位置微调 ±30pt |
| P5.4 | 深浅色跟随系统 |
| P5.5 | 启动时间 < 1.5s |
| P5.6 | 空闲内存 < 150 MB |
| P5.7 | 中英本地化齐 |
| P5.8 | 3 小时使用无崩溃 |

## 手动测试的先后顺序

1. 启动 app
2. 观察 Apu 出现（或 Notch boot）
3. 打开 Preferences 切换模式
4. 关闭再启动，验证模式保持
5. 手动触发休息（偏好里加开发者按钮或改配置）
6. 完整走一遍眼保健操
7. 锁屏 → 等 2 分钟 → 解锁，验证不立即弹
8. 多屏：接外接屏，验证只在内建屏显示 Notch
