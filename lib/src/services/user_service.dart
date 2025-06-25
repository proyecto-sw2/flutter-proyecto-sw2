import 'dart:convert';

import 'package:flutter_sw1/src/config/config.dart';
import 'package:flutter_sw1/src/models/user.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<List<User>> obtenerUsuarios() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final url = ApiConfig.baseUrl;
  final uri = Uri.parse('$url/api/users');
  final token = prefs.getString('auth_token') ?? '';

  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => User.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load users');
  }
}

Future<void> updateDispositivo(String dispositivo, int id) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final url = ApiConfig.baseUrl;
  final uri = Uri.parse('$url/api/users/${id.toString()}');
  final token = prefs.getString('auth_token') ?? '';

  final response = await http.patch(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'dispositivo': dispositivo}),
  );

  if (response.statusCode != 200) {
    throw Exception('Error al actualizar el dispositivo');
  }
}
