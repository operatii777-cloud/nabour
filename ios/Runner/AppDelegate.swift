import Flutter
import UIKit

/// Stub pentru canalele din `BleBumpService` (Dart); fără înregistrare apare MissingPluginException.
private final class BleBumpEventStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: FlutterEventSink?) -> FlutterError? {
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let messenger = controller.engine.binaryMessenger
      let method = FlutterMethodChannel(name: "com.nabour/ble_bump", binaryMessenger: messenger)
      method.setMethodCallHandler { call, result in
        switch call.method {
        case "start", "stop":
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      let events = FlutterEventChannel(name: "com.nabour/ble_bump_events", binaryMessenger: messenger)
      events.setStreamHandler(BleBumpEventStreamHandler())
    }
    return ok
  }
}
