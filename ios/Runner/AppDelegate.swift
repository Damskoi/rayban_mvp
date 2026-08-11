import Flutter
import UIKit
import MWDATCore
import MWDATCamera

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var session: DeviceSession?
  private var stream: MWDATCamera.Stream?
  private var videoListenerToken: AnyListenerToken?
  private var frameSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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
    
    let cameraChannel = FlutterMethodChannel(name: "com.rayban.meta/camera",
                                              binaryMessenger: messenger)
    cameraChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "startStream" {
        self?.startStream(result: result)
      } else if call.method == "takePhoto" {
        self?.takePhoto(result: result)
      } else if call.method == "checkConnection" {
        self?.checkConnection(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    let videoChannel = FlutterEventChannel(name: "com.rayban.meta/video",
                                           binaryMessenger: messenger)
    videoChannel.setStreamHandler(VideoEventHandler(appDelegate: self))

    let connectionChannel = FlutterEventChannel(name: "com.rayban.meta/connection",
                                                binaryMessenger: messenger)
    connectionChannel.setStreamHandler(ConnectionEventHandler())
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    Task {
      do {
        _ = try await Wearables.shared.handleUrl(url)
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
        
        if wearables.registrationState != .registered {
           try await wearables.startRegistration()
        }

        let currentStatus = try await wearables.checkPermissionStatus(.camera)
        if currentStatus != .granted {
            let status = try await wearables.requestPermission(.camera)
            if status != .granted {
               result(FlutterError(code: "PERMISSION_DENIED", message: "Permission refusée", details: nil))
               return
            }
        }

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
                try? await Task.sleep(nanoseconds: 10_000_000_000)
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

        if self.session == nil || self.session?.state == .stopping || self.session?.state == .stopped {
            self.session = try wearables.createSession(deviceSelector: deviceSelector)
        }
        
        try self.session?.start()

        var finalState: MWDATCore.DeviceSessionState? = self.session?.state
        if finalState != .started {
            let waitResult = await withTaskGroup(of: String.self) { group in
                group.addTask {
                    guard let stream = self.session?.stateStream() else { return "NoStateStream" }
                    for await state in stream {
                        if state == .started { return "OK" }
                        if state == .idle { return "IDLE" }
                        if state == .stopping { return "STOPPING" }
                    }
                    return "EndStream"
                }
                
                group.addTask {
                    guard let errStream = self.session?.errorStream() else { return "NoErrorStream" }
                    for await err in errStream {
                        return "ERROR: \(err)"
                    }
                    return "EndErrStream"
                }
                
                group.addTask {
                    try? await Task.sleep(nanoseconds: 10_000_000_000) // 10s timeout
                    return "TIMEOUT"
                }
                
                let firstResult = await group.next() ?? "TIMEOUT"
                group.cancelAll()
                return firstResult
            }
            
            if waitResult != "OK" {
                result(FlutterError(code: "SESSION_FAILED", message: "La session n'a pas pu démarrer. Raison: \(waitResult), État actuel: \(String(describing: self.session?.state))", details: nil))
                return
            }
        }

        let config = MWDATCamera.StreamConfiguration(
          videoCodec: VideoCodec.raw,
          resolution: StreamingResolution.low,
          frameRate: 24)

        if let camera = try self.session?.addCamera(config: config) {
          self.stream = camera.stream
          
          self.videoListenerToken = self.stream?.videoFramePublisher.listen { [weak self] frame in
             if let image = frame.makeUIImage(), let data = image.jpegData(compressionQuality: 0.5) {
                DispatchQueue.main.async {
                   self?.frameSink?(data)
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
       stream.capturePhoto(format: .jpeg)
       result(true)
    } else {
       result(FlutterError(code: "NO_STREAM", message: "Flux non démarré", details: nil))
    }
  }

  private func checkConnection(result: @escaping FlutterResult) {
    Task {
      let wearables = Wearables.shared
      if wearables.registrationState != .registered {
          result(false)
          return
      }
      let deviceSelector = AutoDeviceSelector(wearables: wearables)
      let connected = await withTaskGroup(of: Bool.self) { group in
          group.addTask {
              for await device in deviceSelector.activeDeviceStream() {
                  if device != nil { return true }
              }
              return false
          }
          group.addTask {
              try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s timeout
              return false
          }
          let res = await group.next() ?? false
          group.cancelAll()
          return res
      }
      result(connected)
    }
  }

  func setFrameSink(_ sink: FlutterEventSink?) {
     self.frameSink = sink
  }
}

class ConnectionEventHandler: NSObject, FlutterStreamHandler {
    private var task: Task<Void, Never>?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        task = Task {
            let wearables = Wearables.shared
            if wearables.registrationState != .registered {
                DispatchQueue.main.async { events(false) }
                // Still monitor in case they register while listening
            }
            let deviceSelector = AutoDeviceSelector(wearables: wearables)
            
            for await device in deviceSelector.activeDeviceStream() {
                if Task.isCancelled { break }
                let isConnected = (device != nil)
                DispatchQueue.main.async {
                    events(isConnected)
                }
            }
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        task?.cancel()
        task = nil
        return nil
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
