import 'dart:typed_data';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RayBanMVPPage(title: 'Ray-Ban Meta MVP'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RayBanMVPPage extends StatefulWidget {
  const RayBanMVPPage({super.key, required this.title});
  final String title;

  @override
  State<RayBanMVPPage> createState() => _RayBanMVPPageState();
}

class _RayBanMVPPageState extends State<RayBanMVPPage> {
  static const platform = MethodChannel('com.rayban.meta/camera');
  static const videoChannel = EventChannel('com.rayban.meta/video');
  
  bool _isStreaming = false;
  Uint8List? _latestFrame;

  @override
  void initState() {
    super.initState();
    // Écoute du flux vidéo venant d'iOS
    videoChannel.receiveBroadcastStream().listen((event) {
      if (event is Uint8List) {
        setState(() {
          _latestFrame = event;
        });
      }
    }, onError: (error) {
      print("Erreur du flux vidéo: $error");
    });
  }

  Future<void> _startStream() async {
    try {
      final bool result = await platform.invokeMethod('startStream');
      setState(() {
        _isStreaming = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ? 'Flux démarré' : 'Échec du flux')),
      );
    } on PlatformException catch (e) {
      setState(() {
        _isStreaming = true; // Simulé pour l'UI sur simulateur
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur native: ${e.message}")),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      await platform.invokeMethod('takePhoto');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo prise avec succès !')),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur photo native: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Espace de rendu pour la caméra des Ray-Ban
            Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  )
                ]
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
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
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off, color: Colors.white54, size: 50),
                          SizedBox(height: 10),
                          Text("Flux vidéo inactif", style: TextStyle(color: Colors.white54, fontSize: 16)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: _startStream,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Flux'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Prendre une photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer
              ),
            ),
          ],
        ),
      ),
    );
  }
}
