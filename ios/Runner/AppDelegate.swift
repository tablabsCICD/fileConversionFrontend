import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StorageInfoChannel") {
      let channel = FlutterMethodChannel(
        name: "file_convertor/storage",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getCapacity":
          result(AppDelegate.capacity())
        default:
          // Per-category media usage is not available inside the iOS sandbox.
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  /// Device capacity as reported in Settings › General › iPhone Storage.
  private static func capacity() -> [String: Int64] {
    let url = URL(fileURLWithPath: NSHomeDirectory())
    let values = try? url.resourceValues(forKeys: [
      .volumeTotalCapacityKey,
      .volumeAvailableCapacityForImportantUsageKey,
    ])
    return [
      "totalBytes": Int64(values?.volumeTotalCapacity ?? 0),
      "freeBytes": values?.volumeAvailableCapacityForImportantUsage ?? 0,
    ]
  }
}
