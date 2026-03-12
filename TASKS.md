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
- [x] Info.plist for iMessage extension (NSExtensionPointIdentifier + CFBundleDisplayName)
- [x] WebKit.framework added to IDShareExtension
- [x] Code signing configured (team PKXQTDC76Q, automatic provisioning)
- [x] Both targets build with zero compile errors
- [x] Fixed .tertiaryLabel color compatibility in ContentView.swift
- [x] UIPasteControl for reliable clipboard access on iOS 16+
- [x] Switched from MSMessage to plain text URL for universal recipient compatibility
- [x] Landing page URL strips Odesli prefix (SPOTIFY_SONG:: → just the ID)
- [x] ClipboardReader checks both URL and string pasteboard types
- [x] End-to-end tested: Enzo → Daniel, link opens in Safari, landing page works

## ✅ Phase 1 — Xcode Project Setup ✅ COMPLETE
- [x] Create Xcode project with both targets (IDShare app + IDShareExtension) via xcodegen
- [x] Configure iMessage Extension with correct bundle ID (`com.enzohoyos.idshare.extension`)
- [x] Add `WebKit.framework` to IDShareExtension target
- [x] All Swift source files included in targets
- [x] Set up signing with Apple Developer account
- [x] Build to verify zero compile errors

## ✅ Phase 2 — URL Validation ✅ COMPLETE
- [x] `URLValidator.swift` written
- [x] Tested regex against 20 URLs: Spotify (standard, short, deep link), Apple Music (album, song, geo, no-region), SoundCloud (standard, www, short link)
- [x] Verified edge cases: short links, tracking params (?si=), query params, negative cases (albums, playlists, sets, YouTube, plain text)
- [x] 20/20 tests passed — all patterns correct

## ✅ Phase 3 — Odesli Integration ✅ COMPLETE
- [x] `OdesliService.swift` written
- [x] Tested OdesliService with real Spotify URL — returns title, artist, albumArtURL, trackID, platformLinks
- [x] Verified SongData parsing: Spotify → SPOTIFY_SONG::ID, Apple Music → ITUNES_SONG::ID, SoundCloud → SOUNDCLOUD_SONG::ID
- [x] Confirmed: Odesli doesn't always return all 3 target platforms — search fallback in PlatformLinks is essential
- [x] Error handling verified: obscure/missing tracks return 400, caught by OdesliError.apiError

## ✅ Phase 4 — Extension UI ✅ COMPLETE
- [x] `MessagesViewController.swift` written
- [x] UIPasteControl for iOS 16+ clipboard access (bypasses permission restrictions)
- [x] Paste handles both URL types (Spotify) and plain text
- [x] Compact → expanded transition on Odesli success
- [x] State resets on fresh extension open

## ✅ Phase 5 — Message Composition ✅ COMPLETE
- [x] `MessageComposer.swift` written
- [x] Switched from MSMessage (requires extension) to plain text URL (works for everyone)
- [x] iMessage auto-generates rich link preview from landing page OG tags
- [x] Album art pre-fetched for in-extension preview card

## ✅ Phase 6 — On-Device Testing ✅ COMPLETE
- [x] Connected iPhone 17 Pro Max via USB
- [x] Built + installed via xcodebuild + devicectl
- [x] Full flow tested: open extension → paste Spotify link → look up → preview → send → recipient taps → Safari → landing page
- [x] Verified: recipient without IDShare can tap link and reach landing page
- [x] Verified: landing page shows correct song with platform buttons

### Test Matrix (remaining items for future testing)
- [ ] Apple Music link → all 3 platform buttons work
- [ ] SoundCloud link → all 3 platform buttons work
- [ ] Very new release → search fallback fires
- [ ] Obscure SoundCloud track → search fallback fires
- [ ] Invalid URL pasted → error shown, send disabled
- [ ] API timeout → error shown, retry option works

## 🔲 Phase 7 (Future) — Share Sheet Extension
- [ ] Add Share Sheet target to Xcode project
- [ ] Reuse OdesliService + MessageComposer
- [ ] Test sharing directly from Spotify/Apple Music apps

## 🔲 Phase 8 (Future) — Audio Preview
- [ ] Add AVPlayer to extension UI
- [ ] Wire up 30-second preview URL from Odesli response
- [ ] Test memory usage — stay under ~120MB

## Bugs / Issues (Resolved)
- [x] ~~MSMessage bubbles showed "Cannot Connect" for recipients without extension~~ → Switched to plain text URL
- [x] ~~Paste didn't work reliably on iOS 16+~~ → Switched to UIPasteControl
- [x] ~~Landing page showed "Track Not Found"~~ → Strip Odesli prefix from track ID
- [x] ~~Spotify URLs not detected from clipboard~~ → Check UIPasteboard.url in addition to .string
