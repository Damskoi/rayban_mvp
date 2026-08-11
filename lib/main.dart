import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ray-Ban Meta MVP',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A90E2),
          secondary: Color(0xFFE24A7F),
          surface: Color(0xFF1A1A24),
        ),
        useMaterial3: true,
      ),
      home: const RayBanMVPPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RayBanMVPPage extends StatefulWidget {
  const RayBanMVPPage({super.key});

  @override
  State<RayBanMVPPage> createState() => _RayBanMVPPageState();
}

class _RayBanMVPPageState extends State<RayBanMVPPage> with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.rayban.meta/camera');
  static const videoChannel = EventChannel('com.rayban.meta/video');
  
  bool _isStreaming = false;
  bool _isConnecting = false;
  Uint8List? _latestFrame;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    videoChannel.receiveBroadcastStream().listen((event) {
      if (event is Uint8List) {
        setState(() {
          _latestFrame = event;
          _isConnecting = false;
          _isStreaming = true;
        });
      }
    }, onError: (error) {
      _showError("Erreur du flux vidéo: $error");
      setState(() { _isConnecting = false; _isStreaming = false; });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _startStream() async {
    setState(() { _isConnecting = true; });
    try {
      final bool result = await platform.invokeMethod('startStream');
      if (!result) {
        setState(() { _isConnecting = false; });
        _showError("Échec du lancement du flux.");
      }
    } on PlatformException catch (e) {
      setState(() { _isConnecting = false; });
      _showError("Erreur native: ${e.message}");
    }
  }

  Future<void> _takePhoto() async {
    try {
      await platform.invokeMethod('takePhoto');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('📸 Photo prise avec succès !', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on PlatformException catch (e) {
      _showError("Erreur photo native: ${e.message}");
    }
  }

  Widget _buildGlassContainer({required Widget child, double? width, double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF2A2A3D), Color(0xFF0D0D12)],
                radius: 1.2,
                center: Alignment.topCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Ray-Ban Meta",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isStreaming 
                                ? Colors.green.withOpacity(0.2 + (_pulseController.value * 0.3))
                                : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isStreaming ? Colors.green : Colors.transparent,
                              )
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: _isStreaming ? Colors.greenAccent : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isStreaming ? "EN DIRECT" : "DÉCONNECTÉ",
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w600,
                                    color: _isStreaming ? Colors.greenAccent : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Video Viewport
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildGlassContainer(
                    width: double.infinity,
                    height: 400,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_latestFrame != null)
                          Positioned.fill(
                            child: Image.memory(
                              _latestFrame!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Flux vidéo inactif",
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                              ),
                            ],
                          ),
                        
                        if (_isConnecting)
                          Container(
                            color: Colors.black.withOpacity(0.6),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 16),
                                  Text("Connexion aux lunettes...", style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Stream Button
                      GestureDetector(
                        onTap: (_isStreaming || _isConnecting) ? null : _startStream,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: (_isStreaming || _isConnecting)
                                ? [Colors.grey.shade800, Colors.grey.shade900]
                                : [Theme.of(context).colorScheme.primary, Colors.blue.shade800],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity((_isStreaming || _isConnecting) ? 0 : 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ]
                          ),
                          child: const Icon(Icons.power_settings_new, size: 36, color: Colors.white),
                        ),
                      ),
                      
                      // Capture Button
                      GestureDetector(
                        onTap: _isStreaming ? _takePhoto : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isStreaming ? Colors.white.withOpacity(0.1) : Colors.transparent,
                            border: Border.all(
                              color: _isStreaming ? Colors.white : Colors.white.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined, 
                            size: 28, 
                            color: _isStreaming ? Colors.white : Colors.white.withOpacity(0.2)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
