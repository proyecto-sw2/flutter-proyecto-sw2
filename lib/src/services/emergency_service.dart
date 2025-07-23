import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sw1/src/config/config.dart';
import 'package:flutter_sw1/src/models/emergency_alert.dart';
import 'package:flutter_sw1/src/models/emergency_contact.dart';

class EmergencyService {
  static const String baseUrl = ApiConfig.baseUrl;

  // ===== CONTACTOS DE EMERGENCIA =====

  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final url = '$baseUrl/api/emergency/contacts';
    print('🔗 Intentando obtener contactos de: $url');
    print('🔑 Token: ${token.substring(0, 20)}...');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        print('✅ Contactos obtenidos: ${jsonList.length}');
        return jsonList.map((json) => EmergencyContact.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener contactos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error en getEmergencyContacts: $e');
      
      // 🚨 SOLUCIÓN TEMPORAL: Si el endpoint no existe, devolver lista vacía
      if (e.toString().contains('404') || e.toString().contains('Connection refused')) {
        print('⚠️ Endpoint no disponible, devolviendo lista vacía');
        return [];
      }
      
      throw Exception('Error de conexión al obtener contactos: $e');
    }
  }

  static Future<EmergencyContact> createEmergencyContact({
    required String name,
    required String phone,
    String? email,
    String? relationship,
    int priority = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/emergency/contacts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'relationship': relationship,
        'priority': priority,
      }),
    );

    if (response.statusCode == 201) {
      final jsonData = json.decode(response.body);
      return EmergencyContact.fromJson(jsonData);
    } else {
      throw Exception('Error al crear contacto: ${response.body}');
    }
  }

  static Future<EmergencyContact> updateEmergencyContact({
    required int id,
    String? name,
    String? phone,
    String? email,
    String? relationship,
    int? priority,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/api/emergency/contacts/$id'),
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
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return EmergencyContact.fromJson(jsonData);
    } else {
      throw Exception('Error al actualizar contacto: ${response.body}');
    }
  }

  static Future<void> deleteEmergencyContact(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/api/emergency/contacts/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar contacto: ${response.body}');
    }
  }

  // ===== ALERTAS DE EMERGENCIA =====

  static Future<List<EmergencyAlert>> getEmergencyAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/emergency/alerts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => EmergencyAlert.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener alertas: ${response.body}');
    }
  }

  static Future<EmergencyAlert> createEmergencyAlert({
    String? description,
    double? latitude,
    double? longitude,
    String? location,
    AlertType type = AlertType.panicButton,
    Map<String, dynamic>? metadata,
    File? videoFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    // Crear request multipart
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/emergency/alerts'),
    );

    // Agregar headers
    request.headers['Authorization'] = 'Bearer $token';

    // Agregar campos de texto
    request.fields['description'] = description ?? '';
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();
    if (location != null) request.fields['location'] = location;
    request.fields['type'] = type.toString().split('.').last;
    if (metadata != null) {
      request.fields['metadata'] = jsonEncode(metadata);
    }

    // Agregar archivo de video si existe
    if (videoFile != null) {
      final videoStream = http.ByteStream(videoFile.openRead());
      final videoLength = await videoFile.length();
      
      final videoMultipart = http.MultipartFile(
        'video',
        videoStream,
        videoLength,
        filename: 'emergency_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      request.files.add(videoMultipart);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final jsonData = json.decode(response.body);
      return EmergencyAlert.fromJson(jsonData);
    } else {
      throw Exception('Error al crear alerta: ${response.body}');
    }
  }

  static Future<EmergencyAlert> triggerPanicButton({
    String? description,
    double? latitude,
    double? longitude,
    String? location,
    Map<String, dynamic>? metadata,
    File? videoFile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    // Crear el body JSON con números correctos
    final body = {
      'description': description ?? '',
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (location != null) 'location': location,
      if (metadata != null) 'metadata': metadata,
    };

    // Enviar como JSON
    final response = await http.post(
      Uri.parse('$baseUrl/api/emergency/alerts/panic-button'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final jsonData = json.decode(response.body);
      return EmergencyAlert.fromJson(jsonData);
    } else {
      throw Exception('Error al activar botón de pánico: ${response.body}');
    }
  }

  static Future<EmergencyAlert> resolveEmergencyAlert({
    required int id,
    String? resolutionNotes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/api/emergency/alerts/$id/resolve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return EmergencyAlert.fromJson(jsonData);
    } else {
      throw Exception('Error al resolver alerta: ${response.body}');
    }
  }

  static Future<EmergencyAlert> markAsFalseAlarm({
    required int id,
    String? resolutionNotes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/api/emergency/alerts/$id/false-alarm'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return EmergencyAlert.fromJson(jsonData);
    } else {
      throw Exception('Error al marcar como falsa alarma: ${response.body}');
    }
  }

  // ===== ESTADÍSTICAS =====

  static Future<Map<String, dynamic>> getEmergencyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/emergency/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener estadísticas: ${response.body}');
    }
  }

  // ===== SERVICIOS DE NOTIFICACIÓN =====

  static Future<Map<String, dynamic>> getNotificationServicesStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw Exception('Token de autenticación no encontrado');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/emergency/notification-services/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener estado de servicios: ${response.body}');
    }
  }
} 