import UIKit

// MARK: - ClipboardReader
// Reads the clipboard when the extension opens.
// iOS 16+ will show a system banner ("IDShare pasted from [app]") — this is expected and cannot be suppressed.

struct ClipboardReader {

    // MARK: - Result
    struct Result {
        let content: String
        let platform: MusicPlatform
    }

    // MARK: - Public API

    /// Attempts to read a valid music URL from the clipboard.
    /// Returns nil if clipboard is empty or doesn't contain a recognized music URL.
    static func readMusicURL() -> Result? {
        guard let content = UIPasteboard.general.string,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let platform = URLValidator.platform(for: trimmed) else {
            return nil
        }

        return Result(content: trimmed, platform: platform)
    }
}
