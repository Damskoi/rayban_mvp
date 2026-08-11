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
  // Canal de communication avec le code natif (iOS / SDK Meta)
  static const platform = MethodChannel('com.rayban.meta/camera');
  
  bool _isStreaming = false;

  Future<void> _startStream() async {
    try {
      // Appel de la méthode native "startStream" qui devra être implémentée dans iOS
      final bool result = await platform.invokeMethod('startStream');
      setState(() {
        _isStreaming = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result ? 'Flux démarré' : 'Échec du flux')),
      );
    } on PlatformException catch (e) {
      // En l'absence d'implémentation native pour l'instant (sur Windows), cela échouera
      setState(() {
        _isStreaming = true; // On simule le succès pour l'interface UI MVP
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Simulation : Flux démarré (Erreur native: ${e.message})")),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      // Appel de la méthode native "takePhoto"
      await platform.invokeMethod('takePhoto');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo prise !')),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Simulation : Photo prise (Erreur native: ${e.message})")),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: _isStreaming 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam, color: Colors.greenAccent, size: 50),
                        SizedBox(height: 10),
                        Text("🎥 Flux vidéo actif", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off, color: Colors.white54, size: 50),
                        SizedBox(height: 10),
                        Text("Flux vidéo inactif", style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
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
