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
    
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RayBanMVP") else { return }
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

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    Task {
      do {
        _ = try await Wearables.shared.handleUrl(url)
        print("Wearables handleUrl success for: \(url)")
      } catch {
        print("Wearables handleUrl error: \(error)")
      }
    }
    return super.application(app, open: url, options: options)
  }

  private func startStream(result: @escaping FlutterResult) {
    Task {
      do {
        let wearables = Wearables.shared
        
        // 1. Check registration state
        if wearables.registrationState != .registered {
           print("Not registered. Starting registration flow...")
           try await wearables.startRegistration()
        }

        // 2. Request camera permission
        print("Checking camera permission...")
        let currentStatus = try await wearables.checkPermissionStatus(.camera)
        if currentStatus != .granted {
            print("Requesting camera permission...")
            let status = try await wearables.requestPermission(.camera)
            if status != .granted {
               result(FlutterError(code: "PERMISSION_DENIED", message: "Permission caméra refusée", details: nil))
               return
            }
        }

        // 3. Wait for device connection (Meta View app can take a few seconds to establish Bluetooth)
        let deviceSelector = AutoDeviceSelector(wearables: wearables)
        
        print("Waiting for device to connect...")
        let connected = await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                for await device in deviceSelector.activeDeviceStream() {
                    if device != nil {
                        return true
                    }
                }
                return false
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10s timeout
                return false
            }
            let res = await group.next() ?? false
            group.cancelAll()
            return res
        }

        if !connected {
           result(FlutterError(code: "NO_DEVICE", message: "Timeout: Aucune lunette connectée", details: nil))
           return
        }

        // 4. Create session and connect
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
