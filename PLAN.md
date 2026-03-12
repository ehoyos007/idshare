# IDShare — Build Plan

## Phase Overview

```
Phase 1: Xcode Setup         [Manual — Xcode GUI]
Phase 2: URL Validation      [Swift — URLValidator.swift] ✅ Written
Phase 3: Odesli Integration  [Swift — OdesliService.swift] ✅ Written
Phase 4: Extension UI        [Swift — MessagesViewController.swift] ✅ Written
Phase 5: Message Composition [Swift — MessageComposer.swift] ✅ Written
Phase 6: On-Device Testing   [iPhone required]
Phase 7: Share Sheet (future)
Phase 8: Audio Preview (future)
```

---

## Phase 1 — Xcode Project Setup
**Status:** Not started — manual Xcode steps required

### Steps
1. Open Xcode → File → New → Project
   - Template: iOS → App
   - Product Name: `IDShare`
   - Bundle Identifier: `com.enzohoyos.idshare`
   - Interface: SwiftUI
   - Language: Swift
   - Uncheck "Include Tests" (not needed for v1)

2. Add iMessage Extension target
   - File → New → Target
   - Filter: search "iMessage"
   - Choose **iMessage Extension**
   - Product Name: `IDShareExtension`
   - Bundle ID auto-fills: `com.enzohoyos.idshare.IDShareExtension`
     → Change to: `com.enzohoyos.idshare.extension`
   - Click Finish. Activate scheme when prompted.

3. Add WebKit.framework to IDShareExtension
   - Select IDShareExtension target → General tab
   - Scroll to Frameworks, Libraries, and Embedded Content
   - Click + → search "WebKit" → Add WebKit.framework

4. Copy Swift source files
   - Drag all files from this repo's `IDShareExtension/` folder into the IDShareExtension group in Xcode
   - Make sure "Add to target: IDShareExtension" is checked
   - Delete the default `MessagesViewController.swift` that Xcode auto-generated first

5. Set up signing
   - Select IDShare target → Signing & Capabilities
   - Team: your Apple Developer account
   - Repeat for IDShareExtension target
   - Xcode should auto-manage provisioning profiles

6. Build (⌘B) to verify zero compile errors

---

## Phase 2 — URL Validation
**Status:** ✅ Written (`IDShareExtension/URLValidator.swift`)

URLValidator handles real-time URL validation for Spotify, Apple Music, and SoundCloud.
Test it with real URLs from each app before moving on.

---

## Phase 3 — Odesli Integration
**Status:** ✅ Written (`IDShareExtension/OdesliService.swift`)

**Recommended:** Test OdesliService in a Swift Playground first.
Create a new Playground in Xcode → paste OdesliService code → call it with a real Spotify URL.
This way you can verify parsing before it's buried inside the extension.

Odesli API endpoint:
```
GET https://api.song.link/v1-alpha.1/links?url=[percent-encoded URL]
```

No API key needed. Response includes:
- `entitiesByUniqueId` — song metadata per platform
- `linksByPlatform` — direct platform links
- `entityUniqueId` — the track ID used in the landing page URL

---

## Phase 4 — Extension UI
**Status:** ✅ Written (`IDShareExtension/MessagesViewController.swift`)

The UI has three states:
- **Compact:** Text field (pre-populated from clipboard) + Look Up button
- **Loading:** Spinner + disabled buttons (during Odesli call)
- **Expanded:** Album art preview card + Send button

Key behavior: `requestPresentationStyle(.expanded)` is called after the Odesli response. The transition animation can be tricky — test carefully on device.

---

## Phase 5 — Message Composition
**Status:** ✅ Written (`IDShareExtension/MessageComposer.swift`)

The MSMessage is built with `MSMessageTemplateLayout`:
- Image: album art (UIImage, downloaded during preview phase)
- Caption: song title
- Subcaption: artist name  
- URL: `https://idshare.vercel.app/s/[trackID]`

**Important:** Album art must be fully downloaded before the user taps Send. The download happens during the preview phase so there's no delay at send time.

---

## Phase 6 — On-Device Testing
**Status:** Blocked until Phases 1-5 complete

iMessage extensions CANNOT run in the iOS Simulator. You need a physical iPhone connected to your Mac via USB.

Test order:
1. Build + install to device (Xcode → select your iPhone → ▶ Run)
2. Open iMessage on device → tap app drawer icon (A with pencil) → find IDShare
3. Full flow test with each platform
4. Edge case testing (new releases, obscure tracks, invalid URLs)

---

## Architecture Notes

### Why client-side Odesli?
For v1, calling Odesli directly from the extension is simpler — no server, no latency, no maintenance. The tradeoff is rate limits, but for personal use this will never be an issue. If you ever need caching/analytics, move it server-side to a Vercel API route at `idshare.vercel.app/api/lookup`.

### Why no platform memory?
Always showing all 3 buttons keeps the landing page stateless — no auth, no cookies, no DB. Simple and fast. If you want to add platform preference saving later, a URL param (`?platform=spotify`) or localStorage would work.

### Landing page URL scheme
`idshare.vercel.app/s/[trackID]` — the `[trackID]` is the `entityUniqueId` from Odesli (e.g. `SPOTIFY_SONG::0VjIjW4GlUZAMYd2vXMi3b`). The landing page calls Odesli server-side with this ID to fetch metadata.
