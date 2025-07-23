import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sw1/src/models/emergency_alert.dart';
import 'package:flutter_sw1/src/services/emergency_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';

class PanicButtonPage extends StatefulWidget {
  const PanicButtonPage({super.key});

  @override
  State<PanicButtonPage> createState() => _PanicButtonPageState();
}

class _PanicButtonPageState extends State<PanicButtonPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isRecording = false;
  bool _isLoading = false;
  Position? _currentPosition;
  String? _currentLocation;
  File? _recordedVideo;
  int _recordingDuration = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopRecording();
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final granted = await Geolocator.requestPermission();
        if (granted != LocationPermission.whileInUse &&
            granted != LocationPermission.always) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() => _currentPosition = position);

      // Por ahora solo usamos las coordenadas como ubicación
      setState(() {
        _currentLocation = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final videoPath = '${directory.path}/emergency_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      await _cameraController!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _recordedVideo = File(videoPath);
      });

      // Timer para duración de grabación
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });

        // Detener automáticamente después de 5 minutos
        if (_recordingDuration >= 300) {
          _stopRecording();
        }
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;

    try {
      final videoFile = await _cameraController!.stopVideoRecording();
      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
        _recordedVideo = File(videoFile.path);
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _sendEmergencyAlert() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener la ubicación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🚨 Enviando alerta de emergencia...');
      print('📍 Ubicación: ${_currentLocation}');
      print('📹 Video: ${_recordedVideo?.path ?? 'No disponible'}');
      
      final alert = await EmergencyService.triggerPanicButton(
        description: 'Alerta de emergencia activada',
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        location: _currentLocation,
        metadata: {
          'recordingDuration': _recordingDuration,
          'deviceInfo': {
            'platform': Platform.operatingSystem,
            'version': Platform.operatingSystemVersion,
          },
        },
        videoFile: _recordedVideo,
      );

      setState(() => _isLoading = false);

      // Mostrar confirmación
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🚨 Alerta Enviada'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tu alerta de emergencia ha sido enviada a todos tus contactos.'),
                const SizedBox(height: 16),
                Text('Ubicación: ${_currentLocation ?? 'No disponible'}'),
                Text('Duración del video: ${_recordingDuration}s'),
                const SizedBox(height: 16),
                const Text(
                  'Mantén la calma. Tus contactos han sido notificados.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error al enviar alerta: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar alerta: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Botón de Pánico'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Inicializando cámara...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Botón de Pánico'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${_recordingDuration}s'),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Vista previa de la cámara
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),

          // Información de ubicación
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_currentLocation != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentLocation!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (_currentPosition != null)
                  Text(
                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Controles
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (!_isRecording && _recordedVideo == null) ...[
                  // Botón de grabación
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _startRecording,
                      icon: const Icon(Icons.videocam, size: 24),
                      label: const Text(
                        'Iniciar Grabación',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else if (_isRecording) ...[
                  // Botón para detener grabación
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: const Icon(Icons.stop, size: 24),
                      label: const Text(
                        'Detener Grabación',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else if (_recordedVideo != null) ...[
                  // Botón para enviar alerta
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendEmergencyAlert,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, size: 24),
                      label: Text(
                        _isLoading ? 'Enviando...' : 'Enviar Alerta de Emergencia',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _recordedVideo = null;
                        _recordingDuration = 0;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Grabar Nuevamente'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 