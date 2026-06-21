import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sw1/src/services/emergency_service.dart';
import 'package:flutter_sw1/src/services/offline_emergency_queue.dart';

/// Estado de la sincronización
enum SyncStatus { idle, syncing, error, done }

/// Servicio que monitorea la conectividad y sincroniza las alertas pendientes
/// generadas sin internet cuando se recupera la conexión.
class EmergencySyncService {
  EmergencySyncService._();
  static final EmergencySyncService instance = EmergencySyncService._();

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  Timer? _timer;
  bool _isSyncing = false;

  /// Inicia el monitoreo de conectividad de forma periódica y segura.
  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 15), (timer) async {
      final pendingCount = await OfflineEmergencyQueue.getPendingCount();
      if (pendingCount > 0) {
        final hasInternet = await _checkInternet();
        if (hasInternet) {
          syncPending();
        }
      }
    });
  }

  /// Detiene el monitoreo.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _statusController.close();
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Sincroniza todas las alertas pendientes de la cola offline.
  Future<void> syncPending() async {
    if (_isSyncing) return;

    final pending = await OfflineEmergencyQueue.getAll();
    if (pending.isEmpty) return;

    _isSyncing = true;
    _emit(SyncStatus.syncing);
    debugPrint('📡 Sincronizando ${pending.length} alerta(s) offline...');

    for (final alert in pending) {
      if (alert.maxRetriesReached) {
        await OfflineEmergencyQueue.remove(alert.id);
        debugPrint('🗑️ Alerta ${alert.id} descartada tras ${PendingEmergencyAlert.maxRetries} intentos fallidos');
        continue;
      }

      final success = await _syncAlert(alert);
      if (success) {
        await OfflineEmergencyQueue.remove(alert.id);
        debugPrint('✅ Alerta ${alert.id} sincronizada y removida de la cola');
      } else {
        final updated = alert.incrementRetry();
        await OfflineEmergencyQueue.updateRetry(updated);
        debugPrint('⚠️ Alerta ${alert.id} fallida (intento ${updated.retryCount}/${PendingEmergencyAlert.maxRetries})');
      }
    }

    _isSyncing = false;

    final remaining = await OfflineEmergencyQueue.getPendingCount();
    _emit(remaining == 0 ? SyncStatus.done : SyncStatus.error);

    if (remaining == 0) {
      // Volver a idle después de 3 segundos para que la UI pueda mostrar el check
      Future.delayed(const Duration(seconds: 3), () => _emit(SyncStatus.idle));
    }
  }

  Future<bool> _syncAlert(PendingEmergencyAlert alert) async {
    try {
      File? videoFile;
      if (alert.videoPath.isNotEmpty && File(alert.videoPath).existsSync()) {
        videoFile = File(alert.videoPath);
      }

      await EmergencyService.syncOfflineAlert(
        description: alert.description ?? 'Alerta de emergencia (offline)',
        latitude: alert.latitude,
        longitude: alert.longitude,
        location: alert.location,
        offlineTimestamp: alert.offlineTimestamp,
        metadata: {
          ...?alert.metadata,
          'offlineSync': true,
          'syncedAt': DateTime.now().toIso8601String(),
        },
        videoFile: videoFile,
      );

      return true;
    } catch (e) {
      debugPrint('❌ Error sincronizando alerta ${alert.id}: $e');
      return false;
    }
  }

  void _emit(SyncStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
