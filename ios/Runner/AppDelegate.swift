import AudioToolbox
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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "UiSoundPlugin") {
      UiSoundPlugin.register(with: registrar)
    }
  }
}

/// UI 효과음 (`tapeletter/ui_sound`) — System Sound Services.
/// 무음 스위치를 따르고, 앱의 AVAudioSession(녹음·재생)을 바꾸지 않아 다른 소리를 끊거나 줄이지 않는다.
final class UiSoundPlugin: NSObject, FlutterPlugin {
  private let registrar: FlutterPluginRegistrar
  private var sounds: [String: SystemSoundID] = [:]

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "tapeletter/ui_sound", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(UiSoundPlugin(registrar: registrar), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "preload":
      // { 이름: Flutter 에셋 경로 }
      for (name, asset) in (call.arguments as? [String: String]) ?? [:] where sounds[name] == nil {
        let key = registrar.lookupKey(forAsset: asset)
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else { continue }
        var id: SystemSoundID = 0
        if AudioServicesCreateSystemSoundID(URL(fileURLWithPath: path) as CFURL, &id) == noErr {
          sounds[name] = id
        }
      }
      result(nil)
    case "play":
      if let name = call.arguments as? String, let id = sounds[name] {
        AudioServicesPlaySystemSound(id)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    for id in sounds.values { AudioServicesDisposeSystemSoundID(id) }
    sounds.removeAll()
  }
}
