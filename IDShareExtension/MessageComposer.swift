import UIKit
import Messages

// MARK: - MessageComposer
// Sends the IDShare landing page URL as plain text.
// iMessage auto-generates a rich link preview from the page's OG meta tags.
// This ensures the link works for ALL recipients — no extension required.

final class MessageComposer {

    // MARK: - State
    private(set) var cachedAlbumArt: UIImage?

    // MARK: - Album Art Download
    // Used for the in-extension preview card (before send).

    func prefetchAlbumArt(from url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                cachedAlbumArt = resize(image, to: CGSize(width: 600, height: 600))
            }
        } catch {
            cachedAlbumArt = nil
        }
    }

    func clearCache() {
        cachedAlbumArt = nil
    }

    // MARK: - Send

    /// Inserts the landing page URL as plain text into the conversation input field.
    /// iMessage auto-generates a rich link preview from OG tags.
    /// The user taps the send arrow to send — standard iMessage behavior.
    func send(song: SongData, in conversation: MSConversation, controller: MSMessagesAppViewController) {
        let text = "\(song.landingPageURL.absoluteString)"

        conversation.insertText(text) { [weak controller] error in
            if let error = error {
                print("[IDShare] Failed to insert text: \(error.localizedDescription)")
            } else {
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

        guard scaleFactor < 1.0 else { return image }

        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
}
