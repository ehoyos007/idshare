import SwiftUI

// MARK: - ContentView
// The main app is a required container for the iMessage Extension.
// It doesn't need to do anything — just tell the user to open iMessage.

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 64))
                    .foregroundColor(.white)

                Text("IDShare")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text("One link. Every platform.")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Divider()
                    .background(Color.gray)
                    .padding(.horizontal, 40)

                VStack(spacing: 8) {
                    Text("Open iMessage to use IDShare")
                        .font(.body)
                        .foregroundColor(.secondary)

                    Text("Tap the  button in a conversation,\nthen find IDShare in the app drawer.")
                        .font(.caption)
                        .foregroundColor(.tertiaryLabel)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
