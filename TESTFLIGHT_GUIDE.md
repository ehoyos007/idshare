# iOS App → TestFlight Internal Only: Complete Guide

> Lessons learned from shipping IDShare (iMessage extension) to TestFlight via CLI + xcodegen.
> Last updated: 2026-03-12

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Apple Developer Account | $99/year, needed for code signing + App Store Connect |
| Xcode | Installed via App Store, includes `xcodebuild`, `xcrun`, `devicectl` |
| xcodegen (optional) | `brew install xcodegen` — generates `.xcodeproj` from a `project.yml` spec |
| Physical iPhone | iMessage extensions cannot be tested in the Simulator |

---

## 1. Xcode Project Setup (via xcodegen)

### project.yml structure

```yaml
name: MyApp
options:
  bundleIdPrefix: com.yourname
  deploymentTarget:
    iOS: "16.0"

settings:
  base:
    SWIFT_VERSION: "5.9"

targets:
  MyApp:
    type: application
    platform: iOS
    sources:
      - path: MyApp
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.yourname.myapp
        PRODUCT_NAME: "My App Display Name"        # ← This becomes the App Store name
        INFOPLIST_KEY_CFBundleDisplayName: "My App Display Name"
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone: "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight"
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        CODE_SIGN_STYLE: Automatic
        DEVELOPMENT_TEAM: YOUR_TEAM_ID
```

### Key gotchas

- **`PRODUCT_NAME`** is what App Store Connect uses as the app name — not `CFBundleName` or the project name
- **App name must be unique** on the App Store. If "MyApp" is taken, use something like "MyApp - Description"
- **`GENERATE_INFOPLIST_FILE: YES`** — lets Xcode auto-generate Info.plist instead of requiring a manual one
- **`INFOPLIST_KEY_UILaunchScreen_Generation: YES`** — required or you get "missing launch storyboard" error
- **`INFOPLIST_KEY_UISupportedInterfaceOrientations_*`** — required or you get "all orientations must be supported" error

### Finding your Team ID

```bash
security find-certificate -c "Apple Development" -p ~/Library/Keychains/login.keychain-db \
  | openssl x509 -noout -subject
# Look for OU=XXXXXXXXXX — that's your Team ID
```

### Generate the Xcode project

```bash
xcodegen generate
```

---

## 2. iMessage Extension Target

### Product type matters

For iMessage extensions, use `app-extension.messages` — NOT `app-extension`:

```yaml
  MyExtension:
    type: app-extension.messages    # ← Critical! Not just "app-extension"
    platform: iOS
```

- `app-extension` → product type `com.apple.product-type.appex` (generic)
- `app-extension.messages` → product type `com.apple.product-type.app-extension.messages`

The messages-specific type is required for:
- Compiling iMessage sticker/message icon sets
- Proper TestFlight/App Store validation

### Extension Info.plist requirements

```xml
<key>CFBundleDisplayName</key>
<string>MyExtension</string>
<key>MSMessagesExtensionStoreIconName</key>
<string>Messages Icon</string>
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.message-payload-provider</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).MessagesViewController</string>
</dict>
```

- **`CFBundleDisplayName`** — required or device install fails with "MissingBundleDisplayNameString"
- **`MSMessagesExtensionStoreIconName`** — required for TestFlight/App Store validation. **Must match the exact name of the icon set in the asset catalog** (see Section 3).

### Extension bundle ID

Must be prefixed with the parent app's bundle ID:
- Parent: `com.yourname.myapp`
- Extension: `com.yourname.myapp.extension`

---

## 3. App Icons

### Main app icon (standard iOS)

Place a 1024x1024 PNG in the app's asset catalog:

```
MyApp/Assets.xcassets/AppIcon.appiconset/
├── Contents.json
└── AppIcon.png
```

```json
{
  "images": [
    {
      "filename": "AppIcon.png",
      "idiom": "universal",
      "platform": "ios",
      "size": "1024x1024"
    }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

### iMessage extension icons — USE XCODE GUI

**DO NOT try to create iMessage icon sets via CLI/xcodegen.** The `stickersiconset` asset catalog type has compilation issues with CLI builds — it only compiles some sizes and drops others, causing TestFlight validation failures.

**The correct approach:**

1. Open the `.xcodeproj` in Xcode GUI
2. Select the extension's `Assets.xcassets`
3. Click **+** in the bottom-left → select **Message Extension Icon** (called "iMessage App Icon" in older Xcode)
4. Xcode creates a `Messages Icon.stickersiconset` with all the correct slots
5. Generate all required sizes from your source image (see below)
6. **Drag each sized PNG into the matching slot** in Xcode's asset catalog editor

### Required icon sizes

iMessage icons are **not square** — most use a 4:3 aspect ratio. There are also square icons for Settings.

| Slot | Pixels | Shape | Device |
|------|--------|-------|--------|
| iPhone Settings 29pt @2x | 58x58 | Square | iPhone |
| iPhone Settings 29pt @3x | 87x87 | Square | iPhone |
| Messages iPhone 60x45pt @2x | 120x90 | 4:3 | iPhone |
| Messages iPhone 60x45pt @3x | 180x135 | 4:3 | iPhone |
| iPad Settings 29pt @2x | 58x58 | Square | iPad |
| Messages iPad 67x50pt @2x | 134x100 | 4:3 | iPad |
| Messages iPad Pro 74x55pt @2x | 148x110 | 4:3 | iPad |
| App Store iOS 1024pt @1x | 1024x1024 | Square | Marketing |
| 27x20pt @2x | 54x40 | 4:3 | Small icon |
| 27x20pt @3x | 81x60 | 4:3 | Small icon |
| 32x24pt @2x | 64x48 | 4:3 | Small icon |
| 32x24pt @3x | 96x72 | 4:3 | Small icon |
| 1,024x768pt @1x | 1024x768 | 4:3 | Marketing |

### Generating all sizes from a source image

```python
from PIL import Image
import os

src = Image.open("my_icon.png")
out = "IDShare_Icons"
os.makedirs(out, exist_ok=True)

sizes = [
    # (filename, width, height)
    # Square icons (Settings + App Store)
    ("iPhone_Settings_29pt@2x.png", 58, 58),
    ("iPhone_Settings_29pt@3x.png", 87, 87),
    ("iPad_Settings_29pt@2x.png", 58, 58),
    ("AppStore_iOS_1024pt@1x.png", 1024, 1024),
    # 4:3 icons (Messages)
    ("Messages_iPhone_60x45pt@2x.png", 120, 90),
    ("Messages_iPhone_60x45pt@3x.png", 180, 135),
    ("Messages_iPad_67x50pt@2x.png", 134, 100),
    ("Messages_iPadPro_74x55pt@2x.png", 148, 110),
    ("Messages_27x20pt@2x.png", 54, 40),
    ("Messages_27x20pt@3x.png", 81, 60),
    ("Messages_32x24pt@2x.png", 64, 48),
    ("Messages_32x24pt@3x.png", 96, 72),
    ("Messages_1024x768pt@1x.png", 1024, 768),
]

for fname, w, h in sizes:
    src_w, src_h = src.size
    target_ratio = w / h
    src_ratio = src_w / src_h
    if src_ratio > target_ratio:
        new_w = int(src_h * target_ratio)
        left = (src_w - new_w) // 2
        cropped = src.crop((left, 0, left + new_w, src_h))
    else:
        new_h = int(src_w / target_ratio)
        top = (src_h - new_h) // 2
        cropped = src.crop((0, top, src_w, top + new_h))
    cropped.resize((w, h), Image.LANCZOS).save(os.path.join(out, fname))
    print(f"  {fname} ({w}x{h})")
```

### Critical: ASSETCATALOG_COMPILER_APPICON_NAME must match

The `app-extension.messages` type in xcodegen auto-sets `ASSETCATALOG_COMPILER_APPICON_NAME` to `"iMessage App Icon"`. But Xcode GUI creates the icon set as `"Messages Icon"`. **You must override this in project.yml:**

```yaml
  MyExtension:
    type: app-extension.messages
    settings:
      base:
        ASSETCATALOG_COMPILER_APPICON_NAME: "Messages Icon"  # ← Must match the asset catalog name
```

**After running `xcodegen generate`, verify:**
```bash
grep "ASSETCATALOG_COMPILER_APPICON_NAME" MyApp.xcodeproj/project.pbxproj
# Should show "Messages Icon" for the extension target
```

If this doesn't match, you get: `None of the input catalogs contained a matching stickers icon set or app icon set named "iMessage App Icon"`

### The MSMessagesExtensionStoreIconName must also match

In the extension's Info.plist, the value must match the asset catalog name:
```xml
<key>MSMessagesExtensionStoreIconName</key>
<string>Messages Icon</string>   <!-- Must match the .stickersiconset folder name -->
```

---

## 4. Code Signing

### Automatic signing (recommended)

```yaml
settings:
  base:
    CODE_SIGN_STYLE: Automatic
    DEVELOPMENT_TEAM: YOUR_TEAM_ID
```

- Xcode auto-creates development AND distribution certificates
- Xcode auto-creates provisioning profiles
- Use `-allowProvisioningUpdates` flag with `xcodebuild`

### Certificates

- **Apple Development** — for debug builds and device testing
- **Apple Distribution** — auto-created when you first export for App Store/TestFlight

---

## 5. Building & Device Testing

### Build for device

```bash
xcodebuild -project MyApp.xcodeproj -scheme MyApp \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates build
```

### Install to device

```bash
# List connected devices
xcrun devicectl list devices

# Install
xcrun devicectl device install app \
  --device DEVICE_UUID \
  path/to/MyApp.app
```

### Common device install errors

| Error | Fix |
|-------|-----|
| "Device is locked" | Unlock phone, keep screen on, reconnect USB |
| "Developer disk image could not be mounted" | Unlock phone → reconnect USB while unlocked |
| "MissingBundleDisplayNameString" | Add `CFBundleDisplayName` to extension Info.plist |
| "Embedded binary's bundle identifier is not prefixed" | Extension bundle ID must start with parent app's bundle ID |
| SDK version mismatch | Update Xcode or downgrade iOS |

---

## 6. Archiving for TestFlight

### Archive via CLI

```bash
xcodebuild archive \
  -project MyApp.xcodeproj \
  -scheme MyApp \
  -archivePath .build/MyApp.xcarchive \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic
```

### Archive via Xcode GUI (recommended for iMessage extensions)

Use **Product → Archive** in Xcode GUI. This handles the iMessage icon compilation correctly, which CLI builds sometimes botch.

### Upload via Xcode Organizer

1. After archiving, Xcode Organizer opens automatically (or: `open .build/MyApp.xcarchive`)
2. Select the archive → **Distribute App**
3. Select **TestFlight Internal Only**
4. Click **Distribute**
5. Xcode handles signing, app record creation, and upload
6. No phone needed — uploads directly to Apple's servers

---

## 7. TestFlight Validation Errors (Complete Reference)

### "App Name already in use"

The `PRODUCT_NAME` must be unique across the entire App Store.

**Fix:** Change `PRODUCT_NAME` in project.yml to something unique (e.g. "MyApp - Music Links"). This also sets `CFBundleName`. Both `PRODUCT_NAME` and `INFOPLIST_KEY_CFBundleDisplayName` should match.

### "Missing MSMessagesExtensionStoreIconName"

Extension Info.plist needs this key.

**Fix:** Add to Info.plist:
```xml
<key>MSMessagesExtensionStoreIconName</key>
<string>Messages Icon</string>
```

### "None of the input catalogs contained a matching stickers icon set or app icon set named 'iMessage App Icon'"

The `ASSETCATALOG_COMPILER_APPICON_NAME` build setting doesn't match the actual icon set name in the asset catalog.

**Fix:** Override in project.yml:
```yaml
ASSETCATALOG_COMPILER_APPICON_NAME: "Messages Icon"
```
After running `xcodegen generate`, the setting must match the `.stickersiconset` folder name in the extension's Assets.xcassets.

### "Missing app icon 54x40" / "81x60" / "96x72" / "64x48" etc.

The extension bundle is missing required iMessage icon PNGs.

**Fix:** Use Xcode GUI to create the Message Extension Icon set and drag correctly-sized PNGs into each slot. Don't rely on CLI-only stickersiconset compilation — it drops the smaller sizes.

### "Missing Large App Icon asset"

The 1024x768 marketing icon isn't compiled in the bundle.

**Fix:** Ensure the 1024x768pt @1x slot (bottom of the Messages Icon editor in Xcode) has an image. This is the 4:3 marketing icon, not the square 1024x1024 App Store icon.

### "Missing required icon file 120x120"

The main app (not extension) is missing its app icon.

**Fix:** Add a 1024x1024 PNG to the main app's `AppIcon.appiconset` with `"idiom": "universal", "platform": "ios"` in Contents.json.

---

## 8. MSMessage Behavior (iMessage Extensions)

### MSMessage vs plain text

| Approach | Pros | Cons |
|----------|------|------|
| `MSMessage` with template layout | Rich bubble with album art | Only works if recipient has the extension installed |
| `conversation.insertText(url)` | Works for ALL recipients, opens in Safari | No custom bubble — uses iMessage's auto link preview |

**For sideloaded apps (not on App Store):** Use `insertText()` — MSMessage bubbles show "Cannot Connect" for recipients without the extension because there's no App Store fallback.

**Once on TestFlight/App Store:** You can switch back to `MSMessage` — recipients without the extension will be prompted to download from the App Store.

### MSSession

- `MSMessage(session:)` — for interactive back-and-forth messages (games, collaboration)
- `MSMessage()` — for one-shot informational messages

**Don't use MSSession for share-type extensions.** It tells iOS the message requires the extension on both sides.

### Clipboard in extensions (iOS 16+)

`UIPasteboard.general.string` is restricted in extensions on iOS 16+. Use Apple's `UIPasteControl` instead:

```swift
import UniformTypeIdentifiers

// In viewDidLoad:
self.pasteConfiguration = UIPasteConfiguration(acceptableTypeIdentifiers: [
    UTType.url.identifier,
    UTType.plainText.identifier
])

// Add UIPasteControl to your view (system-provided paste button)
let pasteControl = UIPasteControl(configuration: .init())

// Override to receive pasted content:
override func paste(itemProviders: [NSItemProvider]) {
    // Handle pasted URLs/text
}
```

**Also check `UIPasteboard.general.url`** — Spotify and Apple Music copy links as URL objects, not plain strings.

---

## Quick Reference: Full Workflow

```bash
# 1. Generate project
xcodegen generate

# 2. Build
xcodebuild -project MyApp.xcodeproj -scheme MyApp \
  -destination 'generic/platform=iOS' -allowProvisioningUpdates build

# 3. Test on device
xcrun devicectl device install app --device DEVICE_ID path/to/MyApp.app

# 4. Generate icon sizes (Python script above), then:
#    - Open .xcodeproj in Xcode
#    - Add Message Extension Icon via Assets.xcassets + button
#    - Drag sized PNGs into each slot

# 5. Archive (use Xcode GUI for iMessage extensions)
#    Product → Archive

# 6. Upload
#    Xcode Organizer → Distribute App → TestFlight Internal Only → Distribute
```

---

## Troubleshooting Checklist

Before submitting to TestFlight, verify:

- [ ] `PRODUCT_NAME` is unique (not taken on App Store)
- [ ] `PRODUCT_NAME`, `INFOPLIST_KEY_CFBundleDisplayName`, and `CFBundleName` all match
- [ ] Extension bundle ID is prefixed with parent app bundle ID
- [ ] Extension Info.plist has `CFBundleDisplayName` (non-empty)
- [ ] Extension Info.plist has `MSMessagesExtensionStoreIconName` matching asset catalog name
- [ ] `ASSETCATALOG_COMPILER_APPICON_NAME` in project.yml matches the actual `.stickersiconset` folder name
- [ ] Main app has 1024x1024 AppIcon in asset catalog
- [ ] Extension has ALL 13 Message Extension Icon slots filled (via Xcode GUI)
- [ ] All icon PNGs are the exact pixel dimensions shown in Xcode's slot labels
- [ ] Archive using Xcode GUI (**Product → Archive**), not just CLI
