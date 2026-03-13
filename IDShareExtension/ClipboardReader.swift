import UIKit

// MARK: - ClipboardReader
// Reads the clipboard when the extension opens.
// iOS 16+ will show a system banner ("IDShare pasted from [app]") — this is expected and cannot be suppressed.
// Apps like Spotify copy URLs as URL objects, not plain strings — we check both.

struct ClipboardReader {

    // MARK: - Result
    struct Result {
        let content: String
        let platform: MusicPlatform
    }

    // MARK: - Public API

    /// Attempts to read a valid music URL from the clipboard.
    /// Checks both string and URL pasteboard types (Spotify copies as URL, not string).
    /// Returns nil if clipboard is empty or doesn't contain a recognized music URL.
    static func readMusicURL() -> Result? {
        // Try URL first — Spotify and Apple Music copy rich URLs
        if let url = UIPasteboard.general.url {
            let urlString = url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
            if let platform = URLValidator.platform(for: urlString) {
                return Result(content: urlString, platform: platform)
            }
        }

        // Fall back to plain string
        if let content = UIPasteboard.general.string {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if let platform = URLValidator.platform(for: trimmed) {
                return Result(content: trimmed, platform: platform)
            }
        }

        return nil
    }
}
