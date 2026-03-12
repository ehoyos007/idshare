import Foundation

// MARK: - OdesliService
// Calls the Odesli (song.link) API to resolve a music URL into cross-platform links + metadata.
// API: https://api.song.link/v1-alpha.1/links?url=[encoded URL]
// Free, no API key required.

actor OdesliService {

    private let session: URLSession
    private let baseURL = "https://api.song.link/v1-alpha.1/links"
    private let timeoutSeconds: TimeInterval = 10

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Resolves a music URL to a SongData model containing cross-platform links and metadata.
    func resolve(url: String) async throws -> SongData {
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let requestURL = URL(string: "\(baseURL)?url=\(encodedURL)") else {
            throw OdesliError.invalidURL
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: requestURL)
        } catch let error as URLError where error.code == .timedOut {
            throw OdesliError.timeout
        } catch {
            throw OdesliError.networkFailure(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OdesliError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OdesliError.apiError(httpResponse.statusCode)
        }

        return try parseResponse(data: data)
    }

    // MARK: - JSON Parsing

    private func parseResponse(data: Data) throws -> SongData {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OdesliError.invalidResponse
        }

        // The entityUniqueId is used as the track ID for our landing page URL
        guard let trackID = json["entityUniqueId"] as? String else {
            throw OdesliError.noMatchFound
        }

        // entitiesByUniqueId contains metadata for the source entity
        let entitiesByUniqueId = json["entitiesByUniqueId"] as? [String: Any] ?? [:]

        // Find the source entity — the one matching our trackID
        let metadata = entitiesByUniqueId[trackID] as? [String: Any]

        let title = metadata?["title"] as? String ?? "Unknown Song"
        let artist = metadata?["artistName"] as? String ?? "Unknown Artist"
        let albumName = metadata?["collectionName"] as? String

        let thumbnailURL: URL?
        if let thumbStr = metadata?["thumbnailUrl"] as? String {
            thumbnailURL = URL(string: thumbStr)
        } else {
            thumbnailURL = nil
        }

        let previewURL: URL?
        if let previewStr = metadata?["previewUrl"] as? String {
            previewURL = URL(string: previewStr)
        } else {
            previewURL = nil
        }

        // linksByPlatform contains direct links per platform
        let linksByPlatform = json["linksByPlatform"] as? [String: Any] ?? [:]

        let platformLinks = PlatformLinks(
            spotify:    extractPlatformURL(from: linksByPlatform, key: "spotify"),
            appleMusic: extractPlatformURL(from: linksByPlatform, key: "appleMusic"),
            soundCloud: extractPlatformURL(from: linksByPlatform, key: "soundcloud")
        )

        // Require at least one platform link — if we got nothing useful, fail gracefully
        if platformLinks.spotify == nil && platformLinks.appleMusic == nil && platformLinks.soundCloud == nil {
            throw OdesliError.noMatchFound
        }

        return SongData(
            trackID: trackID,
            title: title,
            artist: artist,
            albumName: albumName,
            albumArtURL: thumbnailURL,
            previewURL: previewURL,
            platformLinks: platformLinks
        )
    }

    private func extractPlatformURL(from dict: [String: Any], key: String) -> URL? {
        guard let platformData = dict[key] as? [String: Any],
              let urlString = platformData["url"] as? String else {
            return nil
        }
        return URL(string: urlString)
    }
}
