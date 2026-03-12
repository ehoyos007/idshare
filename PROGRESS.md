# IDShare — Progress Log

## Session: 2026-03-12 (Session 1 — Project Setup & Swift Files)

**Summary:** Created GitHub repo, scaffolded all project docs, and wrote all Swift source files for the iMessage extension. Landing page already live on Vercel. Ready for Xcode project creation.

### What was done

**Project Docs**
1. Created `CONTEXT.md` — full architecture, data flow, key decisions, deep link schemes, gotchas
2. Created `TASKS.md` — complete task list across all 8 phases with test matrix
3. Created `PLAN.md` — phase-by-phase build guide with Xcode setup walkthrough
4. Created `PROGRESS.md` (this file)

**Swift Source Files — IDShareExtension/**
5. `SongData.swift` — data model (title, artist, albumArtURL, trackID, platformLinks, previewURL)
6. `URLValidator.swift` — regex-based validation for Spotify, Apple Music, SoundCloud URLs (synchronous, called on every keystroke)
7. `OdesliService.swift` — async/await URLSession call to api.song.link, full JSON parsing into SongData, error handling (network failure, invalid response, timeout, no platforms found)
8. `ClipboardReader.swift` — reads UIPasteboard on extension open, validates if content matches music URL pattern, returns result
9. `MessageComposer.swift` — downloads album art as UIImage, builds MSMessage with MSMessageTemplateLayout (art + title + artist + IDShare URL), inserts into conversation
10. `MessagesViewController.swift` — full extension UI controller with compact/loading/expanded states, clipboard auto-detection, real-time URL validation, Odesli call orchestration, send action

**Infrastructure**
11. Created `scripts/clu-update.sh` — Clu's session commit workflow
12. Created `.gitignore` — ignores Xcode cruft, build artifacts, DS_Store
13. Initialized git repo + pushed to GitHub (ehoyos007/idshare)

---

## Session: 2026-03-12 (Session 2 — Xcode Build, On-Device Testing & Bug Fixes)

**Summary:** Generated Xcode project via xcodegen, validated URL regex and Odesli API, deployed to physical iPhone, and iterated through several bugs to get a working end-to-end flow. IDShare now sends a universal link that works for all recipients.

### What was done

**Phase 1 — Xcode Project Setup**
1. Installed `xcodegen`, created `project.yml` with both targets (IDShare app + IDShareExtension)
2. Created `IDShareApp.swift` (@main entry point), `Assets.xcassets` for both targets
3. Created `Info.plist` for extension with NSExtensionPointIdentifier + CFBundleDisplayName
4. Configured code signing (team PKXQTDC76Q, automatic provisioning)
5. Fixed `.tertiaryLabel` color compatibility in ContentView.swift
6. Both targets build with zero compile errors

**Phase 2+3 — URL Validation & Odesli API Testing**
7. Wrote `scripts/test_validation.swift` — 20 URL regex tests (all passed)
8. Tested Odesli API with real Spotify, Apple Music, SoundCloud URLs
9. Confirmed cross-platform gaps (Odesli doesn't always have all 3 platforms)

**Phase 4+5+6 — Extension UI, Message Composition & On-Device Testing**
10. Deployed to iPhone 17 Pro Max via `xcodebuild` + `devicectl`
11. Fixed paste: replaced custom button with `UIPasteControl` (Apple's system paste control that bypasses iOS 16+ clipboard restrictions)
12. Fixed clipboard: `ClipboardReader` now checks `UIPasteboard.general.url` first (Spotify copies as URL type, not string)
13. Fixed landing page "Track Not Found": strip Odesli entity prefix (`SPOTIFY_SONG::`) from track ID in `SongData.platformID`
14. Fixed "Cannot Connect" for recipients without extension: switched from `MSMessage` (requires extension on both sides) to plain text URL via `conversation.insertText()` — iMessage auto-generates rich link preview from OG tags
15. Tested end-to-end: Enzo → Daniel (no IDShare), link opens in Safari, landing page shows song with platform buttons

### Key architectural decision
MSMessage with MSMessageTemplateLayout creates rich bubbles but **requires the extension on both sides** (or an App Store listing for fallback). Since IDShare is sideloaded, we switched to sending the landing page URL as plain text. iMessage auto-generates a rich link preview from the page's OG meta tags, and the link works for ALL recipients.

### Where we left off
- Phases 1-6 complete — IDShare is functional end-to-end
- Remaining test matrix items: Apple Music links, SoundCloud links, edge cases
- Phase 7 (Share Sheet) and Phase 8 (Audio Preview) are future work
