# EyeGuard Swift 风格指南

> 基于 [Apple Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) + 项目实际惯例。
> reviewer 会按此评审。

## 命名

### 类型
- `UpperCamelCase`
- 名词或名词短语：`BreakScheduler`、`HealthScoreBreakdown`
- View 后缀 `View`：`MenuBarView`
- ViewController/WindowController 后缀完整保留：`MascotWindowController`
- Manager / Coordinator / Provider / Service 后缀根据职责选

### 函数 / 方法
- `lowerCamelCase`
- 第一个参数名应让调用点像英语：
  - ✅ `scheduler.start(at: date)` → 调用点 `start(at: date)` 自然
  - ❌ `scheduler.startAt(date)` → 别用这种 ObjC 风格

### 变量 / 常量
- `lowerCamelCase`
- 布尔用 `is` / `has` / `should` 前缀：`isPaused`、`hasActiveSession`、`shouldShowOverlay`
- 私有用 `private` 显式标注，不靠 `_` 前缀

### 缩写
- 避免缩写：`HealthScore` 不写 `HSc`
- 业界公认的缩写大写：`URL`、`JSON`、`AI`、`UI`、`HTML`
- 不要：`bg`、`btn`、`cfg`（写全 `background`、`button`、`config`）

## 颜色

### 硬规则
- ❌ 禁止硬编码颜色：`Color.white`、`Color(red: 0.3, ...)`
- ✅ 系统色优先：`Color(NSColor.windowBackgroundColor)`、`.labelColor`、`.controlAccentColor`
- ✅ 应用语义色：自定义集中放在 `Sources/Utils/Colors.swift`（如不存在，建立）

### Colors.swift 风格
```swift
import SwiftUI
import AppKit

enum AppColors {
    /// 菜单栏 popover 背景，跟随系统外观
    static let popoverBackground = Color(NSColor.windowBackgroundColor)

    /// 健康分高分（≥80），mint green
    static let scoreHigh = Color(NSColor.systemGreen)

    /// 健康分中等（50-79）
    static let scoreMid = Color(NSColor.systemYellow)

    /// 健康分低（30-49）
    static let scoreLow = Color(NSColor.systemOrange)

    /// 健康分危险（<30）
    static let scoreCritical = Color(NSColor.systemRed)
}
```

### 状态色阈值（固定）
- 健康分 ≥ 80 → green
- 50–79 → yellow
- 30–49 → orange
- < 30 → red

screenTimeColor:
- < 10 min → green
- 10–15 min → yellow
- 15–20 min → orange
- ≥ 20 min → red

## 字体

- 用 SwiftUI 语义字体：`.font(.body)`、`.caption`、`.headline`、`.title2`
- 不写死 size：~~`.font(.system(size: 14))`~~
- 中文字符场景：`.font(.system(.body))`（让系统选 SF Pro + PingFang）
- 等宽（如计时器）：`.font(.system(.title2, design: .monospaced))`

## SwiftUI

### body 性能
- ❌ `body` 里跑昂贵计算（解析 JSON、过滤大集合）
- ✅ 抽到 `private var computed: X { ... }` + `@State` 缓存
- ✅ 大列表用 `LazyVStack` / `LazyHStack`

### 状态管理
- 单 view 局部状态 → `@State`
- 跨 view 共享 → `@Observable` 类 + `@Bindable`（Swift 6 新 macro）
- 旧 `@StateObject` / `@ObservedObject` 仅在维护旧代码时保留

### 视图拆分
- 一个 `body` 内 ≥ 5 个 section → 拆 private computed view
- 一个文件 ≥ 3 个独立 view → 拆 file

## 并发（Swift 6 strict concurrency）

### @MainActor
所有 SwiftUI View 默认 `@MainActor`，但其闭包/Task 需注意：

```swift
// ❌ 错：Task 默认非 MainActor 上下文
Button("X") {
    Task {
        let data = await fetch()
        viewModel.data = data  // ⚠️ data race warning
    }
}

// ✅ 对：显式标
Button("X") {
    Task { @MainActor in
        let data = await fetch()
        viewModel.data = data
    }
}
```

### Sendable
- 跨 actor 边界传递的类型必须 `Sendable`
- struct + 全部成员 Sendable → 自动 Sendable
- class 默认不 Sendable，要么改 struct，要么 `final class ... : Sendable` 且全部成员 immutable / actor-isolated

### 闭包捕获 self
```swift
// ❌
Task {
    self.doWork()  // 强引用循环
}

// ✅
Task { [weak self] in
    self?.doWork()
}
```

## 错误处理

- 业务错误用 `throws` + 自定义 `Error` 枚举
- 非预期错误用 `assertionFailure` (debug) + `Log.app.error` (release)
- ❌ 禁止 `try!`（除非 unit test 内 + 100% 可控）
- ❌ 禁止 `fatalError(...)` 在 release path（仅初始化、不可恢复时用）

## 日志

```swift
import os

private let logger = Logger(subsystem: "com.eyeguard", category: "scheduling")

logger.debug("session started")
logger.info("user took break, type=\(breakType.rawValue, privacy: .public)")
logger.error("failed to load: \(error.localizedDescription, privacy: .public)")
```

- 涉及 PII / 用户数据要标 `privacy: .private`
- 大量 hot path 日志用 `.debug` 级别（release 自动过滤）

## 注释

### Doc comment
公开 API 必须 `///`：
```swift
/// 计算今日的健康分（0-100），结合休息合规、连续使用、屏幕时间、休息质量。
///
/// - Returns: 0-100 的整数分数
/// - Note: 调用频率应低于每秒一次（内部有缓存）
func calculateScore() -> Int { ... }
```

### 解释「为什么」不写「做什么」
```swift
// ❌
// 设置背景色为白色
view.backgroundColor = .white

// ✅
// 用 NSColor 系统色而非 SwiftUI 透明 vibrancy，避免浅色模式下文字对比度不足（WCAG AA 4.5:1）
view.backgroundColor = NSColor.windowBackgroundColor
```

### TODO
TODO 必须带：
- 作者名
- issue/ticket 引用（如有）
- 截止条件
```swift
// TODO(mengxiong, #42): 等 ScreenCaptureKit 完全替代 CGWindowList 后删除此分支
```

## 测试

- 用 Swift Testing 框架（`@Test`、`#expect`）
- 测试文件名：`<TypeName>Tests.swift`
- 测试函数命名：`test<行为>_<条件>_<预期>`
  - 例：`testCalculateScore_AfterMissedBreak_ReturnsLowerScore`
- 一个测试只验一件事
- 不 mock 时间用真实 `Date`，mock 时间用 protocol 注入（参见 `Sources/Protocols/Clock.swift`）
