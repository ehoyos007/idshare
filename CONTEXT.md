# IDShare — Project Context

## What It Is
An iMessage extension for iPhone that lets you share music across streaming platforms from a single universal link. Instead of sending a Spotify link that only works for Spotify users, IDShare sends a rich iMessage bubble with album art — the recipient taps it and opens the song on their preferred platform.

**Tagline:** One link. Every platform. Inside iMessage.

## Scope (v1)
- **Content:** Individual songs only (no albums, playlists, podcasts)
- **Platforms:** Spotify, Apple Music, SoundCloud
- **Distribution:** Sideloaded via Xcode to personal devices. No App Store.
- **Link input:** Paste-only for v1 (Share Sheet is Phase 7 — future)
- **Timeline:** No hard deadline. Build at your own pace.

## Architecture
Two independent codebases connected through a shared URL scheme:

| Component | Tech | Purpose |
|-----------|------|---------|
| iMessage Extension | Swift + SwiftUI (Xcode) | Paste link → call Odesli → preview song → send MSMessage |
| Landing Page | Next.js on Vercel | Resolve track ID → render album art + 3 platform buttons |
| Odesli API | api.song.link (free, no key) | Cross-platform link resolution + metadata |

## Key URLs
- **Landing page (live):** https://idshare.vercel.app
- **Example song page:** https://idshare.vercel.app/s/0VjIjW4GlUZAMYd2vXMi3b
- **Odesli API:** https://api.song.link/v1-alpha.1/links?url=[encoded URL]
- **GitHub:** https://github.com/ehoyos007/idshare

## Key Technical Decisions
| Decision | Choice |
|----------|--------|
| Content types | Individual songs only |
| Link input | Paste-only v1, Share Sheet later |
| Clipboard auto-detect | Yes — auto-read clipboard on extension open |
| Odesli API call location | Client-side (extension calls Odesli directly) |
| Message type | MSMessage + MSMessageTemplateLayout (rich bubble) |
| Landing page platform memory | No — always show all 3 buttons |
| Failed Odesli lookup | Search fallback (open search in platform app) |
| Extension UI theme | Dark, matching iMessage |
| Extension layout | Compact → expanded when preview loads |
| Distribution | Sideload via Xcode |
| Dev workflow | Build everything first, then test on device |

## Bundle IDs
- Main app: `com.enzohoyos.idshare`
- Extension: `com.enzohoyos.idshare.extension`

## Xcode Project Targets
1. **IDShare** — containing iOS app (required by Apple, minimal shell UI)
2. **IDShareExtension** — the actual iMessage extension (all real logic here)

## File Structure (Extension)
```
IDShareExtension/
├── MessagesViewController.swift   # Main UI controller — compact/expanded states
├── OdesliService.swift            # Odesli API call + JSON parsing → SongData
├── MessageComposer.swift          # Builds MSMessage + downloads album art
├── ClipboardReader.swift          # Reads UIPasteboard, validates music URLs
├── URLValidator.swift             # Regex patterns for Spotify/Apple Music/SoundCloud
├── SongData.swift                 # Data model
└── Assets.xcassets/
```

## Data Flow
1. User opens IDShare from iMessage app drawer
2. Extension reads clipboard → auto-populates if music URL detected
3. URL validated in real-time (regex patterns)
4. User taps "Look Up" → OdesliService calls api.song.link
5. Spinner shown while waiting (1-3s)
6. Odesli returns: platform links, track ID, title, artist, album art URL
7. Extension drawer expands → shows preview card (art + title + artist)
8. User taps Send → MessageComposer builds MSMessage with album art
9. Rich bubble appears in iMessage thread
10. Recipient taps → idshare.vercel.app/s/[trackID] opens
11. Page renders album art + 3 platform buttons
12. Recipient taps their platform → deep link fires → song opens in app

## Deep Link Schemes
| Platform | Direct | Search Fallback |
|----------|--------|----------------|
| Spotify | `spotify://track/[id]` | `spotify://search/[title+artist]` |
| Apple Music | `music://[path]` | `music://search?term=[title+artist]` |
| SoundCloud | `soundcloud://[path]` | `soundcloud://search/[title+artist]` |

## Known Gotchas
- Extension memory limit ~120MB — use thumbnail images, not full-res
- iOS 16+ shows clipboard banner ("IDShare pasted from [app]") — cosmetic, can't suppress
- iMessage extensions CANNOT be tested in the Simulator — requires physical iPhone
- SoundCloud deep links less reliable than Spotify/Apple Music — search fallback critical
- MSMessageTemplateLayout requires album art downloaded as UIImage before send
- Very new releases may not be in Odesli yet — search fallback handles this
