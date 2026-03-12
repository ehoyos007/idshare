import UIKit
import Messages

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
        v.backgroundColor = UIColor(white: 0.1, alpha: 1) // dark iMessage-ish background
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // --- Compact state ---

    private lazy var urlTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Paste a Spotify, Apple Music, or SoundCloud link"
        tf.placeholderTextColor(.tertiaryLabel)
        tf.textColor = .white
        tf.backgroundColor = UIColor(white: 0.2, alpha: 1)
        tf.layer.cornerRadius = 10
        tf.setLeftPaddingPoints(12)
        tf.setRightPaddingPoints(12)
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

    private lazy var lookUpButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Look Up"
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
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 14)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // --- Expanded state (preview card) ---

    private lazy var albumArtView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(white: 0.15, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var songTitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = .white
        l.font = .boldSystemFont(ofSize: 16)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var artistLabel: UILabel = {
        let l = UILabel()
        l.textColor = .secondaryLabel
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
        setupUI()
        readClipboard()
    }

    // MARK: - Clipboard

    private func readClipboard() {
        guard let result = ClipboardReader.readMusicURL() else { return }
        urlTextField.text = result.content
        lookUpButton.isEnabled = true
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
        [urlTextField, lookUpButton,
         activityIndicator, loadingLabel,
         albumArtView, songTitleLabel, artistLabel, sendButton,
         errorLabel, retryButton].forEach { containerView.addSubview($0) }

        // Layout constraints
        NSLayoutConstraint.activate([
            // URL text field
            urlTextField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            urlTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            urlTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            urlTextField.heightAnchor.constraint(equalToConstant: 44),

            // Look Up button
            lookUpButton.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 12),
            lookUpButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            lookUpButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            lookUpButton.heightAnchor.constraint(equalToConstant: 44),

            // Loading state
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: lookUpButton.bottomAnchor, constant: 24),
            loadingLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 8),
            loadingLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            // Album art (expanded)
            albumArtView.topAnchor.constraint(equalTo: lookUpButton.bottomAnchor, constant: 16),
            albumArtView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            albumArtView.widthAnchor.constraint(equalToConstant: 80),
            albumArtView.heightAnchor.constraint(equalToConstant: 80),

            // Song info
            songTitleLabel.topAnchor.constraint(equalTo: albumArtView.topAnchor),
            songTitleLabel.leadingAnchor.constraint(equalTo: albumArtView.trailingAnchor, constant: 12),
            songTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            artistLabel.topAnchor.constraint(equalTo: songTitleLabel.bottomAnchor, constant: 4),
            artistLabel.leadingAnchor.constraint(equalTo: songTitleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(equalTo: songTitleLabel.trailingAnchor),

            // Send button
            sendButton.topAnchor.constraint(equalTo: albumArtView.bottomAnchor, constant: 16),
            sendButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            sendButton.heightAnchor.constraint(equalToConstant: 44),

            // Error
            errorLabel.topAnchor.constraint(equalTo: lookUpButton.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
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
            // Album art pre-fetched by now — show placeholder while it loads
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
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        // If user manually collapses back to compact, reset state
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
    func placeholderTextColor(_ color: UIColor) {
        attributedPlaceholder = NSAttributedString(
            string: placeholder ?? "",
            attributes: [.foregroundColor: color]
        )
    }
}
