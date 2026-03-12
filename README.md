# IDShare

> One link. Every platform. Inside iMessage.

An iMessage extension for iPhone that sends a rich music bubble — tap it and open the song on Spotify, Apple Music, or SoundCloud. No more platform-specific links.

## How It Works

1. Open IDShare from the iMessage app drawer
2. Paste a music link (Spotify, Apple Music, or SoundCloud)
3. IDShare fetches metadata via the [Odesli API](https://odesli.co/) and shows a preview
4. Tap **Send** — a rich bubble with album art appears in your conversation
5. Recipient taps the bubble → [idshare.vercel.app](https://idshare.vercel.app) → picks their platform → song opens

## Tech Stack

| Component | Tech |
|-----------|------|
| iMessage Extension | Swift + UIKit (Xcode) |
| Landing Page | Next.js on Vercel |
| Link Resolution | [Odesli API](https://api.song.link) (free, no key) |

## Project Structure

```
IDShare/                    → Minimal container iOS app (required by Apple)
IDShareExtension/           → The actual iMessage extension
  ├── MessagesViewController.swift   # Main UI: compact → loading → expanded
  ├── OdesliService.swift            # API call + JSON parsing
  ├── MessageComposer.swift          # Builds MSMessage + downloads album art
  ├── ClipboardReader.swift          # Auto-reads clipboard on open
  ├── URLValidator.swift             # Regex URL validation
  └── SongData.swift                 # Data model + platform enums
docs/                       → Additional docs
scripts/
  └── clu-update.sh         → Session commit workflow
```

## Platform Support

- **Spotify** — tracks
- **Apple Music** — tracks
- **SoundCloud** — tracks
- Search fallback for platforms where Odesli doesn't have a direct link

## Distribution

Sideloaded via Xcode to personal devices. No App Store.

## Build Notes

- Requires Xcode + Apple Developer account ($99/year)
- iMessage extensions **cannot** be tested in the iOS Simulator — physical iPhone required
- Landing page already live at [idshare.vercel.app](https://idshare.vercel.app)
- See [PLAN.md](PLAN.md) for full build walkthrough
