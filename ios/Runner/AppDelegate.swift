import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications
import MessageUI

// MARK: - iCloud Documents backup (MethodChannel com.aun.reqstudio/icloud_backup)

private enum IcloudBackupPlugin {
  static let channelName = "com.aun.reqstudio/icloud_backup"
  static let containerId = "iCloud.com.aunCreations.aunReqStudio"
  static let backupFileName = "aun_reqstudio_iCloud_backup.json"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler(handle(call:result:))
  }

  private static func ubiquityDocumentsDirectory() -> URL? {
    guard let base = FileManager.default.url(
      forUbiquityContainerIdentifier: containerId
    ) else {
      return nil
    }
    return base.appendingPathComponent("Documents", isDirectory: true)
  }

  private static func ubiquityBackupFileURL() -> URL? {
    guard let docs = ubiquityDocumentsDirectory() else { return nil }
    return docs.appendingPathComponent(backupFileName, isDirectory: false)
  }

  private static func ensureDocumentsDir() throws {
    guard let docs = ubiquityDocumentsDirectory() else {
      throw NSError(
        domain: "IcloudBackup",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "iCloud container unavailable"]
      )
    }
    let fm = FileManager.default
    if !fm.fileExists(atPath: docs.path) {
      try fm.createDirectory(at: docs, withIntermediateDirectories: true, attributes: nil)
    }
  }

  private static func writeUbiquitous(data: Data, to dest: URL) throws {
    try ensureDocumentsDir()
    let fm = FileManager.default
    let coordinator = NSFileCoordinator()
    var coordinationError: NSError?
    var writeError: Error?
    let opts: NSFileCoordinator.WritingOptions = fm.fileExists(atPath: dest.path) ? .forReplacing : []
    coordinator.coordinate(writingItemAt: dest, options: opts, error: &coordinationError) { url in
      do {
        try data.write(to: url, options: .atomic)
      } catch {
        writeError = error
      }
    }
    if let coordinationError { throw coordinationError }
    if let writeError { throw writeError }
  }

  private static func readUbiquitous(from src: URL) throws -> Data {
    let coordinator = NSFileCoordinator()
    var coordinationError: NSError?
    var fileData: Data?
    var readError: Error?
    coordinator.coordinate(readingItemAt: src, options: [], error: &coordinationError) { url in
      do {
        fileData = try Data(contentsOf: url)
      } catch {
        readError = error
      }
    }
    if let coordinationError { throw coordinationError }
    if let readError { throw readError }
    guard let fileData else {
      throw NSError(
        domain: "IcloudBackup",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Could not read iCloud backup"]
      )
    }
    return fileData
  }

  private static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      let ok = ubiquityDocumentsDirectory() != nil
      result(ok)

    case "backupExists":
      guard let dest = ubiquityBackupFileURL() else {
        result(false)
        return
      }
      result(FileManager.default.fileExists(atPath: dest.path))

    case "backupModifiedMsSinceEpoch":
      DispatchQueue.global(qos: .utility).async {
        guard let dest = ubiquityBackupFileURL(),
              FileManager.default.fileExists(atPath: dest.path) else {
          DispatchQueue.main.async { result(nil) }
          return
        }
        do {
          let ms = try modificationDateMs(for: dest)
          DispatchQueue.main.async { result(ms > 0 ? ms : nil) }
        } catch {
          DispatchQueue.main.async { result(nil) }
        }
      }

    case "copyToICloud":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "bad_args", message: "Missing path", details: nil))
        return
      }
      let src = URL(fileURLWithPath: path)
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let dest = ubiquityBackupFileURL() else {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "unavailable",
                message: "iCloud is not available. Sign in to iCloud and ensure iCloud Drive is on.",
                details: nil
              ))
            }
            return
          }
          let data = try Data(contentsOf: src)
          try writeUbiquitous(data: data, to: dest)
          DispatchQueue.main.async { result(nil) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "io", message: error.localizedDescription, details: nil))
          }
        }
      }

    case "copyFromICloudToTemp":
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let src = ubiquityBackupFileURL(),
                FileManager.default.fileExists(atPath: src.path) else {
            DispatchQueue.main.async { result(nil) }
            return
          }
          let data = try readUbiquitous(from: src)
          let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("icloud_backup_\(UUID().uuidString).json")
          try data.write(to: tmp, options: .atomic)
          DispatchQueue.main.async { result(tmp.path) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "io", message: error.localizedDescription, details: nil))
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func modificationDateMs(for dest: URL) throws -> Double {
    var ms: Double = 0
    let coordinator = NSFileCoordinator()
    var coordinationError: NSError?
    coordinator.coordinate(readingItemAt: dest, options: [], error: &coordinationError) { url in
      if let vals = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
         let d = vals.contentModificationDate {
        ms = d.timeIntervalSince1970 * 1000
      }
    }
    if let coordinationError { throw coordinationError }
    return ms
  }
}

private final class ScreenshotEventsPlugin: NSObject, FlutterStreamHandler {
  private let channel: FlutterEventChannel
  private var eventSink: FlutterEventSink?
  private var observer: NSObjectProtocol?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterEventChannel(
      name: "com.aun.reqstudio/screenshot_events",
      binaryMessenger: messenger
    )
    super.init()
    channel.setStreamHandler(self)
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    observer = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.eventSink?([
        "platform": "ios",
        "takenAtMs": Int(Date().timeIntervalSince1970 * 1000)
      ])
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer {
      NotificationCenter.default.removeObserver(observer)
      self.observer = nil
    }
    eventSink = nil
    return nil
  }
}

private final class FeedbackEmailPlugin: NSObject, MFMailComposeViewControllerDelegate {
  private let channel: FlutterMethodChannel
  private weak var presenter: UIViewController?
  private var pendingResult: FlutterResult?

  init(messenger: FlutterBinaryMessenger, presenter: UIViewController) {
    channel = FlutterMethodChannel(
      name: "com.aun.reqstudio/feedback_email",
      binaryMessenger: messenger
    )
    self.presenter = presenter
    super.init()
    channel.setMethodCallHandler(handle)
  }

  func updatePresenter(_ presenter: UIViewController) {
    self.presenter = presenter
  }

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "composeEmail" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard MFMailComposeViewController.canSendMail() else {
      result(
        FlutterError(
          code: "mail_unavailable",
          message: "No mail account is configured on this device.",
          details: nil
        )
      )
      return
    }

    guard pendingResult == nil else {
      result(
        FlutterError(
          code: "mail_busy",
          message: "An email composer is already open.",
          details: nil
        )
      )
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let to = args["to"] as? [String],
      let subject = args["subject"] as? String,
      let body = args["body"] as? String,
      let attachmentPath = args["attachmentPath"] as? String
    else {
      result(FlutterError(code: "bad_args", message: "Missing email fields.", details: nil))
      return
    }

    let mimeType = (args["attachmentMimeType"] as? String) ?? "image/png"
    let attachmentName = (args["attachmentName"] as? String) ?? "aun_reqstudio_feedback.png"

    guard let presenter = topPresenter(from: presenter) else {
      result(FlutterError(code: "no_presenter", message: "Cannot present email composer.", details: nil))
      return
    }

    let composer = MFMailComposeViewController()
    composer.mailComposeDelegate = self
    composer.setToRecipients(to)
    composer.setSubject(subject)
    composer.setMessageBody(body, isHTML: false)

    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: attachmentPath))
      composer.addAttachmentData(data, mimeType: mimeType, fileName: attachmentName)
    } catch {
      result(
        FlutterError(
          code: "attachment_read_failed",
          message: "Could not read the screenshot attachment.",
          details: nil
        )
      )
      return
    }

    pendingResult = result
    presenter.present(composer, animated: true)
  }

  func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult,
    error: Error?
  ) {
    controller.dismiss(animated: true)
    if let error {
      pendingResult?(
        FlutterError(
          code: "mail_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    } else {
      pendingResult?(nil)
    }
    pendingResult = nil
  }

  private func topPresenter(from root: UIViewController?) -> UIViewController? {
    var current = root
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var screenshotEventsPlugin: ScreenshotEventsPlugin?
  private var feedbackEmailPlugin: FeedbackEmailPlugin?
  private let sharedJsonImportPlugin = SharedJsonImportPlugin.shared

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if sharedJsonImportPlugin.handleIncomingURL(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    IcloudBackupPlugin.register(messenger: messenger)
    screenshotEventsPlugin = ScreenshotEventsPlugin(messenger: messenger)
    sharedJsonImportPlugin.register(messenger: messenger)
    if let rootController = window?.rootViewController {
      if let feedbackEmailPlugin {
        feedbackEmailPlugin.updatePresenter(rootController)
      } else {
        feedbackEmailPlugin = FeedbackEmailPlugin(
          messenger: messenger,
          presenter: rootController
        )
      }
    }
  }
}
