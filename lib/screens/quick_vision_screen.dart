import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickVisionScreen extends StatefulWidget {
  const QuickVisionScreen({super.key});

  @override
  State<QuickVisionScreen> createState() => _QuickVisionScreenState();
}

class _QuickVisionScreenState extends State<QuickVisionScreen> {
  static const platform = MethodChannel('com.rayban.meta/camera');
  static const videoChannel = EventChannel('com.rayban.meta/video');
  
  bool _isStreaming = false;
  bool _isLoading = false;
  Uint8List? _latestFrame;

  @override
  void initState() {
    super.initState();
    videoChannel.receiveBroadcastStream().listen((event) {
      if (event is Uint8List) {
        if (mounted) {
          setState(() {
            _latestFrame = event;
            _isLoading = false;
          });
        }
      }
    }, onError: (error) {
      print("Erreur du flux vidéo: $error");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isStreaming = false;
        });
      }
    });
  }

  Future<void> _startStream() async {
    if (_isStreaming) return; // Already streaming
    
    setState(() {
      _isLoading = true;
    });

    try {
      final bool result = await platform.invokeMethod('startStream');
      if (mounted) {
        setState(() {
          _isStreaming = result;
          if (!result) _isLoading = false;
        });
        if (!result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Échec du flux')),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur native: ${e.message}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black background for this screen
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Close", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const Text(
                    "Quick Vision",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 18),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // Main Video / State Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: _isStreaming 
                      ? (_latestFrame != null
                          ? Image.memory(
                              _latestFrame!,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            )
                          : const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            ))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.portable_wifi_off_rounded,
                              color: Color(0xFFFF8B26),
                              size: 60,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Glasses Not Connected",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Glasses not connected. Please pair in Meta View first",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Action Button
              GestureDetector(
                onTap: _startStream,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _isLoading ? const Color(0xFF2C2C2E) : const Color(0xFF38383A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      else ...[
                        const Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isStreaming ? "Flux Démarré" : "Démarrer Quick Vision",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB523D5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Supports Siri and Shortcuts",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
