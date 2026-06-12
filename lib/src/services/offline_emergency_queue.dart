import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Representa una alerta de emergencia generada sin internet.
class PendingEmergencyAlert {
  final String id;
  final String videoPath; // Ruta local del video grabado
  final double? latitude;
  final double? longitude;
  final String? location;
  final String? description;
  final String offlineTimestamp; // ISO 8601
  final Map<String, dynamic>? metadata;

  PendingEmergencyAlert({
    required this.id,
    required this.videoPath,
    this.latitude,
    this.longitude,
    this.location,
    this.description,
    required this.offlineTimestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoPath': videoPath,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'description': description,
        'offlineTimestamp': offlineTimestamp,
        'metadata': metadata,
      };

  factory PendingEmergencyAlert.fromJson(Map<String, dynamic> json) =>
      PendingEmergencyAlert(
        id: json['id'] as String,
        videoPath: json['videoPath'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        location: json['location'] as String?,
        description: json['description'] as String?,
        offlineTimestamp: json['offlineTimestamp'] as String,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Cola de alertas de emergencia pendientes de sincronización.
///
/// Usa [SharedPreferences] para persistencia local (no requiere dependencias
/// adicionales). Las alertas se almacenan como JSON.
class OfflineEmergencyQueue {
  static const String _key = 'offline_emergency_queue';

  /// Agrega una alerta a la cola offline.
  static Future<void> enqueue(PendingEmergencyAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _loadList(prefs);
    existing.add(alert.toJson());
    await prefs.setString(_key, jsonEncode(existing));
  }

  /// Devuelve todas las alertas pendientes.
  static Future<List<PendingEmergencyAlert>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadList(prefs);
    return list
        .map((e) => PendingEmergencyAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Elimina una alerta de la cola por su [id].
  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = _loadList(prefs);
    list.removeWhere((e) => (e as Map)['id'] == id);
    await prefs.setString(_key, jsonEncode(list));
  }

  /// Devuelve cuántas alertas hay pendientes.
  static Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadList(prefs).length;
  }

  /// Limpia toda la cola (uso interno / debug).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static List<dynamic> _loadList(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }
}
