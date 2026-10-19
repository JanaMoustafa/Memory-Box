import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Web-specific camera widget that uses HTML5 getUserMedia API
/// to access the camera directly and capture live photos
class WebCameraWidget extends StatefulWidget {
  final Function(String imagePath, XFile? file) onImageCaptured;

  const WebCameraWidget({
    Key? key,
    required this.onImageCaptured,
  }) : super(key: key);

  @override
  State<WebCameraWidget> createState() => _WebCameraWidgetState();
}

class _WebCameraWidgetState extends State<WebCameraWidget> {
  html.MediaStream? _stream;
  html.VideoElement? _videoElement;
  String? _viewId;
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeCamera();
    } else {
      setState(() {
        _error = 'Web camera widget only works on web platform';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera access using modern API
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('MediaDevices API not supported');
      }

      _stream = await mediaDevices.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      });

      // Create video element
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..srcObject = _stream;

      // Generate unique view ID
      _viewId = 'web_camera_${DateTime.now().millisecondsSinceEpoch}';

      // Register the video element with Flutter
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) => _videoElement!,
      );

      // Wait for video to be ready
      _videoElement!.onLoadedMetadata.listen((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isLoading = false;
          });
        }
      });

      _videoElement!.onError.listen((error) {
        if (mounted) {
          setState(() {
            _error = 'Failed to access camera. Please check permissions.';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize camera: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_videoElement == null || !_isInitialized) {
      return;
    }

    try {
      // Create canvas to capture the video frame
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );
      final ctx = canvas.context2D;

      // Draw video frame to canvas
      ctx.drawImage(_videoElement!, 0, 0);

      // Convert canvas to blob
      final blob = await canvas.toBlob('image/jpeg', 0.85);
      final reader = html.FileReader();

      // Read blob as data URL
      reader.readAsDataUrl(blob);
      await reader.onLoad.first;

      final dataUrl = reader.result as String;

      // Create XFile from data URL
      final bytes = _dataUriToBytes(dataUrl);
      final file = XFile.fromData(
        bytes,
        mimeType: 'image/jpeg',
        name: 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (mounted) {
        widget.onImageCaptured(dataUrl, file);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Uint8List _dataUriToBytes(String dataUri) {
    final base64String = dataUri.split(',')[1];
    return Uint8List.fromList(base64.decode(base64String));
  }

  @override
  void dispose() {
    _stream?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            else if (_error != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
            else if (_isInitialized && _viewId != null)
              Center(
                child: HtmlElementView(
                  viewType: _viewId!,
                ),
              ),

            // Top bar with close button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar with capture button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _isInitialized ? _capturePhoto : null,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 4,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera,
                          size: 36,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

