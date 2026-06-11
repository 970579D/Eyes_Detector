import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class EyeContactCameraPage extends StatefulWidget {
  const EyeContactCameraPage({super.key});
  @override
  State<EyeContactCameraPage> createState() => _EyeContactCameraPageState();
}

class _EyeContactCameraPageState extends State<EyeContactCameraPage> {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  bool _inCooldown = false;
  int _capturedCount = 0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;

  // Detection thresholds
  static const double _maxYaw     = 12.0;
  static const double _maxPitch   = 10.0;
  static const double _minEyeOpen = 0.75;
  static const Duration _cooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await [Permission.camera, Permission.photos].request();

    final cameras = await availableCameras();

    // Use back camera
    final back = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    _controller = CameraController(
      back,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _controller!.initialize();

    // Load zoom limits
    _minZoom = await _controller!.getMinZoomLevel();
    _maxZoom = await _controller!.getMaxZoomLevel();
    _currentZoom = _minZoom;

    // Ensure flash is always off
    await _controller!.setFlashMode(FlashMode.off);

    // Log actual resolution
    final size = _controller!.value.previewSize;
    debugPrint('Camera resolution: ${size?.width} x ${size?.height}');

    if (!mounted) return;
    setState(() {});
    _controller!.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_isProcessing || _inCooldown) return;
    _isProcessing = true;

    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) return;

      final face = faces.first;
      if (_isEyeContact(face)) {
        await _capturePhoto();
      }
    } finally {
      _isProcessing = false;
    }
  }

  bool _isEyeContact(Face face) {
    final yaw   = face.headEulerAngleY ?? 999;
    final pitch = face.headEulerAngleX ?? 999;
    if (yaw.abs() > _maxYaw || pitch.abs() > _maxPitch) return false;

    final leftOpen  = face.leftEyeOpenProbability  ?? 0;
    final rightOpen = face.rightEyeOpenProbability ?? 0;
    if (leftOpen < _minEyeOpen || rightOpen < _minEyeOpen) return false;

    return true;
  }

  Future<void> _capturePhoto() async {
    if (_inCooldown) return;
    _inCooldown = true;

    try {
      await _controller!.stopImageStream();
      await _controller!.setFlashMode(FlashMode.off);
      final xFile = await _controller!.takePicture();
      final bytes = await File(xFile.path).readAsBytes();
      await Gal.putImageBytes(bytes);
      if (mounted) setState(() => _capturedCount++);
    } finally {
      await _controller!.startImageStream(_onFrame);
      Future.delayed(_cooldown, () => _inCooldown = false);
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _controller!.description;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final previewSize = _controller!.value.previewSize!;
    final camRatio = previewSize.height / previewSize.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Camera preview ──
          Center(
            child: AspectRatio(
              aspectRatio: camRatio,
              child: CameraPreview(_controller!),
            ),
          ),

          // ── Top bar: back button + capture count ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () async {
                        await _controller!.stopImageStream();
                        if (mounted) Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Capture count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_capturedCount captured',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom bar: zoom slider ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom level label
                    Text(
                      '${_currentZoom.toStringAsFixed(1)}×',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Zoom slider
                    Row(
                      children: [
                        const Icon(
                          Icons.zoom_out,
                          color: Colors.white70,
                          size: 20,
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentZoom,
                            min: _minZoom,
                            max: _maxZoom,
                            divisions: ((_maxZoom - _minZoom) * 10)
                                .toInt()
                                .clamp(1, 100),
                            activeColor: Colors.white,
                            inactiveColor: Colors.white30,
                            onChanged: (value) async {
                              setState(() => _currentZoom = value);
                              await _controller!.setZoomLevel(value);
                            },
                          ),
                        ),
                        const Icon(
                          Icons.zoom_in,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}