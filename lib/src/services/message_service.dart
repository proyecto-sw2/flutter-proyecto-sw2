import 'dart:convert';
import 'package:flutter_sw1/src/config/config.dart';
import 'package:flutter_sw1/src/models/chat_message.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<ChatMessage?> obtenerChats(int? chatId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  String baseUrl = ApiConfig.baseIA;
  final uri = Uri.parse(
    '$baseUrl/chats${chatId != null ? '?chat_id=$chatId' : ''}',
  );

  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);

    if (chatId != null) {
      return ChatMessage.fromJson(jsonData);
    }
    return null;
  } else {
    throw Exception('Error al obtener los chats: ${response.body}');
  }
}

Future<void> eliminarMensajesDelChat(int chatId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  String baseUrl = ApiConfig.baseIA;
  final uri = Uri.parse('$baseUrl/chat/$chatId/messages');

  final response = await http.delete(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    print(jsonData['message']); // Mensaje de confirmación
  } else {
    print('Error al eliminar mensajes: ${response.body}');
  }
}
