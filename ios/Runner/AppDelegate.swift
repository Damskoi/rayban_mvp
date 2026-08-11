import Flutter
import UIKit
import MWDATCore
import MWDATCamera

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var session: DeviceSession?
  private var stream: MWDATCamera.Stream?
  private var frameSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Initialiser le SDK Meta Wearables
    do {
      try Wearables.configure()
    } catch {
      print("Failed to configure Wearables SDK: \(error)")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RayBanMVP")
    let messenger = registrar.messenger()
    
    // 2. Création du Method Channel pour les commandes
    let cameraChannel = FlutterMethodChannel(name: "com.rayban.meta/camera",
                                              binaryMessenger: messenger)
    cameraChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "startStream" {
        self?.startStream(result: result)
      } else if call.method == "takePhoto" {
        self?.takePhoto(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    // 3. Création du Event Channel pour le flux vidéo (images binaires)
    let videoChannel = FlutterEventChannel(name: "com.rayban.meta/video",
                                           binaryMessenger: messenger)
    videoChannel.setStreamHandler(VideoEventHandler(appDelegate: self))
  }

  private func startStream(result: @escaping FlutterResult) {
    Task {
      do {
        let wearables = Wearables.shared
        
        // Optionnel : Lancement de l'enregistrement si non enregistré
        // try wearables.startRegistration()

        // 4. Demander la permission caméra des lunettes
        let status = try await wearables.requestPermission(.camera)
        if status != .granted {
           result(FlutterError(code: "PERMISSION_DENIED", message: "Permission caméra refusée", details: nil))
           return
        }

        // 5. Créer la session et se connecter aux lunettes
        let deviceSelector = AutoDeviceSelector(wearables: wearables)
        self.session = try wearables.createSession(deviceSelector: deviceSelector)
        try self.session?.start()

        // 6. Configurer la résolution basse pour limiter la latence Bluetooth
        let config = StreamConfiguration(
          videoCodec: VideoCodec.raw,
          resolution: StreamingResolution.low,
          frameRate: 24)

        if let camera = try self.session?.addCamera(config: config) {
          self.stream = camera.stream
          
          // 7. Écouter les images et les envoyer vers Flutter via EventChannel
          _ = self.stream?.videoFramePublisher.listen { frame in
             if let image = frame.makeUIImage(), let data = image.jpegData(compressionQuality: 0.5) {
                DispatchQueue.main.async {
                   self.frameSink?(data) // Envoi des bytes compressés à Flutter
                }
             }
          }
          self.stream?.start()
          result(true)
        } else {
          result(false)
        }
      } catch {
        result(FlutterError(code: "STREAM_ERROR", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func takePhoto(result: @escaping FlutterResult) {
    if let stream = self.stream {
       // 8. Capture photo via la caméra
       stream.capturePhoto(format: .jpeg)
       result(true)
    } else {
       result(FlutterError(code: "NO_STREAM", message: "Le flux n'est pas démarré", details: nil))
    }
  }

  func setFrameSink(_ sink: FlutterEventSink?) {
     self.frameSink = sink
  }
}

class VideoEventHandler: NSObject, FlutterStreamHandler {
    weak var appDelegate: AppDelegate?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        appDelegate?.setFrameSink(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        appDelegate?.setFrameSink(nil)
        return nil
    }
}
