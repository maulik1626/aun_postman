import UIKit
import UniformTypeIdentifiers

private enum SharedImportConfig {
  static let appGroupIdentifier = "group.com.aunCreations.aunReqStudio.shared"
  static let pendingPayloadKey = "pending_shared_json_import_payload"
  static let importURLScheme = "aunreqstudio"
  static let importURLHost = "shared-import"

  static func sharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: appGroupIdentifier)
  }

  static func clearPendingPayload() {
    sharedDefaults()?.removeObject(forKey: pendingPayloadKey)
    sharedDefaults()?.synchronize()
  }
}

final class ShareViewController: UIViewController {
  private let statusLabel = UILabel()
  private let detailLabel = UILabel()
  private let activityIndicator = UIActivityIndicatorView(style: .large)
  private let doneButton = UIButton(type: .system)
  private let cancelButton = UIButton(type: .system)

  override func viewDidLoad() {
    super.viewDidLoad()
    configureUI()
    beginImport()
  }

  private func configureUI() {
    view.backgroundColor = .systemBackground

    statusLabel.font = .preferredFont(forTextStyle: .title2)
    statusLabel.textAlignment = .center
    statusLabel.numberOfLines = 0
    statusLabel.text = "Preparing import"

    detailLabel.font = .preferredFont(forTextStyle: .body)
    detailLabel.textAlignment = .center
    detailLabel.numberOfLines = 0
    detailLabel.textColor = .secondaryLabel
    detailLabel.text = "ReqStudio is preparing this JSON file so you can finish the import inside the app."

    activityIndicator.startAnimating()

    var doneConfig = UIButton.Configuration.filled()
    doneConfig.title = "Done"
    doneConfig.cornerStyle = .large
    doneButton.configuration = doneConfig
    doneButton.isHidden = true
    doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

    var cancelConfig = UIButton.Configuration.plain()
    cancelConfig.title = "Cancel import"
    cancelButton.configuration = cancelConfig
    cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

    let stack = UIStackView(arrangedSubviews: [
      statusLabel,
      detailLabel,
      activityIndicator,
      doneButton,
      cancelButton,
    ])
    stack.axis = .vertical
    stack.spacing = 16
    stack.alignment = .fill
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  private func beginImport() {
    guard let provider = firstSupportedProvider() else {
      showFailure(
        title: "Unsupported file",
        detail: "ReqStudio can import Postman collection JSON and environment JSON from the iOS share sheet."
      )
      return
    }

    loadSharedFile(from: provider) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        switch result {
        case .success(let payload):
          self.persist(payload: payload)
          self.showSuccess(fileName: payload.fileName)
        case .failure(let error):
          self.showFailure(
            title: "Import unavailable",
            detail: error.localizedDescription
          )
        }
      }
    }
  }

  private func firstSupportedProvider() -> NSItemProvider? {
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    for item in items {
      for provider in item.attachments ?? [] {
        if supportedTypeIdentifier(for: provider) != nil {
          return provider
        }
      }
    }
    return nil
  }

  private func supportedTypeIdentifier(for provider: NSItemProvider) -> String? {
    let jsonIdentifier = UTType.json.identifier
    if provider.hasItemConformingToTypeIdentifier(jsonIdentifier) {
      return jsonIdentifier
    }

    let matchingIdentifier = provider.registeredTypeIdentifiers.first { identifier in
      guard let type = UTType(identifier) else { return false }
      return type.conforms(to: .json)
    }
    if let matchingIdentifier {
      return matchingIdentifier
    }

    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
       let suggestedName = provider.suggestedName?.lowercased(),
       suggestedName.hasSuffix(".json") {
      return UTType.fileURL.identifier
    }

    return nil
  }

  private func loadSharedFile(
    from provider: NSItemProvider,
    completion: @escaping (Result<PendingSharedImportPayload, Error>) -> Void
  ) {
    guard let typeIdentifier = supportedTypeIdentifier(for: provider) else {
      completion(.failure(ShareImportError.unsupportedType))
      return
    }

    if typeIdentifier == UTType.fileURL.identifier {
      provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
        if let error {
          completion(.failure(error))
          return
        }
        guard let sourceURL = self.extractURL(from: item) else {
          completion(.failure(ShareImportError.invalidItem))
          return
        }
        completion(self.copyIntoSharedContainer(sourceURL: sourceURL, provider: provider))
      }
      return
    }

    provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
      if let error {
        completion(.failure(error))
        return
      }
      guard let sourceURL = url else {
        completion(.failure(ShareImportError.invalidItem))
        return
      }
      completion(self.copyIntoSharedContainer(sourceURL: sourceURL, provider: provider))
    }
  }

  private func extractURL(from item: NSSecureCoding?) -> URL? {
    if let url = item as? URL {
      return url
    }
    if let data = item as? Data,
       let url = URL(dataRepresentation: data, relativeTo: nil) {
      return url
    }
    return nil
  }

  private func copyIntoSharedContainer(
    sourceURL: URL,
    provider: NSItemProvider
  ) -> Result<PendingSharedImportPayload, Error> {
    do {
      guard let baseURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: SharedImportConfig.appGroupIdentifier
      ) else {
        return .failure(ShareImportError.sharedContainerUnavailable)
      }

      let importsDirectory = baseURL.appendingPathComponent(
        "SharedJsonImports",
        isDirectory: true
      )
      try FileManager.default.createDirectory(
        at: importsDirectory,
        withIntermediateDirectories: true
      )

      let rawName = provider.suggestedName ?? sourceURL.lastPathComponent
      let safeName = sanitizeFileName(rawName)
      let targetURL = importsDirectory.appendingPathComponent(
        "\(UUID().uuidString)_\(safeName)",
        isDirectory: false
      )

      if FileManager.default.fileExists(atPath: targetURL.path) {
        try FileManager.default.removeItem(at: targetURL)
      }

      try FileManager.default.copyItem(at: sourceURL, to: targetURL)

      return .success(
        PendingSharedImportPayload(
          path: targetURL.path,
          fileName: safeName,
          mimeType: "application/json",
          action: "share_extension"
        )
      )
    } catch {
      return .failure(error)
    }
  }

  private func sanitizeFileName(_ fileName: String) -> String {
    let sanitized = fileName.replacingOccurrences(
      of: #"[^A-Za-z0-9._-]"#,
      with: "_",
      options: .regularExpression
    )
    if sanitized.lowercased().hasSuffix(".json") {
      return sanitized
    }
    let base = sanitized.isEmpty ? "shared" : sanitized
    return "\(base).json"
  }

  private func persist(payload: PendingSharedImportPayload) {
    let defaults = SharedImportConfig.sharedDefaults()
    defaults?.set(payload.asDictionary, forKey: SharedImportConfig.pendingPayloadKey)
    defaults?.synchronize()
  }

  private func showSuccess(fileName: String) {
    activityIndicator.stopAnimating()
    statusLabel.text = "Saved for import"
    detailLabel.text = "\"\(fileName)\" is ready. Open ReqStudio and you’ll land on Import / Export to finish the import."
    doneButton.isHidden = false
    var cancelConfig = cancelButton.configuration ?? .plain()
    cancelConfig.title = "Discard import"
    cancelButton.configuration = cancelConfig
  }

  private func showFailure(
    title: String,
    detail: String
  ) {
    activityIndicator.stopAnimating()
    statusLabel.text = title
    detailLabel.text = detail
    doneButton.isHidden = true
    var cancelConfig = cancelButton.configuration ?? .plain()
    cancelConfig.title = "Close"
    cancelButton.configuration = cancelConfig
  }

  @objc private func doneTapped() {
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }

  @objc private func cancelTapped() {
    SharedImportConfig.clearPendingPayload()
    extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
  }
}

private struct PendingSharedImportPayload {
  let path: String
  let fileName: String
  let mimeType: String
  let action: String

  var asDictionary: [String: Any] {
    [
      "path": path,
      "fileName": fileName,
      "mimeType": mimeType,
      "action": action,
    ]
  }
}

private enum ShareImportError: LocalizedError {
  case unsupportedType
  case invalidItem
  case sharedContainerUnavailable

  var errorDescription: String? {
    switch self {
    case .unsupportedType:
      return "This attachment is not a supported JSON file."
    case .invalidItem:
      return "The shared item could not be read."
    case .sharedContainerUnavailable:
      return "ReqStudio could not access its shared container."
    }
  }
}
