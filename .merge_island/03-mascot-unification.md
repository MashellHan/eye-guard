# 精灵系统统一设计

## 当前状况

### 阿普 (EyeGuard)
- **渲染**: SwiftUI 手绘（圆形身体 + 眼睛 + 表情），渐变色
- **大小**: ~120x120pt 浮动窗口
- **位置**: 屏幕右下角，peek mode 隐藏到边缘
- **动画**: 弹跳、呼吸、摇晃、跟随鼠标瞳孔
- **表情**: 开心/困/担忧/庆祝/睡觉，根据健康评分变化
- **交互**: 点击打开 popover 面板，右键菜单
- **语音**: TTS 播报（AVSpeechSynthesizer 中文）

### 像素猫 (MioIsland)
- **渲染**: 13×11 像素网格，带霓虹闪烁效果
- **大小**: ~30x30pt 嵌入 Notch
- **位置**: Notch 左侧
- **动画**: idle/thinking/blink 帧动画，霓虹 sine wave
- **表情**: 根据 Claude session 状态变化
- **交互**: 纯展示，不可独立交互

## 统一方案

### MascotProtocol — 精灵统一协议

```swift
protocol MascotRenderable: View {
    /// 精灵唯一标识
    var mascotId: String { get }
    
    /// 当前表情/状态
    var expression: MascotExpression { get set }
    
    /// 精灵尺寸（自适应容器）
    var preferredSize: CGSize { get }
    
    /// 是否支持在 Notch 内渲染（小尺寸）
    var supportsNotchMode: Bool { get }
}

enum MascotExpression: String, CaseIterable {
    // 共享表情
    case idle          // 默认
    case happy         // 开心
    case concerned     // 担忧
    case sleeping      // 睡觉
    case celebrating   // 庆祝
    
    // EyeGuard 专属
    case tired         // 疲劳提醒
    case exercising    // 做操中
    case encouraging   // 鼓励
    
    // Island 专属
    case thinking      // Claude 思考中
    case waiting       // 等待输入
    case alert         // 需要注意
}
```

### 阿普适配 Notch

阿普需要一个 mini 版本用于 Notch 显示（30x30pt）：

```
Full Size (120pt)     Notch Mini (30pt)
                      
   ╭──────╮           ╭──╮
  │ ◉  ◉ │          │◉◉│
  │  ◡   │          │◡ │
  │      │          ╰──╯
   ╰──────╯
```

- 保留核心特征：圆形 + 两只眼睛 + 嘴巴
- 去掉渐变细节，改为纯色 + 轮廓
- 瞳孔跟随仍然保留（缩小版）

### 像素猫适配浮动窗口

像素猫可以放大到 80x80pt 用于浮动模式：

- 保持像素风格，每个像素放大
- 霓虹效果在大尺寸更酷

### 精灵容器

```swift
struct MascotContainer<M: MascotRenderable>: View {
    let mascot: M
    let mode: MascotDisplayMode
    
    enum MascotDisplayMode {
        case notch       // 嵌入 Notch，小尺寸
        case floating    // 浮动窗口，大尺寸
        case overlay     // 全屏覆盖上的，中等尺寸
    }
    
    var body: some View {
        mascot
            .frame(
                width: size.width,
                height: size.height
            )
    }
    
    private var size: CGSize {
        switch mode {
        case .notch: return CGSize(width: 30, height: 30)
        case .floating: return mascot.preferredSize
        case .overlay: return CGSize(width: 80, height: 80)
        }
    }
}
```

## 精灵切换效果

### 模式切换时

```swift
// Notch 内切换
withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
    // 当前精灵向下滑出
    // 新精灵从上弹入
}
```

### 特殊交互

| 场景 | 效果 |
|------|------|
| Dual 模式 | 阿普在左，猫在右，偶尔互相看 |
| 休息提醒 | 阿普跳出来挡住猫，显示"该休息了" |
| Claude 完成任务 | 猫庆祝，如果护眼模式开着阿普也一起庆祝 |
| 长时间使用 | 阿普表情变担忧，猫的霓虹变暗 |

## 语气系统 (Speech)

统一 TTS 管理，两个精灵共享 SoundManager：

```swift
protocol MascotSpeaker {
    func speak(_ text: String, voice: MascotVoice)
}

enum MascotVoice {
    case apu    // 温柔中文女声
    case cat    // 可爱音效（不说话，只有 sfx）
}
```

## 文件清单

| 新文件 | 来源 | 说明 |
|--------|------|------|
| `Mascot/MascotProtocol.swift` | NEW | 统一协议 |
| `Mascot/MascotContainer.swift` | NEW | 统一容器 |
| `Mascot/Apu/ApuView.swift` | EyeGuard MascotView | 阿普渲染 |
| `Mascot/Apu/ApuMiniView.swift` | NEW | Notch 迷你版 |
| `Mascot/Apu/ApuAnimations.swift` | EyeGuard MascotAnimations | 动画 |
| `Mascot/Apu/ApuExpressions.swift` | EyeGuard MascotState | 表情映射 |
| `Mascot/PixelCat/PixelCatView.swift` | MioIsland PixelCharacterView | 像素猫 |
| `Mascot/PixelCat/NeonPixelCatView.swift` | MioIsland | 霓虹版 |
| `Mascot/SpeechBubbleView.swift` | EyeGuard | 对话气泡 |
