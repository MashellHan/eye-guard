# EyeGuard Iteration Log

## Iteration 1 - v0.1 (2026-04-14 23:29 - 23:49)
- **Goal**: Project skeleton, basic timer, menu bar icon
- **PM**: ✅ Product spec, UX wireframes, long-term roadmap, iteration plan
- **Lead**: ✅ Architecture doc, code review (7/10, NEEDS_CHANGES)
- **Dev**: ✅ 12 Swift files, build passes, pushed to GitHub
- **Tester**: ✅ 14/14 tests pass, 7 bugs found, ~25% coverage
- **Status**: ✅ COMPLETED
- **Git**: `8193101` feat: v0.1

---

## Iteration 2 - v0.2 (2026-04-14 23:49 - 00:04)
- **Goal**: Wire pipeline, fix all 7 bugs, add tests, replace print→Logger
- **PM**: ✅ Updated roadmap v2, mascot design spec, competitive analysis
- **Lead**: ✅ v0.2 code review complete
- **Dev**: ✅ Pipeline wired, 7 bugs fixed, 65 tests (from 14), Logger added
- **Tester**: ✅ 65/65 tests pass, coverage ~50%
- **Status**: ✅ COMPLETED
- **Git**: `33f886d` feat: v0.2

---

## Iteration 3 - v0.3 (2026-04-15 00:04 - 00:10)
- **Goal**: App bundle + build script + menu bar countdown
- **PM**: ✅ Updated iteration plan v2 (20+ versions)
- **Lead**: ✅ (bundled with v0.2 review)
- **Dev**: ✅ build-app.sh, Info.plist, LSUIElement=true
- **Tester**: ✅ App launches, menu bar visible, screenshot captured
- **Status**: ✅ COMPLETED
- **Git**: `818e1a4` + `71396f4` feat: v0.3
- **Screenshot**: `.eye-guard/screenshots/v0.3-app-running.png`

---

## Iteration 4 - v0.4 (2026-04-15 00:10 - IN PROGRESS)
- **Goal**: Floating overlay notification window (Tier 2)
- **Dev**: 🔄 OverlayWindowController + BreakOverlayView
- **Status**: 🔄 IN PROGRESS

---

## Target: 20+ iterations
- v0.1-v0.5: Core features
- v0.6-v0.8: Score & Reports
- v0.9-v1.2: Mascot (USER PRIORITY - Q萌护眼精灵)
- v1.3-v2.0+: Advanced features (exercises, LLM, etc.)

## User Requirements
1. Q萌护眼精灵 - cute floating mascot that reminds breaks
2. 眼保健操动画 - eye exercise animations
3. 颜色平衡建议 - color balance suggestions
4. 医学护眼小贴士 - medical tips
5. 深夜提醒 - late night guardian
6. 大模型智能分析 - LLM integration
7. 每版安装测试+截图验证 - install test + screenshot per version
8. 每版一个功能，稳定后再下一个 - one feature per version
