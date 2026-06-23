import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_sw1/src/services/emergency_service.dart';
import 'package:flutter_sw1/src/services/offline_emergency_queue.dart';
import 'package:flutter_sw1/src/services/emergency_sync_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:flutter_sw1/src/services/local_evidence_service.dart';

const int _kMaxRecordingSeconds = 900; // 15 minutos (CU01)

class PanicButtonPage extends StatefulWidget {
  const PanicButtonPage({super.key});

  @override
  State<PanicButtonPage> createState() => _PanicButtonPageState();
}

class _PanicButtonPageState extends State<PanicButtonPage>
    with WidgetsBindingObserver {
  // ── Cámara ──────────────────────────────────────────────────────────────────
  CameraController? _cameraController;

  // ── Estado ──────────────────────────────────────────────────────────────────
  bool _isRecording = false;
  bool _isLoading = false;
  bool _hasInternet = true;
  File? _recordedVideo;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  int? _currentAlertId;
  String? _localSignature;
  String? _localPublicKey;

  // ── Ubicación ───────────────────────────────────────────────────────────────
  Position? _position;
  String? _locationLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _fetchLocation();
    _checkConnectivity();
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
    // Detener al ir a background solo si NO queremos background recording.
    // Cuando el CU01 implemente ForegroundService se quitará esta restricción.
    if (state == AppLifecycleState.paused && _isRecording) {
      _stopRecording();
    }
  }

  // ── Inicializar cámara ───────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('⚠️ Error inicializando cámara: $e');
    }
  }

  // ── Ubicación ────────────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = pos;
        _locationLabel =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      debugPrint('⚠️ Error obteniendo ubicación: $e');
    }
  }

  // ── Conectividad ─────────────────────────────────────────────────────────────

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      setState(() {
        _hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } catch (_) {
      setState(() {
        _hasInternet = false;
      });
    }
  }

  // ── Grabación ─────────────────────────────────────────────────────────────────

  // ── Grabación y Fase 1 ────────────────────────────────────────────────────────
  
  Future<void>? _initialAlertFuture;

  Future<void> _startPanicFlow() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showSnack('La cámara no está lista', isError: true);
      return;
    }

    // Fase 1: Enviar alerta inmediata sin video
    _initialAlertFuture = _sendInitialAlert();

    // Iniciar grabación
    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= _kMaxRecordingSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      _showSnack('Error al iniciar la grabación: $e', isError: true);
    }
  }

  Future<void> _sendInitialAlert() async {
    await _checkConnectivity();
    if (!_hasInternet) {
      _showSnack('Sin internet: La alerta se guardará localmente.', isError: true);
      return;
    }

    try {
      final alert = await EmergencyService.triggerPanicButton(
        description: 'Alerta de emergencia activada',
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        location: _locationLabel,
        metadata: {
          'deviceInfo': {'platform': Platform.operatingSystem},
        },
      );
      _currentAlertId = alert.id;
      if (mounted) _showSnack('Alerta enviada a tus contactos.');
    } catch (e) {
      _showSnack('Error enviando alerta inicial: $e', isError: true);
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;
    _recordingTimer?.cancel();

    try {
      final videoFile = await _cameraController!.stopVideoRecording();
      if (!mounted) return;
      
      // Guardar y firmar localmente (HU02)
      final localEvidence = await LocalEvidenceService.saveAndSignVideo(File(videoFile.path));
      final pubKey = await LocalEvidenceService.getPublicKey();

      setState(() {
        _isRecording = false;
        _recordedVideo = File(localEvidence.path);
        _localSignature = localEvidence.signature;
        _localPublicKey = pubKey;
      });
      
      // Fase 2: Subir evidencia
      _uploadVideoEvidencia();
    } catch (e) {
      setState(() => _isRecording = false);
      _showSnack('Error al detener la grabación: $e', isError: true);
    }
  }

  // ── Fase 2: Subida de evidencia ───────────────────────────────────────────────

  Future<void> _uploadVideoEvidencia() async {
    if (_recordedVideo == null) return;

    setState(() => _isLoading = true);

    // Esperar a que termine la Fase 1 si aún está en progreso
    if (_initialAlertFuture != null) {
      await _initialAlertFuture;
    }

    await _checkConnectivity();

    if (!_hasInternet || _currentAlertId == null) {
      setState(() => _isLoading = false);
      await _saveOffline();
      return;
    }

    try {
      await EmergencyService.attachVideo(
        _currentAlertId!,
        _recordedVideo!,
        localSignature: _localSignature,
        publicKey: _localPublicKey,
      );
      setState(() => _isLoading = false);
      if (mounted) _showSuccessDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Error subiendo evidencia: $e', isError: true);
    }
  }

  Future<void> _saveOffline() async {
    final id = const Uuid().v4();
    final alert = PendingEmergencyAlert(
      id: id,
      videoPath: _recordedVideo?.path ?? '',
      latitude: _position?.latitude,
      longitude: _position?.longitude,
      location: _locationLabel,
      description: 'Alerta de emergencia activada',
      offlineTimestamp: DateTime.now().toIso8601String(),
      metadata: {
        'recordingDuration': _recordingSeconds,
        'local_signature': _localSignature,
        'public_key': _localPublicKey,
      },
    );

    await OfflineEmergencyQueue.enqueue(alert);

    // Lanzar intent de sync para cuando haya internet
    EmergencySyncService.instance.start();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Text('Sin conexión'),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No hay internet en este momento.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tu alerta y evidencia han sido guardadas en el dispositivo. '
              'Se enviarán automáticamente a tus contactos cuando recuperes conexión.',
            ),
            SizedBox(height: 12),
            Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Expanded(child: Text('Grabación guardada localmente')),
            ]),
            SizedBox(height: 4),
            Row(children: [
              Icon(Icons.sync, color: Colors.blue, size: 18),
              SizedBox(width: 6),
              Expanded(child: Text('Se sincronizará automáticamente')),
            ]),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ── UI helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 5),
    ));
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 8),
          Text('Alerta Enviada'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu alerta de emergencia ha sido enviada.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_locationLabel != null)
              Text('📍 Ubicación: $_locationLabel'),
            Text('⏱️ Duración de grabación: ${_recordingSeconds}s'),
            const SizedBox(height: 12),
            const Text(
              '📧 Tus contactos recibirán notificación por WhatsApp y email.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Mantén la calma. Tus contactos han sido notificados.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady =
        _cameraController != null && _cameraController!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('🚨 Botón de Pánico'),
        actions: [
          if (_isRecording)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _BlinkingDot(),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_recordingSeconds),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  '/ ${_formatTime(_kMaxRecordingSeconds)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ]),
            ),
          if (!_hasInternet)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.wifi_off, color: Colors.orange),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          // ── Vista previa de cámara
          Expanded(
            flex: 3,
            child: cameraReady
                ? ClipRect(child: CameraPreview(_cameraController!))
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt, size: 64, color: Colors.white38),
                          SizedBox(height: 12),
                          Text('Inicializando cámara...',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
          ),

          // ── Información de ubicación
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Icon(
                Icons.location_on,
                color: _position != null ? Colors.green : Colors.orange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationLabel ?? 'Obteniendo ubicación GPS...',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!_hasInternet)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Chip(
                    label: Text('Sin internet',
                        style: TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.zero,
                  ),
                ),
            ]),
          ),

          // ── Controles
          Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: _buildControls(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildControls() {
    if (_isLoading) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Colors.red),
          SizedBox(height: 12),
          Text('Enviando alerta...', style: TextStyle(color: Colors.white70)),
        ]),
      );
    }

    if (!_isRecording && _recordedVideo == null) {
      // Estado inicial: botón pánico
      return _PanicButton(
        label: 'Activar Pánico',
        icon: Icons.warning,
        color: Colors.red,
        onTap: _startPanicFlow,
      );
    }

    if (_isRecording) {
      // Grabando: botón detener + barra de progreso
      return Column(children: [
        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _recordingSeconds / _kMaxRecordingSeconds,
            backgroundColor: Colors.grey.shade700,
            color: _recordingSeconds > _kMaxRecordingSeconds * 0.8
                ? Colors.orange
                : Colors.red,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Grabando evidencia ${_formatTime(_recordingSeconds)} / ${_formatTime(_kMaxRecordingSeconds)}',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _PanicButton(
          label: 'Detener y Enviar Evidencia',
          icon: Icons.stop,
          color: Colors.orange,
          onTap: _stopRecording,
        ),
      ]);
    }

    // Video listo (este estado ocurre si falla la subida y se queda ahí)
    return Column(children: [
      Row(children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 18),
        const SizedBox(width: 8),
        Text(
          'Video listo (${_recordingSeconds}s)',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ]),
      const SizedBox(height: 16),
      _PanicButton(
        label: _hasInternet
            ? 'Reintentar Subir Evidencia'
            : 'Guardar y Enviar Después',
        icon: _hasInternet ? Icons.cloud_upload : Icons.save,
        color: Colors.red,
        onTap: _uploadVideoEvidencia,
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: () => setState(() {
          _recordedVideo = null;
          _recordingSeconds = 0;
          _currentAlertId = null;
        }),
        icon: const Icon(Icons.refresh, color: Colors.white54),
        label: const Text('Comenzar nueva alerta',
            style: TextStyle(color: Colors.white54)),
      ),
    ]);
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _PanicButton extends StatelessWidget {
  const _PanicButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 17)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: const CircleAvatar(
          radius: 5, backgroundColor: Colors.red),
    );
  }
}