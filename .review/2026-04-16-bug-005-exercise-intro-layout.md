# Bug Report: 眼保健操 Intro 页面布局空白过大 (BUG-005)

**Date:** 2026-04-16
**Severity:** P2
**Status:** Root Cause Confirmed

---

## 现象

眼保健操 intro 页面中，练习列表和底部按钮之间存在大面积空白，视觉效果差。

## 根因

`ExerciseSessionView.swift` intro view（line 159）使用了 `Spacer()` 将内容和底部按钮分隔。窗口固定高度 640pt，但实际内容（mascot + 标题 + 练习列表）只占约 350pt，`Spacer()` 吃掉了剩余 ~290pt 空间。

```swift
// ExerciseSessionView.swift, introView (line 121-187)
VStack(spacing: 16) {
    // mascot + title (~150pt)
    // session info + exercise list (~150pt)
    
    Spacer()  // ← 约 290pt 空白
    
    // buttons (~100pt)
}
```

## 修复方案

将 `Spacer()` 改为 `Spacer(minLength: 20)`，或者更好的方式是去掉 `Spacer()` 改用 `.frame(maxHeight: .infinity, alignment: .bottom)` 放在按钮区域上，限制最大空白：

```swift
// 方案 A（最简单）：限制 Spacer 最小高度并让内容居中
VStack(spacing: 16) {
    // mascot + title
    // session info + exercise list
    
    Spacer(minLength: 20)
        .frame(maxHeight: 60)  // 限制空白最多 60pt
    
    // buttons
}

// 方案 B（推荐）：去掉 Spacer，按钮固定在底部
VStack(spacing: 0) {
    VStack(spacing: 16) {
        // mascot + title
        // session info + exercise list
    }
    .padding(.top, 16)
    
    Spacer()
    
    // buttons
}
.frame(height: 640)
```

实际上方案 B 和当前代码效果相同。**真正的问题可能是窗口高度 640 太大了。** 建议：

### 方案 C（推荐）：缩小窗口高度适配内容

将 intro 阶段的窗口高度从 640 改为内容实际需要的高度（约 480-520），或者让窗口高度根据内容自适应。

## 变更文件

| File | Change |
|------|--------|
| `Sources/Exercises/ExerciseSessionView.swift` | 调整 intro 布局间距 |
| `Sources/Mascot/MascotWindowController.swift` | 可选：调整窗口高度 |
