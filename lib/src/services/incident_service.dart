import 'dart:typed_data';
import 'package:flutter_sw1/src/config/config.dart';
import 'package:flutter_sw1/src/models/incident.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

Future<Incidente?> crearIncidente(String tipo, String desc, LatLng latLon) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final url = ApiConfig.baseUrl;
  final uri = Uri.parse('$url/incidentes');
  final token = prefs.getString('auth_token') ?? '';
  final latLngString = latLngToString(latLon);

  if (token.isEmpty) {
    print('❌ Token de autenticación no encontrado');
    return null;
  }

  try {
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tipo_incidente': tipo,
        'descripcion': desc.isEmpty ? 'Sin descripción' : desc,
        'latitud_longitud': latLngString,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('✅ Incidente creado exitosamente');
      return Incidente.fromJson(data);
    } else {
      print('⚠️ Error al crear incidente: ${response.statusCode}');
      print('Detalles: ${response.body}');
    }
  } catch (e) {
    print('❌ Error de red o inesperado: $e');
  }
  return null;
}

Future<Incidentes?> getIncidentes() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final url = ApiConfig.baseUrl;
  final token = prefs.getString('auth_token') ?? '';

  if (token.isEmpty) {
    print('❌ Token de autenticación no encontrado');
    return null;
  }

  try {
    final response = await http.get(
      Uri.parse('$url/incidentes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Incidentes.fromJson(data);
    } else {
      print('⚠️ Error al obtener incidentes: ${response.statusCode}');
      print('Detalles: ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ Error de red o inesperado: $e');
    return null;
  }
}

Future<List<Incidente>> getMisIncidentes() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final url = ApiConfig.baseUrl;
  final token = prefs.getString('auth_token') ?? '';

  if (token.isEmpty) return [];

  try {
    final response = await http.get(
      Uri.parse('$url/incidentes/mis-incidentes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((x) => Incidente.fromJson(x)).toList();
    }
  } catch (e) {
    print('❌ Error al obtener mis incidentes: $e');
  }
  return [];
}

/// Descarga el certificado PDF de un incidente.
/// Devuelve los bytes del PDF, o null si está pendiente (con [pendienteMsg]).
Future<({Uint8List? bytes, String? pendienteMsg})> descargarCertificado(
    int incidenteId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final url = ApiConfig.baseUrl;
  final token = prefs.getString('auth_token') ?? '';

  if (token.isEmpty) {
    return (bytes: null, pendienteMsg: 'Sin sesión activa.');
  }

  try {
    final response = await http.get(
      Uri.parse('$url/incidentes/$incidenteId/certificado'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return (bytes: response.bodyBytes, pendienteMsg: null);
    }

    if (response.statusCode == 202) {
      final data = jsonDecode(response.body);
      return (
        bytes: null,
        pendienteMsg: data['message'] as String? ??
            'El certificado estará disponible cuando la transacción sea confirmada.'
      );
    }

    final data = jsonDecode(response.body);
    throw Exception(data['message'] ?? 'Error al obtener el certificado');
  } catch (e) {
    rethrow;
  }
}

String latLngToString(LatLng latLng) {
  return '${latLng.latitude.toStringAsFixed(4)},${latLng.longitude.toStringAsFixed(4)}';
}

LatLng stringToLatLng(String latLngString) {
  final parts = latLngString.split(',');
  final lat = double.parse(parts[0]);
  final lng = double.parse(parts[1]);
  return LatLng(lat, lng);
}
