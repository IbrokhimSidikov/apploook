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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle custom URL scheme
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    
    // Check if the URL scheme matches the custom scheme
    if url.scheme == "app-1-87012829234-ios-1d206beel565cdc288f42b" {
        print("Custom URL scheme detected: \(url.absoluteString)")
        return true
    }

    return false
  }
}
