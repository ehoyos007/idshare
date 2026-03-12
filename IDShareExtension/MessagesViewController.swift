import UIKit
import Messages
import UniformTypeIdentifiers

// MARK: - MessagesViewController
// The main extension UI controller.
// Manages three states: compact (initial), loading (API call in flight), expanded (preview ready).
//
// UI Flow:
//   Compact  →  [user taps Look Up]  →  Loading  →  Expanded (on success)
//                                                  →  Error state (on failure)
//   Expanded →  [user taps Send]     →  Message inserted, extension collapses to compact

final class MessagesViewController: MSMessagesAppViewController {

    // MARK: - Services
    private let odesliService = OdesliService()
    private let composer = MessageComposer()

    // MARK: - State
    private var currentSong: SongData?

    private enum ViewState {
        case compact
        case loading
        case expanded(SongData)
        case error(String)
    }

    private var state: ViewState = .compact {
        didSet { applyState() }
    }

    // MARK: - UI Elements

    private lazy var containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.11, alpha: 1)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // --- Compact state ---

    private lazy var urlTextField: UITextField = {
        let tf = UITextField()
        tf.attributedPlaceholder = NSAttributedString(
            string: "Paste a music link...",
            attributes: [.foregroundColor: UIColor(white: 0.55, alpha: 1)]
        )
        tf.textColor = .white
        tf.backgroundColor = UIColor(white: 0.22, alpha: 1)
        tf.layer.cornerRadius = 12
        tf.clipsToBounds = true
        tf.setLeftPaddingPoints(14)
        tf.setRightPaddingPoints(14)
        tf.keyboardType = .URL
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.returnKeyType = .search
        tf.clearButtonMode = .whileEditing
        tf.font = .systemFont(ofSize: 15)
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        tf.delegate = self
        return tf
    }()

    // System paste control — bypasses iOS 16+ clipboard permission restrictions
    private lazy var systemPasteControl: UIPasteControl = {
        var config = UIPasteControl.Configuration()
        config.baseBackgroundColor = UIColor(red: 0.35, green: 0.35, blue: 0.9, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.displayMode = .iconAndLabel
        let pc = UIPasteControl(configuration: config)
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

    private lazy var lookUpButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Look Up Song"
        config.image = UIImage(systemName: "magnifyingglass")
        config.imagePadding = 6
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.isEnabled = false
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(lookUpTapped), for: .touchUpInside)
        return btn
    }()

    // --- Loading state ---

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    private lazy var loadingLabel: UILabel = {
        let l = UILabel()
        l.text = "Looking up song..."
        l.textColor = UIColor(white: 0.7, alpha: 1)
        l.font = .systemFont(ofSize: 14)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // --- Expanded state (preview card) ---

    private lazy var albumArtView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.backgroundColor = UIColor(white: 0.18, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var songTitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .boldSystemFont(ofSize: 17)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var artistLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor(white: 0.65, alpha: 1)
        l.font = .systemFont(ofSize: 14)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Send"
        config.image = UIImage(systemName: "paperplane.fill")
        config.imagePadding = 6
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemBlue
        config.cornerStyle = .medium
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.textColor = .systemRed
        l.font = .systemFont(ofSize: 13)
        l.numberOfLines = 3
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var retryButton: UIButton = {
        var config = UIButton.Configuration.borderless()
        config.title = "Try Again"
        config.baseForegroundColor = .systemBlue
        let btn = UIButton(configuration: config)
        btn.isHidden = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Accept URLs and plain text via UIPasteControl
        self.pasteConfiguration = UIPasteConfiguration(acceptableTypeIdentifiers: [
            UTType.url.identifier,
            UTType.plainText.identifier
        ])
        setupUI()
    }

    // MARK: - System Paste Handler (UIPasteControl callback)

    override func paste(itemProviders: [NSItemProvider]) {
        for provider in itemProviders {
            // Try URL first (Spotify/Apple Music copy as URL)
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, _ in
                    var urlString: String?
                    if let url = item as? URL {
                        urlString = url.absoluteString
                    } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urlString = url.absoluteString
                    }
                    if let urlString = urlString {
                        DispatchQueue.main.async {
                            self?.urlTextField.text = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
                            self?.textFieldDidChange()
                        }
                    }
                }
                return
            }
            // Fall back to plain text
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, _ in
                    if let string = item as? String {
                        DispatchQueue.main.async {
                            self?.urlTextField.text = string.trimmingCharacters(in: .whitespacesAndNewlines)
                            self?.textFieldDidChange()
                        }
                    }
                }
                return
            }
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Add all subviews
        [urlTextField, systemPasteControl, lookUpButton,
         activityIndicator, loadingLabel,
         albumArtView, songTitleLabel, artistLabel, sendButton,
         errorLabel, retryButton].forEach { containerView.addSubview($0) }

        // Layout constraints
        NSLayoutConstraint.activate([
            // URL text field — shares row with system paste control
            urlTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            urlTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            urlTextField.trailingAnchor.constraint(equalTo: systemPasteControl.leadingAnchor, constant: -8),
            urlTextField.heightAnchor.constraint(equalToConstant: 44),

            // System paste control
            systemPasteControl.centerYAnchor.constraint(equalTo: urlTextField.centerYAnchor),
            systemPasteControl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            systemPasteControl.heightAnchor.constraint(equalToConstant: 44),

            // Look Up button
            lookUpButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 10),
            lookUpButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            lookUpButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            lookUpButton.heightAnchor.constraint(equalToConstant: 46),

            // Loading state
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: lookUpButton.bottomAnchor, constant: 24),
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 8),
            loadingLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            // Album art (expanded)
            albumArtView.topAnchor.constraint(equalTo: lookUpButton.bottomAnchor, constant: 16),
            albumArtView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            albumArtView.widthAnchor.constraint(equalToConstant: 80),
            albumArtView.heightAnchor.constraint(equalToConstant: 80),

            // Song info
            songTitleLabel.topAnchor.constraint(equalTo: albumArtView.topAnchor, constant: 4),
            songTitleLabel.leadingAnchor.constraint(equalTo: albumArtView.trailingAnchor, constant: 12),
            songTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            artistLabel.topAnchor.constraint(equalTo: songTitleLabel.bottomAnchor, constant: 4),
            artistLabel.leadingAnchor.constraint(equalTo: songTitleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: songTitleLabel.trailingAnchor),

            // Send button
            sendButton.topAnchor.constraint(equalTo: albumArtView.bottomAnchor, constant: 16),
            sendButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            sendButton.heightAnchor.constraint(equalToConstant: 46),

            // Error
            errorLabel.topAnchor.constraint(equalTo: lookUpButton.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            errorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 8),
            retryButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
        ])

        applyState()
    }

    // MARK: - State Machine

    private func applyState() {
        let isLoading: Bool
        let isExpanded: Bool
        let isError: Bool

        switch state {
        case .compact:
            isLoading = false; isExpanded = false; isError = false
        case .loading:
            isLoading = true; isExpanded = false; isError = false
            lookUpButton.isEnabled = false
        case .expanded(let song):
            isLoading = false; isExpanded = true; isError = false
            songTitleLabel.text = song.title
            artistLabel.text = song.artist
            albumArtView.image = composer.cachedAlbumArt ?? UIImage(systemName: "music.note")
        case .error(let message):
            isLoading = false; isExpanded = false; isError = true
            errorLabel.text = message
            lookUpButton.isEnabled = true
        }

        activityIndicator.isHidden = !isLoading
        loadingLabel.isHidden = !isLoading
        if isLoading { activityIndicator.startAnimating() } else { activityIndicator.stopAnimating() }

        albumArtView.isHidden = !isExpanded
        songTitleLabel.isHidden = !isExpanded
        artistLabel.isHidden = !isExpanded
        sendButton.isHidden = !isExpanded

        errorLabel.isHidden = !isError
        retryButton.isHidden = !isError
    }

    // MARK: - Actions

    @objc private func textFieldDidChange() {
        let input = urlTextField.text ?? ""
        lookUpButton.isEnabled = URLValidator.isValid(input)
        // Clear error if user is editing
        if case .error = state { state = .compact }
    }

    @objc private func lookUpTapped() {
        guard let input = urlTextField.text, URLValidator.isValid(input) else { return }
        urlTextField.resignFirstResponder()
        performLookup(url: input)
    }

    @objc private func retryTapped() {
        guard let input = urlTextField.text, URLValidator.isValid(input) else { return }
        performLookup(url: input)
    }

    @objc private func sendTapped() {
        guard let song = currentSong,
              let conversation = activeConversation else { return }
        composer.send(song: song, in: conversation, controller: self)
    }

    // MARK: - Lookup

    private func performLookup(url: String) {
        state = .loading

        Task {
            do {
                let song = try await odesliService.resolve(url: url)
                currentSong = song

                // Pre-fetch album art during preview phase so send is instant
                if let artURL = song.albumArtURL {
                    await composer.prefetchAlbumArt(from: artURL)
                }

                await MainActor.run {
                    state = .expanded(song)
                    requestPresentationStyle(.expanded)
                }
            } catch {
                await MainActor.run {
                    let message = (error as? OdesliError)?.errorDescription ?? error.localizedDescription
                    state = .error(message)
                }
            }
        }
    }

    // MARK: - MSMessagesAppViewController Overrides

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        // Reset to clean state each time the extension opens
        currentSong = nil
        composer.clearCache()
        state = .compact
        urlTextField.text = ""
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        if presentationStyle == .compact && currentSong == nil {
            state = .compact
        }
    }
}

// MARK: - UITextFieldDelegate
extension MessagesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        lookUpTapped()
        return true
    }
}

// MARK: - UITextField Helpers
private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.size.height))
        leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount: CGFloat) {
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.size.height))
        rightViewMode = .always
    }
}
