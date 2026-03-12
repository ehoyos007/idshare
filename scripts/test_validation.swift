#!/usr/bin/env swift
// Phase 2+3 Test Script — URLValidator regex + Odesli API integration

import Foundation

// ============================================================
// MARK: - URLValidator (copied from IDShareExtension)
// ============================================================

struct URLValidator {
    static func isValid(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return platform(for: trimmed) != nil
    }

    static func platform(for input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if isSpotifyURL(trimmed)     { return "spotify" }
        if isAppleMusicURL(trimmed)  { return "appleMusic" }
        if isSoundCloudURL(trimmed)  { return "soundCloud" }
        return nil
    }

    private static func isSpotifyURL(_ url: String) -> Bool {
        let patterns = [
            #"https?://open\.spotify\.com/track/[A-Za-z0-9]+"#,
            #"spotify://track/[A-Za-z0-9]+"#,
            #"https?://spotify\.link/[A-Za-z0-9]+"#
        ]
        return matches(url, anyOf: patterns)
    }

    private static func isAppleMusicURL(_ url: String) -> Bool {
        let patterns = [
            #"https?://music\.apple\.com/[a-z]{0,5}/?album/[^/]+/\d+"#,
            #"https?://music\.apple\.com/[a-z]{0,5}/?song/[^/]+/\d+"#,
            #"https?://geo\.music\.apple\.com/[^?]+"#,
            #"https?://music\.apple\.com/[a-z]{2}/album/.+\?i=\d+"#
        ]
        return matches(url, anyOf: patterns)
    }

    private static func isSoundCloudURL(_ url: String) -> Bool {
        let patterns = [
            #"https?://(?:www\.)?soundcloud\.com/[A-Za-z0-9_-]+/(?!sets|likes|reposts|tracks|following|followers)[A-Za-z0-9_-]+"#,
            #"https?://on\.soundcloud\.com/[A-Za-z0-9]+"#
        ]
        return matches(url, anyOf: patterns)
    }

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

// ============================================================
// MARK: - Phase 2: URL Validation Tests
// ============================================================

print("=" * 60)
print("PHASE 2: URL Validation Tests")
print("=" * 60)

struct TestCase {
    let url: String
    let expectedPlatform: String?
    let description: String
}

let testCases: [TestCase] = [
    // Spotify — should match
    TestCase(url: "https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b", expectedPlatform: "spotify", description: "Spotify standard track URL"),
    TestCase(url: "https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b?si=abc123def456", expectedPlatform: "spotify", description: "Spotify track with si param"),
    TestCase(url: "spotify://track/0VjIjW4GlUZAMYd2vXMi3b", expectedPlatform: "spotify", description: "Spotify deep link"),
    TestCase(url: "https://spotify.link/abc123XYZ", expectedPlatform: "spotify", description: "Spotify short link"),

    // Apple Music — should match
    TestCase(url: "https://music.apple.com/us/album/blinding-lights/1499378108?i=1499378615", expectedPlatform: "appleMusic", description: "Apple Music album with ?i= track"),
    TestCase(url: "https://music.apple.com/us/album/some-album/1234567890", expectedPlatform: "appleMusic", description: "Apple Music album URL"),
    TestCase(url: "https://music.apple.com/us/song/blinding-lights/1499378615", expectedPlatform: "appleMusic", description: "Apple Music song URL"),
    TestCase(url: "https://music.apple.com/album/some-album/1234567890", expectedPlatform: "appleMusic", description: "Apple Music no region"),
    TestCase(url: "https://geo.music.apple.com/us/album/blinding-lights/1499378108", expectedPlatform: "appleMusic", description: "Apple Music geo link"),

    // SoundCloud — should match
    TestCase(url: "https://soundcloud.com/flaborat/flaborat-aint-new", expectedPlatform: "soundCloud", description: "SoundCloud standard track"),
    TestCase(url: "https://www.soundcloud.com/artist-name/track-name", expectedPlatform: "soundCloud", description: "SoundCloud with www"),
    TestCase(url: "https://soundcloud.com/artist/track-name?in=playlist/set", expectedPlatform: "soundCloud", description: "SoundCloud with query params"),
    TestCase(url: "https://on.soundcloud.com/abc123", expectedPlatform: "soundCloud", description: "SoundCloud short link"),

    // Should NOT match
    TestCase(url: "https://open.spotify.com/album/12345", expectedPlatform: nil, description: "Spotify album (not track)"),
    TestCase(url: "https://open.spotify.com/playlist/12345", expectedPlatform: nil, description: "Spotify playlist"),
    TestCase(url: "https://soundcloud.com/artist/sets/playlist-name", expectedPlatform: nil, description: "SoundCloud set (not track)"),
    TestCase(url: "https://soundcloud.com/artist/likes", expectedPlatform: nil, description: "SoundCloud likes page"),
    TestCase(url: "https://www.youtube.com/watch?v=12345", expectedPlatform: nil, description: "YouTube (unsupported)"),
    TestCase(url: "not a url at all", expectedPlatform: nil, description: "Plain text"),
    TestCase(url: "", expectedPlatform: nil, description: "Empty string"),
]

var passed = 0
var failed = 0

for tc in testCases {
    let result = URLValidator.platform(for: tc.url)
    let ok = result == tc.expectedPlatform
    if ok {
        passed += 1
        print("  ✅ \(tc.description)")
    } else {
        failed += 1
        print("  ❌ \(tc.description)")
        print("     URL:      \(tc.url)")
        print("     Expected: \(tc.expectedPlatform ?? "nil")")
        print("     Got:      \(result ?? "nil")")
    }
}

print("\nResults: \(passed)/\(passed + failed) passed")
if failed > 0 { print("⚠️  \(failed) test(s) FAILED") }

// ============================================================
// MARK: - Phase 3: Odesli API Integration Test
// ============================================================

print("\n" + "=" * 60)
print("PHASE 3: Odesli API Integration Test")
print("=" * 60)

let testURLs = [
    ("https://open.spotify.com/track/0VjIjW4GlUZAMYd2vXMi3b", "Spotify"),
    ("https://music.apple.com/us/album/blinding-lights/1499378108?i=1499378615", "Apple Music"),
    ("https://soundcloud.com/flaborat/flaborat-aint-new", "SoundCloud"),
]

let semaphore = DispatchSemaphore(value: 0)

for (testURL, platform) in testURLs {
    print("\n  Testing \(platform): \(testURL)")

    guard let encoded = testURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let requestURL = URL(string: "https://api.song.link/v1-alpha.1/links?url=\(encoded)") else {
        print("  ❌ Failed to encode URL")
        continue
    }

    let task = URLSession.shared.dataTask(with: requestURL) { data, response, error in
        defer { semaphore.signal() }

        if let error = error {
            print("  ❌ Network error: \(error.localizedDescription)")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("  ❌ Invalid response")
            return
        }

        print("  HTTP Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200, let data = data else {
            print("  ❌ Non-200 response")
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("  ❌ Failed to parse JSON")
            return
        }

        // Track ID
        let trackID = json["entityUniqueId"] as? String ?? "MISSING"
        print("  Track ID: \(trackID)")

        // Metadata
        let entities = json["entitiesByUniqueId"] as? [String: Any] ?? [:]
        if let meta = entities[trackID] as? [String: Any] {
            let title = meta["title"] as? String ?? "?"
            let artist = meta["artistName"] as? String ?? "?"
            let thumb = meta["thumbnailUrl"] as? String ?? "none"
            print("  Title:  \(title)")
            print("  Artist: \(artist)")
            print("  Art:    \(thumb.prefix(80))...")
        } else {
            print("  ⚠️  No metadata for trackID")
        }

        // Platform links
        let links = json["linksByPlatform"] as? [String: Any] ?? [:]
        let platforms = ["spotify", "appleMusic", "soundcloud"]
        for p in platforms {
            if let pdata = links[p] as? [String: Any], let url = pdata["url"] as? String {
                print("  ✅ \(p): \(url.prefix(60))...")
            } else {
                print("  ⚠️  \(p): no link found")
            }
        }
    }
    task.resume()
    semaphore.wait()
}

print("\n" + "=" * 60)
print("All tests complete.")
print("=" * 60)

// Helper
func *(lhs: String, rhs: Int) -> String {
    String(repeating: lhs, count: rhs)
}
