import Foundation

// MARK: - SongData
// The core data model returned from OdesliService.
// This is the single source of truth passed between all components.

struct SongData {
    let trackID: String           // Odesli entityUniqueId (e.g. "SPOTIFY_SONG::0VjIjW4GlUZAMYd2vXMi3b")
    let title: String
    let artist: String
    let albumName: String?
    let albumArtURL: URL?
    let previewURL: URL?          // 30-second preview (optional, may not always be present)
    let platformLinks: PlatformLinks

    /// The platform-specific ID extracted from the Odesli entityUniqueId.
    /// e.g. "SPOTIFY_SONG::0VjIjW4GlUZAMYd2vXMi3b" → "0VjIjW4GlUZAMYd2vXMi3b"
    var platformID: String {
        if let range = trackID.range(of: "::") {
            return String(trackID[range.upperBound...])
        }
        return trackID
    }

    /// The IDShare landing page URL for this track
    var landingPageURL: URL {
        URL(string: "https://idshare.vercel.app/s/\(platformID)")!
    }
}

// MARK: - PlatformLinks
// Platform-specific links returned by Odesli.
// A nil value means Odesli couldn't find that platform — use the search fallback.

struct PlatformLinks {
    let spotify: URL?
    let appleMusic: URL?
    let soundCloud: URL?

    /// Returns the direct link, falling back to a search URL if not available
    func resolvedLink(for platform: MusicPlatform, songTitle: String, artist: String) -> URL {
        let directLink: URL?
        switch platform {
        case .spotify:      directLink = spotify
        case .appleMusic:   directLink = appleMusic
        case .soundCloud:   directLink = soundCloud
        }
        return directLink ?? platform.searchURL(title: songTitle, artist: artist)
    }
}

// MARK: - MusicPlatform
enum MusicPlatform: CaseIterable {
    case spotify
    case appleMusic
    case soundCloud

    var displayName: String {
        switch self {
        case .spotify:    return "Spotify"
        case .appleMusic: return "Apple Music"
        case .soundCloud: return "SoundCloud"
        }
    }

    var iconName: String {
        switch self {
        case .spotify:    return "spotify_icon"   // add to Assets.xcassets
        case .appleMusic: return "applemusic_icon"
        case .soundCloud: return "soundcloud_icon"
        }
    }

    /// Search URL fallback when Odesli doesn't have a direct link for this platform
    func searchURL(title: String, artist: String) -> URL {
        let query = "\(title) \(artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        switch self {
        case .spotify:
            return URL(string: "spotify://search/\(query)")!
        case .appleMusic:
            return URL(string: "music://search?term=\(query)")!
        case .soundCloud:
            return URL(string: "soundcloud://search/\(query)")!
        }
    }
}

// MARK: - OdesliError
enum OdesliError: LocalizedError {
    case invalidURL
    case networkFailure(Error)
    case invalidResponse
    case apiError(Int)
    case noMatchFound
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "That doesn't look like a valid music link. Try copying it again."
        case .networkFailure:
            return "Couldn't connect. Check your internet connection and try again."
        case .invalidResponse:
            return "Unexpected response from the server. Try again."
        case .apiError(let code):
            return "Lookup failed (error \(code)). Try a different link."
        case .noMatchFound:
            return "Couldn't find that song on other platforms. Try a different link."
        case .timeout:
            return "Lookup timed out. Check your connection and try again."
        }
    }
}
