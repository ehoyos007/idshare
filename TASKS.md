# IDShare — Task List

## ✅ Done
- [x] Architecture design + key decisions finalized
- [x] Landing page live at idshare.vercel.app
- [x] Odesli API response structure verified
- [x] Build plan document written (IDShare_Revised_Build_Plan.docx)
- [x] GitHub repo created (ehoyos007/idshare)
- [x] Project docs scaffolded (CONTEXT.md, TASKS.md, PLAN.md, PROGRESS.md)
- [x] All Swift source files written (OdesliService, URLValidator, MessageComposer, ClipboardReader, MessagesViewController, SongData)
- [x] Xcode project created via xcodegen (project.yml + IDShare.xcodeproj)
- [x] IDShareApp.swift entry point + Assets.xcassets for both targets
- [x] Info.plist for iMessage extension (NSExtensionPointIdentifier configured)
- [x] WebKit.framework added to IDShareExtension
- [x] Code signing configured (team PKXQTDC76Q, automatic provisioning)
- [x] Both targets build with zero compile errors
- [x] Fixed .tertiaryLabel color compatibility in ContentView.swift

## ✅ Phase 1 — Xcode Project Setup ✅ COMPLETE
- [x] Create Xcode project with both targets (IDShare app + IDShareExtension) via xcodegen
- [x] Configure iMessage Extension with correct bundle ID (`com.enzohoyos.idshare.extension`)
- [x] Add `WebKit.framework` to IDShareExtension target
- [x] All Swift source files included in targets
- [x] Set up signing with Apple Developer account
- [x] Build to verify zero compile errors

## 🔲 Phase 2 — URL Validation (Swift — URLValidator.swift)
- [x] `URLValidator.swift` written
- [ ] Test regex against real URLs from all 3 platforms (copy from Spotify, Apple Music, SoundCloud apps)
- [ ] Verify edge cases: short links, URLs with tracking params, mobile vs desktop URLs

## 🔲 Phase 3 — Odesli Integration (Swift — OdesliService.swift)
- [x] `OdesliService.swift` written
- [ ] Test OdesliService in a Swift Playground with a real Spotify URL before wiring into extension
- [ ] Verify SongData model parses correctly (title, artist, albumArtURL, trackID, platformLinks)
- [ ] Test error handling: network failure, invalid URL, API timeout

## 🔲 Phase 4 — Extension UI (Swift — MessagesViewController.swift)
- [x] `MessagesViewController.swift` written
- [ ] Connect ClipboardReader in viewDidLoad — verify auto-population works
- [ ] Verify compact → expanded animation is smooth on device
- [ ] Test spinner + disabled state during Odesli call
- [ ] Test error state (invalid URL, API failure) — inline message shows correctly

## 🔲 Phase 5 — Message Composition (Swift — MessageComposer.swift)
- [x] `MessageComposer.swift` written
- [ ] Test album art download timing — verify image is ready before send
- [ ] Verify MSMessage rich bubble renders correctly in iMessage thread
- [ ] Test with a song that has no album art (edge case)

## 🔲 Phase 6 — On-Device Testing
- [ ] Connect physical iPhone to Mac via USB
- [ ] Select iPhone as run destination in Xcode
- [ ] Build + install IDShareExtension via Xcode
- [ ] Open iMessage → find IDShare in app drawer (may need to tap "More" to enable)
- [ ] Test full flow: open extension → paste Spotify link → see preview → send → tap bubble → landing page → platform button

### Test Matrix
- [ ] Spotify link → all 3 platform buttons work
- [ ] Apple Music link → all 3 platform buttons work
- [ ] SoundCloud link → all 3 platform buttons work
- [ ] Very new release → search fallback fires
- [ ] Obscure SoundCloud track → search fallback fires
- [ ] Clipboard auto-detection → pre-populates correctly
- [ ] Invalid URL pasted → error shown, send disabled
- [ ] API timeout → error shown, retry option works
- [ ] Recipient taps bubble → lands on correct idshare.vercel.app/s/[trackID] page

## 🔲 Phase 7 (Future) — Share Sheet Extension
- [ ] Add Share Sheet target to Xcode project
- [ ] Reuse OdesliService + MessageComposer
- [ ] Test sharing directly from Spotify/Apple Music apps

## 🔲 Phase 8 (Future) — Audio Preview
- [ ] Add AVPlayer to extension UI
- [ ] Wire up 30-second preview URL from Odesli response
- [ ] Test memory usage — stay under ~120MB

## Bugs / Issues
(none yet)
