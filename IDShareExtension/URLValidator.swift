import Foundation

// MARK: - URLValidator
// Synchronous, regex-based URL validation.
// Called on every keystroke in the text field — must be fast.
//
// Supported patterns:
//   Spotify:     open.spotify.com/track/...  OR  spotify://track/...
//   Apple Music: music.apple.com/*/album/*/...  OR  music.apple.com/*/song/...
//   SoundCloud:  soundcloud.com/[user]/[track]

struct URLValidator {

    // MARK: - Public API

    /// Returns true if the string looks like a valid music URL from any supported platform
    static func isValid(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return platform(for: trimmed) != nil
    }

    /// Returns which platform the URL belongs to, or nil if not recognized
    static func platform(for input: String) -> MusicPlatform? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if isSpotifyURL(trimmed)     { return .spotify }
        if isAppleMusicURL(trimmed)  { return .appleMusic }
        if isSoundCloudURL(trimmed)  { return .soundCloud }
        return nil
    }

    // MARK: - Spotify

    // Matches:
    //   https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b
    //   https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b?si=abc123
    //   spotify://track/0VjIjW4GlUZAMYd2vXMi3b
    private static func isSpotifyURL(_ url: String) -> Bool {
        let patterns = [
            #"https?://open\.spotify\.com/track/[A-Za-z0-9]+"#,
            #"spotify://track/[A-Za-z0-9]+"#,
            // Short links (e.g. spotify.link/...)
            #"https?://spotify\.link/[A-Za-z0-9]+"#
        ]
        return matches(url, anyOf: patterns)
    }

    // MARK: - Apple Music

    // Matches:
    //   https://music.apple.com/us/album/song-name/1234567890?i=987654321
    //   https://music.apple.com/us/song/song-name/1234567890
    //   https://music.apple.com/album/...  (no region)
    //   https://geo.music.apple.com/...    (geo redirect links)
    private static func isAppleMusicURL(_ url: String) -> Bool {
        let patterns = [
            #"https?://music\.apple\.com/[a-z]{0,5}/?album/[^/]+/\d+"#,
            #"https?://music\.apple\.com/[a-z]{0,5}/?song/[^/]+/\d+"#,
            #"https?://geo\.music\.apple\.com/[^?]+"#,
            // Short links shared from the Music app
            #"https?://music\.apple\.com/[a-z]{2}/album/.+\?i=\d+"#
        ]
        return matches(url, anyOf: patterns)
    }

    // MARK: - SoundCloud

    // Matches:
    //   https://soundcloud.com/artist/track-name
    //   https://soundcloud.com/artist/track-name?in=playlist
    //   https://on.soundcloud.com/abc123  (short links)
    private static func isSoundCloudURL(_ url: String) -> Bool {
        let patterns = [
            // Standard track URL: soundcloud.com/[artist]/[track] (not sets, not likes, not reposts)
            #"https?://(?:www\.)?soundcloud\.com/[A-Za-z0-9_-]+/(?!sets|likes|reposts|tracks|following|followers)[A-Za-z0-9_-]+"#,
            // Short links
            #"https?://on\.soundcloud\.com/[A-Za-z0-9]+"#
        ]
        return matches(url, anyOf: patterns)
    }

    // MARK: - Helpers

    private static func matches(_ input: String, anyOf patterns: [String]) -> Bool {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(input.startIndex..., in: input)
                if regex.firstMatch(in: input, range: range) != nil {
                    return true
                }
            }
        }
        return false
    }
}
