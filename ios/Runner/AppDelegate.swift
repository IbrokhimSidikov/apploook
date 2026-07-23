import UIKit
import Flutter
import YandexMapsMobile
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize Firebase
    FirebaseApp.configure()
    
    // Set Yandex Maps API Key
    YMKMapKit.setApiKey("7829b061-64f7-4387-89f8-dab711940e2f")

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    setupLiveActivityChannel()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Live Activity bridge

  private func setupLiveActivityChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: "com.loook.apploook/live_activity",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in
      guard #available(iOS 16.2, *) else {
        result(FlutterError(code: "UNSUPPORTED",
                            message: "Live Activities require iOS 16.2+",
                            details: nil))
        return
      }

      let manager = LiveActivityManager.shared
      // Forward push tokens to Dart so they can be registered with OneSignal.
      manager.onPushToken = { activityId, token in
        DispatchQueue.main.async {
          channel.invokeMethod("onPushToken", arguments: [
            "activityId": activityId,
            "token": token,
          ])
        }
      }

      let args = call.arguments as? [String: Any] ?? [:]

      switch call.method {
      case "areActivitiesEnabled":
        result(manager.areActivitiesEnabled())

      case "startActivity":
        guard let orderId = args["orderId"] as? String,
              let state = Self.contentState(from: args) else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing order data", details: nil))
          return
        }
        let branchName = args["branchName"] as? String ?? ""
        do {
          let id = try manager.start(orderId: orderId, branchName: branchName, state: state)
          result(id)
        } catch {
          result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
        }

      case "updateActivity":
        guard let id = args["activityId"] as? String,
              let state = Self.contentState(from: args) else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing activity data", details: nil))
          return
        }
        Task { await manager.update(id: id, state: state); result(nil) }

      case "endActivity":
        guard let id = args["activityId"] as? String else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing activityId", details: nil))
          return
        }
        let finalState = Self.contentState(from: args)
        Task { await manager.end(id: id, finalState: finalState); result(nil) }

      case "endAll":
        Task { await manager.endAll(); result(nil) }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 16.2, *)
  private static func contentState(from args: [String: Any]) -> OrderActivityAttributes.ContentState? {
    guard let statusKey = args["statusKey"] as? String,
          let statusText = args["statusText"] as? String,
          let stepIndex = args["stepIndex"] as? Int else {
      return nil
    }
    let eta = args["etaMinutes"] as? Int ?? 0
    return OrderActivityAttributes.ContentState(
      statusKey: statusKey,
      statusText: statusText,
      stepIndex: stepIndex,
      etaMinutes: eta
    )
  }

  // Handle custom URL scheme
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Let Flutter handle the URL
    return super.application(app, open: url, options: options)
  }
}
