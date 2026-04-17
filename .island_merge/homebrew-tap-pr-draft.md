# Homebrew Tap PR — v4.0.0 Island Merge

> Draft. Replace `<SHA256>` once the v4.0.0 tag is pushed and the
> `.tar.gz` is published on GitHub Releases.

## Target

- Repo: `MashellHan/homebrew-eye-guard` (or equivalent tap)
- File: `Casks/eye-guard.rb` (or `Formula/eye-guard.rb` depending on
  whether Eye Guard ships as a signed `.app` cask or a source-built
  SPM formula)

## Suggested Cask diff

```ruby
cask "eye-guard" do
  version "4.0.0"
  sha256 "<SHA256>"

  url "https://github.com/MashellHan/eye-guard/releases/download/v#{version}/EyeGuard-#{version}.dmg"
  name "Eye Guard"
  desc "Medical-grade eye health guardian for macOS, now with Dynamic Notch mode"
  homepage "https://github.com/MashellHan/eye-guard"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates false
  depends_on macos: ">= :sonoma"

  app "EyeGuard.app"

  zap trash: [
    "~/Library/Application Support/EyeGuard",
    "~/Library/Preferences/com.eyeguard.app.plist",
    "~/Library/Caches/com.eyeguard.app",
  ]
end
```

## PR title

`eye-guard: 4.0.0 (Island Merge — Dynamic Notch mode)`

## PR body

```markdown
This bumps Eye Guard to 4.0.0.

Highlights (full notes in the GitHub release):
- New Dynamic Notch display mode (MioIsland-derived UX)
- Menu-bar picker to switch between Apu Mascot and Notch modes
- Notch preferences: horizontal offset, hover speed, external-display support
- 233 passing tests, no warnings, macOS 14+ Sonoma required

Verification:
- [x] `brew install --cask eye-guard` succeeds on clean macOS 14
- [x] `brew audit --cask eye-guard` passes
- [x] Application launches and both display modes work

Previous release: 3.x (Apu Mascot only)
```

## Pre-publish checklist (for maintainer)

- [ ] Tag `v4.0.0` on `main` with the final CHANGELOG entry
- [ ] Build signed + notarized `EyeGuard-4.0.0.dmg`
- [ ] Upload to GitHub Releases
- [ ] Compute SHA256 and substitute into the cask
- [ ] Push cask PR to the homebrew tap
- [ ] Smoke-test `brew install --cask MashellHan/eye-guard/eye-guard@4` if
      multiple versions are hosted simultaneously
