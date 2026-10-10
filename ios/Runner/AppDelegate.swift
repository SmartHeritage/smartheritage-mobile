import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Đã nạp khoá Google Maps. Thiếu khoá mà vẫn tạo bản đồ thì SDK iOS làm
  /// crash app — Dart hỏi cờ này qua kênh `smartheritage/maps` trước khi vẽ.
  private var mapsConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Khoá nằm ngoài git (ios/Flutter/Secrets.xcconfig → Info.plist GMSApiKey).
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      !key.isEmpty
    {
      GMSServices.provideAPIKey(key)
      mapsConfigured = true
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SmartHeritageMaps") {
      let channel = FlutterMethodChannel(
        name: "smartheritage/maps", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "isConfigured" {
          result(self?.mapsConfigured ?? false)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
