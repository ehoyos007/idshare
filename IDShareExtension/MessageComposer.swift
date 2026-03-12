import UIKit
import Messages

// MARK: - MessageComposer
// Builds an MSMessage with a rich bubble layout (album art + title + artist + IDShare URL).
// Album art is downloaded during the preview phase so there's zero delay at send time.

final class MessageComposer {

    // MARK: - State
    // The downloaded album art is cached here after preview loads.
    // MessagesViewController holds a reference and passes it in at send time.
    private(set) var cachedAlbumArt: UIImage?

    // MARK: - Album Art Download
    // Call this when the preview card loads — not at send time.

    func prefetchAlbumArt(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                // Resize to a reasonable thumbnail to stay under extension memory limits (~120MB)
                cachedAlbumArt = resize(image, to: CGSize(width: 600, height: 600))
            }
        } catch {
            // Non-fatal — if album art fails to download, we send without it
            cachedAlbumArt = nil
        }
    }

    func clearCache() {
        cachedAlbumArt = nil
    }

    // MARK: - Build MSMessage

    /// Builds the MSMessage ready to insert into the conversation.
    /// - Parameters:
    ///   - song: The resolved SongData from Odesli
    ///   - conversation: The active MSConversation
    /// - Returns: A configured MSMessage ready to send, or nil if construction fails
    func buildMessage(for song: SongData, in conversation: MSConversation) -> MSMessage? {
        let layout = MSMessageTemplateLayout()

        // Album art (downloaded during preview phase)
        layout.image = cachedAlbumArt

        // Song info
        layout.caption = song.title
        layout.subcaption = song.artist
        if let album = song.albumName {
            layout.trailingCaption = album
        }

        // The IDShare landing page URL — this is what opens when the recipient taps the bubble
        layout.imageTitle = "IDShare"
        layout.imageSubtitle = "Tap to open on any platform"

        let message = MSMessage()
        message.layout = layout
        message.url = song.landingPageURL

        // Shown in notifications and conversation list previews
        message.summaryText = "\(song.title) by \(song.artist) — IDShare"

        return message
    }

    // MARK: - Insert Message

    /// Inserts the built message into the active conversation.
    /// Call this from MessagesViewController when the user taps Send.
    func send(song: SongData, in conversation: MSConversation, controller: MSMessagesAppViewController) {
        guard let message = buildMessage(for: song, in: conversation) else { return }

        conversation.insert(message) { [weak controller] error in
            if let error = error {
                print("[IDShare] Failed to insert message: \(error.localizedDescription)")
            } else {
                // Collapse the extension back to compact after send
                controller?.requestPresentationStyle(.compact)
            }
        }
    }

    // MARK: - Helpers

    private func resize(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let scaleFactor = min(widthRatio, heightRatio)

        guard scaleFactor < 1.0 else { return image } // Don't upscale

        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
}
