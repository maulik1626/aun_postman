import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let url = connectionOptions.urlContexts.first?.url {
      _ = SharedJsonImportPlugin.shared.handleIncomingURL(url)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let unhandledContexts = Set(URLContexts.filter { context in
      !SharedJsonImportPlugin.shared.handleIncomingURL(context.url)
    })
    if !unhandledContexts.isEmpty {
      super.scene(scene, openURLContexts: unhandledContexts)
    }
  }
}
