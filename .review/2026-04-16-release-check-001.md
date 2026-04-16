# Release Check — 2026-04-16 14:03

**Result:** ✅ Released v3.1

## Changes Since v3.0 (22 commits)

| Type | Count | Key Items |
|------|-------|-----------|
| feat | 8 | 连续屏幕时间显示, TTS语音引导, 休息预警, ESC关闭, 摇晃动画, 闪烁警告 |
| fix | 11 | 弹窗重复触发, 倒计时显示, TTS重叠, 偏好设置, TTS队列清理 |
| refactor | 2 | MandatoryShakeModifier提取, SoundPlaying协议 |
| ci | 1 | release workflow + packaging scripts |

## Release Details

- **Version:** v3.1 (minor bump — new features present)
- **Tag:** https://github.com/MashellHan/eye-guard/releases/tag/v3.1
- **DMG SHA256:** `38e3e5579813d38515ea505879b9278812e1b9b1d4c45ef15cdf8fa7dca31231`
- **Homebrew tap:** updated to v3.1

## Install

```bash
brew tap MashellHan/tap && brew install --cask eye-guard
```
