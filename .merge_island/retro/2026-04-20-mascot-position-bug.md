# Retro: 阿普精灵定位错误 + 几何应用失效

- **日期**: 2026-04-20
- **触发**: 用户截图反馈阿普精灵出现在屏幕**最顶端中间偏左**，而非设计中的「Notch 左侧探头 / 屏幕右下角 peek」。
- **影响范围**: 所有连接外接显示器的用户；所有 v3.x Notch 自定义功能用户（几何调节实际无效）。
- **严重度**: CRITICAL（视觉错位 + 用户配置全部失效，但无数据损坏）。
- **状态**: ✅ 已修复 + 补测试 + prevention plan 落地

---

## 1. 现象

| 期望 | 实际 |
|------|------|
| 阿普 peek 在屏幕右下角，Notch 左侧探头 | 阿普悬浮在屏幕顶端中间偏左 |
| `IslandNotchCustomizationStore` 调宽度/水平偏移立即生效 | 用户拖滑块无任何视觉变化 |

---

## 2. 根因（确认）

### Bug A — 多屏 `NSScreen.main` 坐标系混淆
- **文件**: `EyeGuard/Sources/Mascot/MascotWindowController.swift:562–577`（`positionBottomRight`），563/583/612/680/786 行 8 处直接 `NSScreen.main`
- **原因**: 当外接显示器成为 main 屏，`visibleFrame.origin` 不再是 `(0,0)`。`x = visibleFrame.maxX - 140` 在内置屏坐标系下落到屏幕中上区——正好是截图的位置。
- **对照**: `IslandNotchModule.swift:49–54` 用的是 `NSScreen.builtin ?? NSScreen.main`，两个模块策略不一致。

### Bug B — 几何计算被显式丢弃
- **文件**: `EyeGuard/Sources/Notch/Framework/Window/IslandNotchWindowController.swift:199–227`
- **代码**:
  ```swift
  let finalX = screenFrame.origin.x + baseX + clampedOffset
  _ = (finalX, runtimeWidth)            // ← 算完直接扔
  ...
  window.animator().setFrame(window.frame, display: true)  // ← 用旧 frame 覆盖自己
  ```
- **影响**: 整个 `applyGeometryFromStore()` 是空操作，所有自定义几何全部无效。

### Bug C — 屏幕拓扑变化无响应
- 没有任何代码订阅 `NSApplication.didChangeScreenParametersNotification`。
- 拔掉外接屏后阿普位置不会重算。

---

## 3. 5 Whys

```
现象: 阿普跑到屏幕顶端中间偏左

Why 1: 为什么位置错了？
  → positionBottomRight 算出的坐标在错误的屏幕坐标系下。

Why 2: 为什么坐标系错了？
  → 用了 NSScreen.main，外接屏成为 main 时它的 visibleFrame.origin ≠ (0,0)。

Why 3: 为什么没人发现 NSScreen.main 在多屏场景的歧义？
  → 没有任何多屏测试。Tests/ 下 14 个测试文件，零覆盖 NSWindow frame 实际坐标。
    NotchGeometryTests 只测纯函数 (CGRect 计算)，从不验证窗口最终位置。

Why 4: 为什么没写多屏测试？
  → Phase 5 (Notch 护眼面板) 的 spec 里写了「Notch 中点对齐」但没写「外接屏作为 main 时的行为」。
    需求里没有 = 不会写测试 = 不会发现。
    更深一层：这个项目从合并 MioIsland 起就没有「视觉/定位」类回归测试这一档，
    只有逻辑和数据测试。

Why 5: 为什么 review 也没拦住 Bug B 那个 `_ = (finalX, runtimeWidth)`？
  → review_log/ 之前几轮都聚焦在 Actor 隔离、UserDefaults、TTS 等模块，
    Notch Window 层只过了功能 review，没人 line-by-line 看 setFrame 是否使用了局部变量。
    根因是 review checklist 没有「dead-locals 扫描」「setFrame 必须使用最新算出的 frame」这两条。
    更深：缺少 SwiftLint 规则 unused_variable + warn-on-discard，编译器警告也被静音。
```

**根本原因总结（系统层）**:

> 项目把「视觉/窗口定位」当作不需要测试的 cosmetic 层，导致一类 bug（坐标系、屏幕拓扑、frame 应用）完全失去自动化护栏；同时 review checklist 没有覆盖「计算结果是否被使用」这一通用质量项。

---

## 4. 修复计划

| # | 动作 | 文件 | 验收 |
|---|------|------|------|
| F1 | `MascotWindowController` 引入 `targetScreen` 计算属性 = `NSScreen.builtin ?? NSScreen.main`，全部 `NSScreen.main` 调用替换 | MascotWindowController.swift | 单元测试：注入 mock screens，断言外接屏为 main 时 frame 仍在内置屏可见区 |
| F2 | `applyGeometryFromStore` 真正用 `finalX/runtimeWidth` 构造新 frame 并 `setFrame` | IslandNotchWindowController.swift:199–227 | 单元测试：调用前后 `window.frame.origin.x` / `window.frame.size.width` 必须等于算出的值 |
| F3 | 订阅 `NSApplication.didChangeScreenParametersNotification`，触发 `repositionAll()` | MascotWindowController + IslandNotchModule | 集成测试：post 通知 → 断言两个 controller 的 reposition 被调用 |
| F4 | 删除 `_ = (finalX, runtimeWidth)` 这种「故意丢弃局部变量」模式；加 SwiftLint 规则 `unused_declaration` warning→error | .swiftlint.yml | swiftlint 在 CI 上 fail-on-warning |
| F5 | `NSScreen+Builtin` 添加测试用 `screensProvider` 注入点（protocol-based DI） | NSScreen+Notch.swift | 测试可 mock 屏幕拓扑 |

---

## 5. Prevention Plan

### 5.1 流程层

| 项 | 内容 | 落地位置 |
|----|------|---------|
| P1 | 「视觉/定位」加入测试矩阵：每个 NSWindow 子类必须有 frame 断言测试 | `.merge_island/testing-matrix.md`（新建） |
| P2 | Phase spec 模板增加「多屏 / 屏幕拓扑变化」章节 | `.merge_island/_spec-template.md` |
| P3 | Code review checklist 增加：① 局部变量是否被使用 ② setFrame 是否用了最新计算 ③ NSScreen.main 是否合法 | `.merge_island/review-checklist.md` |
| P4 | retro 文档归档到 `.merge_island/retro/`，每月扫读一次防止重犯 | 本目录 |

### 5.2 工具层

| 项 | 内容 |
|----|------|
| T1 | SwiftLint 规则启用：`unused_declaration`, `unused_closure_parameter`, `redundant_discardable_let` 全部 error |
| T2 | 自定义 SwiftLint 规则 `no_nsscreen_main`：禁止裸用 `NSScreen.main`，必须经过 helper |
| T3 | CI 增加 `swift test --enable-code-coverage` 门禁，Mascot/Notch 模块覆盖率 ≥ 80% |
| T4 | PostToolUse hook：保存 `.swift` 后自动跑 swiftlint，warning 立即提示 |

### 5.3 测试层（本次必补）

```
Tests/MascotTests/
  MascotWindowPositionTests.swift          ← 新增
    - test_positionBottomRight_externalMainScreen_clampsToBuiltin
    - test_peekMode_clampsBelowBuiltinScreen
    - test_screenParametersChange_repositionsWindow

Tests/NotchTests/
  IslandNotchGeometryApplicationTests.swift ← 新增
    - test_applyGeometryFromStore_setsFrameToFinalX
    - test_applyGeometryFromStore_appliesRuntimeWidth
    - test_externalDisplay_originX_offsetIncluded
```

### 5.4 文档层

| 项 | 内容 |
|----|------|
| D1 | `.merge_island/03-mascot-unification.md` 增补「多屏行为契约」 |
| D2 | 本 retro 文档进 `.merge_island/README.md` 引用列表 |
| D3 | 写一份 `MULTI_SCREEN_GUIDE.md` 给后续贡献者 |

---

## 6. 时间线

| 时间 | 事件 |
|------|------|
| 2026-04-20 21:45 | 用户截图反馈 |
| 2026-04-20 22:00 | code-reviewer 完成根因分析 |
| 2026-04-20 22:05 | 本 retro 文档创建 |
| 2026-04-20 22:10 | TDD RED：补失败测试 |
| 2026-04-20 22:30 | GREEN：F1+F2+F3 修复 |
| 2026-04-20 22:50 | swiftlint/CI 钩子落地 |
| 2026-04-20 23:00 | commit + push + 文档更新 |

---

## 7. 行动项 owner

| ID | 描述 | Owner | 截止 |
|----|------|-------|------|
| F1–F5 | 代码修复 | claude (本会话) | 当日 |
| P1–P4 | 流程文档 | claude (本会话) | 当日 |
| T1–T4 | 工具链 | claude → 用户 review | 当日 |
| D1–D3 | 文档补全 | claude (本会话) | 当日 |

---

## 8. 教训卡（贴在 .merge_island/README.md 顶部）

> ⚠️ **不要在 macOS 多屏窗口代码里裸用 `NSScreen.main`**——它指向「键盘焦点所在屏」，外接显示器接管后会把内置屏的窗口算到错误坐标系。统一用 `NSScreen.builtin ?? NSScreen.main`，并且**算出的局部变量必须真的被 `setFrame` 使用**。这两条加测试。
