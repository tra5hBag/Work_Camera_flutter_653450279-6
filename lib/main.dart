import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MainApp(cameras: cameras));
}

class MainApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MainApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomePage(cameras: cameras),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomePage({super.key, required this.cameras});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<CameraController> _cameraFuture;
  CameraController? _cameraController;
  final List<File> _capturedImages = [];
  bool _isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    _cameraFuture = _initializeCamera();
  }

  Future<CameraController> _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      throw Exception("No cameras available");
    }

    CameraDescription selectedCamera = _isFrontCamera
        ? widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => widget.cameras.first)
        : widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => widget.cameras.first);

    final cameraController = CameraController(selectedCamera, ResolutionPreset.medium);
    await cameraController.initialize();
    return cameraController;
  }

  void _toggleCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _cameraFuture = _initializeCamera();
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImages.insert(0, File(image.path));
      });
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Widget _buildPolaroidImage(File imageFile) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.file(imageFile, width: 150, height: 150, fit: BoxFit.cover),
          const SizedBox(height: 10),
          const Text("Polaroid", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Camera")),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: FutureBuilder<CameraController>(
              future: _cameraFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Camera Error: ${snapshot.error}"));
                } else {
                  _cameraController = snapshot.data;
                  return CameraPreview(_cameraController!);
                }
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.switch_camera),
                onPressed: _toggleCamera,
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _takePicture,
              ),
            ],
          ),
          Expanded(
            flex: 1,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _capturedImages.length,
              itemBuilder: (context, index) {
                return _buildPolaroidImage(_capturedImages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
