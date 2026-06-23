import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sw1/src/config/config.dart';
import 'package:flutter_sw1/src/models/emergency_alert.dart';
import 'package:flutter_sw1/src/models/emergency_contact.dart';

class EmergencyService {
  static const String baseUrl = ApiConfig.baseUrl;

  /// Tiempo máximo de espera para cada petición HTTP.
  static const Duration _timeout = Duration(seconds: 30);

  // ────────────────────────────────────────────────────────────────────────────
  // Helper: obtener token y validar
  // ────────────────────────────────────────────────────────────────────────────

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) throw Exception('Token de autenticación no encontrado');
    return token;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helper: decodificar respuesta con manejo robusto de errores
  // ────────────────────────────────────────────────────────────────────────────

  static String _safeErrorMessage(http.Response response) {
    final body = response.body;
    // Si la respuesta es HTML (ej: ngrok 502, servidor caído) no la mostramos cruda
    if (body.trimLeft().startsWith('<')) {
      return 'Error ${response.statusCode}: El servidor no está disponible temporalmente. '
          'Verifica tu conexión e inténtalo de nuevo.';
    }
    // Intentar extraer mensaje JSON
    try {
      final json = jsonDecode(body);
      return json['message']?.toString() ??
          json['error']?.toString() ??
          'Error ${response.statusCode}';
    } catch (_) {
      final preview = body.length > 120 ? '${body.substring(0, 120)}…' : body;
      return 'Error ${response.statusCode}: $preview';
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // CONTACTOS DE EMERGENCIA
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    final token = await _getToken();
    final url = '$baseUrl/emergency/contacts';

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => EmergencyContact.fromJson(j)).toList();
      }

      // En lugar de lanzar con HTML crudo, enviamos mensaje amigable
      throw Exception(_safeErrorMessage(response));
    } on SocketException {
      throw Exception('Sin conexión a internet. Verifica tu red.');
    } on http.ClientException catch (e) {
      throw Exception('Error de red: ${e.message}');
    }
  }

  static Future<EmergencyContact> createEmergencyContact({
    required String name,
    required String phone,
    String? email,
    String? relationship,
    int priority = 1,
  }) async {
    final token = await _getToken();

    final response = await http
        .post(
          Uri.parse('$baseUrl/emergency/contacts'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'phone': phone,
            if (email != null) 'email': email,
            if (relationship != null) 'relationship': relationship,
            'priority': priority,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 201) {
      return EmergencyContact.fromJson(jsonDecode(response.body));
    }
    throw Exception(_safeErrorMessage(response));
  }

  static Future<EmergencyContact> updateEmergencyContact({
    required int id,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    int? priority,
  }) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse('$baseUrl/emergency/contacts/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            if (name != null) 'name': name,
            if (phone != null) 'phone': phone,
            if (email != null) 'email': email,
            if (relationship != null) 'relationship': relationship,
            if (priority != null) 'priority': priority,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return EmergencyContact.fromJson(jsonDecode(response.body));
    }
    throw Exception(_safeErrorMessage(response));
  }

  static Future<void> deleteEmergencyContact(int id) async {
    final token = await _getToken();

    final response = await http
        .delete(
          Uri.parse('$baseUrl/emergency/contacts/$id'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_safeErrorMessage(response));
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ALERTAS DE EMERGENCIA
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<EmergencyAlert>> getEmergencyAlerts() async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'emergency_alerts_cache';

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/emergency/alerts'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        prefs.setString(cacheKey, response.body);
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((j) => EmergencyAlert.fromJson(j)).toList();
      }
      throw Exception(_safeErrorMessage(response));
    } catch (e) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((j) => EmergencyAlert.fromJson(j)).toList();
      }
      throw Exception('Sin conexión a internet y sin historial guardado localmente.');
    }
  }

  static Future<Map<String, dynamic>> getEmergencyCertificate(int id) async {
    final token = await _getToken();
    
    final response = await http
        .get(
          Uri.parse('$baseUrl/emergency/alerts/$id/certificado'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(_safeErrorMessage(response));
  }

  /// Activa el botón de pánico con o sin video.
  /// Usa JSON si no hay video, multipart si hay video.
  static Future<EmergencyAlert> triggerPanicButton({
    String? description,
    double? latitude,
    double? longitude,
    String? location,
    Map<String, dynamic>? metadata,
    File? videoFile,
  }) async {
    final token = await _getToken();

    if (videoFile != null) {
      // Multipart con video
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/emergency/alerts/panic-button'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['description'] = description ?? '';
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (location != null) request.fields['location'] = location;
      if (metadata != null) request.fields['metadata'] = jsonEncode(metadata);

      request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        filename: 'emergency_${DateTime.now().millisecondsSinceEpoch}.mp4',
        contentType: MediaType('video', 'mp4'),
      ));

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        return EmergencyAlert.fromJson(jsonDecode(response.body));
      }
      throw Exception(_safeErrorMessage(response));
    } else {
      // JSON sin video
      final response = await http
          .post(
            Uri.parse('$baseUrl/emergency/alerts/panic-button'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'description': description ?? '',
              if (latitude != null) 'latitude': latitude,
              if (longitude != null) 'longitude': longitude,
              if (location != null) 'location': location,
              if (metadata != null) 'metadata': metadata,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return EmergencyAlert.fromJson(jsonDecode(response.body));
      }
      throw Exception(_safeErrorMessage(response));
    }
  }

  /// Fase 2: Sube el video y lo asocia a una alerta existente
  static Future<EmergencyAlert> attachVideo(
    int alertId,
    File videoFile, {
    String? localSignature,
    String? publicKey,
  }) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/emergency/alerts/$alertId/video'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    if (localSignature != null) {
      request.fields['local_signature'] = localSignature;
    }
    if (publicKey != null) {
      request.fields['public_key'] = publicKey;
    }

    request.files.add(await http.MultipartFile.fromPath(
      'video',
      videoFile.path,
      filename: 'emergency_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      contentType: MediaType('video', 'mp4'),
    ));

    // Damos un timeout largo (60s) para videos pesados
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return EmergencyAlert.fromJson(jsonDecode(response.body));
    }
    throw Exception(_safeErrorMessage(response));
  }

  /// Sincroniza una alerta generada sin internet al recuperar conectividad.
  static Future<EmergencyAlert> syncOfflineAlert({
    String? description,
    double? latitude,
    double? longitude,
    String? location,
    String? offlineTimestamp,
    Map<String, dynamic>? metadata,
    File? videoFile,
  }) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/emergency/alerts/sync'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['description'] = description ?? '';
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();
    if (location != null) request.fields['location'] = location;
    if (offlineTimestamp != null) {
      request.fields['offlineTimestamp'] = offlineTimestamp;
    }
    if (metadata != null) {
      request.fields['metadata'] = jsonEncode(metadata);
    }

    if (videoFile != null && videoFile.existsSync()) {
      request.files.add(await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        filename: 'emergency_offline_${DateTime.now().millisecondsSinceEpoch}.mp4',
        contentType: MediaType('video', 'mp4'),
      ));
    }

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 201) {
      return EmergencyAlert.fromJson(jsonDecode(response.body));
    }
    throw Exception(_safeErrorMessage(response));
  }

  static Future<EmergencyAlert> resolveEmergencyAlert({
    required int id,
    String? resolutionNotes,
  }) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse('$baseUrl/emergency/alerts/$id/resolve'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return EmergencyAlert.fromJson(jsonDecode(response.body));
    }
    throw Exception(_safeErrorMessage(response));
  }

  static Future<EmergencyAlert> markAsFalseAlarm({
    required int id,
    String? resolutionNotes,
  }) async {
    final token = await _getToken();

    final response = await http
        .patch(
          Uri.parse('$baseUrl/emergency/alerts/$id/false-alarm'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return EmergencyAlert.fromJson(jsonDecode(response.body));
    }
    throw Exception(_safeErrorMessage(response));
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ESTADÍSTICAS Y ESTADO
  // ────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getEmergencyStats() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/emergency/stats'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_safeErrorMessage(response));
  }

  static Future<Map<String, dynamic>> getNotificationServicesStatus() async {
    final token = await _getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/emergency/notification-services/status'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_safeErrorMessage(response));
  }
}