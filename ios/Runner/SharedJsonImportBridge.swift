import Flutter
import Foundation
import UniformTypeIdentifiers

enum SharedJsonImportStore {
  static let pendingPayloadKey = "pending_shared_json_import_payload"
  private static let importsDirectoryName = "IncomingJsonImports"

  static func sharedDefaults() -> UserDefaults {
    UserDefaults.standard
  }

  static func canHandle(url: URL) -> Bool {
    guard url.isFileURL else { return false }
    if url.pathExtension.lowercased() == "json" {
      return true
    }
    if let contentType = fileContentType(for: url) {
      return contentType.conforms(to: .json)
    }
    if let fileType = UTType(filenameExtension: url.pathExtension) {
      return fileType.conforms(to: .json)
    }
    return false
  }

  static func consumePendingPayload() -> [String: Any]? {
    let defaults = sharedDefaults()
    guard let payload = defaults.dictionary(forKey: pendingPayloadKey) else {
      return nil
    }
    defaults.removeObject(forKey: pendingPayloadKey)
    return sanitize(payload: payload)
  }

  static func storePendingPayload(_ payload: [String: Any]) {
    sharedDefaults().set(payload, forKey: pendingPayloadKey)
  }

  static func preparePayload(from sourceURL: URL) throws -> [String: Any] {
    let fileName = sanitizeFileName(sourceURL.lastPathComponent)
    let didAccessSecurityScopedResource = sourceURL.startAccessingSecurityScopedResource()
    defer {
      if didAccessSecurityScopedResource {
        sourceURL.stopAccessingSecurityScopedResource()
      }
    }

    let destinationURL = try destinationURL(for: sourceURL)
    let coordinator = NSFileCoordinator()
    var coordinationError: NSError?
    var copyError: Error?

    coordinator.coordinate(readingItemAt: sourceURL, options: [], error: &coordinationError) { readableURL in
      do {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: destinationURL.path) {
          try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: readableURL, to: destinationURL)
      } catch {
        copyError = error
      }
    }

    if let coordinationError {
      throw coordinationError
    }
    if let copyError {
      throw copyError
    }

    return [
      "path": destinationURL.path,
      "fileName": fileName,
      "mimeType": "application/json",
      "action": "open",
    ]
  }

  private static func destinationURL(for sourceURL: URL) throws -> URL {
    guard let cachesDirectory = FileManager.default.urls(
      for: .cachesDirectory,
      in: .userDomainMask
    ).first else {
      throw NSError(
        domain: "SharedJsonImport",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not access the app cache directory."]
      )
    }

    let importsDirectory = cachesDirectory.appendingPathComponent(
      importsDirectoryName,
      isDirectory: true
    )
    try FileManager.default.createDirectory(
      at: importsDirectory,
      withIntermediateDirectories: true
    )

    let safeName = sanitizeFileName(sourceURL.lastPathComponent)
    return importsDirectory.appendingPathComponent(
      "\(UUID().uuidString)_\(safeName)",
      isDirectory: false
    )
  }

  private static func fileContentType(for url: URL) -> UTType? {
    if let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
       let contentType = resourceValues.contentType {
      return contentType
    }
    return nil
  }

  private static func sanitizeFileName(_ rawName: String) -> String {
    let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
    let fallback = trimmed.isEmpty ? "shared.json" : trimmed
    let invalidCharacters = CharacterSet(charactersIn: "/:\\?%*|\"<>")
    let cleanedScalars = fallback.unicodeScalars.map { scalar in
      invalidCharacters.contains(scalar) ? "_" : Character(scalar)
    }
    let cleaned = String(cleanedScalars)
    return cleaned.isEmpty ? "shared.json" : cleaned
  }

  private static func sanitize(payload: [String: Any]) -> [String: Any]? {
    guard let path = payload["path"] as? String,
          let fileName = payload["fileName"] as? String,
          let mimeType = payload["mimeType"] as? String,
          let action = payload["action"] as? String,
          !path.isEmpty else {
      return nil
    }

    let normalizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
    guard let cachesDirectory = FileManager.default.urls(
      for: .cachesDirectory,
      in: .userDomainMask
    ).first else {
      return nil
    }
    let allowedPrefix = cachesDirectory
      .appendingPathComponent(importsDirectoryName, isDirectory: true)
      .standardizedFileURL
      .path
    guard normalizedPath.hasPrefix(allowedPrefix) else {
      return nil
    }

    return [
      "path": normalizedPath,
      "fileName": fileName,
      "mimeType": mimeType,
      "action": action,
    ]
  }
}

final class SharedJsonImportPlugin: NSObject, FlutterStreamHandler {
  static let shared = SharedJsonImportPlugin()

  private var eventSink: FlutterEventSink?

  func register(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: "com.aun.reqstudio/shared_json_import",
      binaryMessenger: messenger
    )
    methodChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getInitialSharedJson":
        result(SharedJsonImportStore.consumePendingPayload())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: "com.aun.reqstudio/shared_json_import/events",
      binaryMessenger: messenger
    )
    eventChannel.setStreamHandler(self)
  }

  @discardableResult
  func handleIncomingURL(_ url: URL) -> Bool {
    guard SharedJsonImportStore.canHandle(url: url) else { return false }
    do {
      let payload = try SharedJsonImportStore.preparePayload(from: url)
      SharedJsonImportStore.storePendingPayload(payload)
    } catch {
      return false
    }
    dispatchPendingPayloadIfPossible()
    return true
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    dispatchPendingPayloadIfPossible()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func dispatchPendingPayloadIfPossible() {
    guard let eventSink,
          let payload = SharedJsonImportStore.consumePendingPayload() else {
      return
    }
    eventSink(payload)
  }
}
