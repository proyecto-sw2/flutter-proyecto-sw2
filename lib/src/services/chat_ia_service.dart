import 'dart:convert';
import 'package:flutter_sw1/src/config/config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 192.168.0.15
class GptService {
  final String baseUrl = ApiConfig.baseIA;

  Future<String> getChatResponse(String prompt) async {
    final url = Uri.parse("$baseUrl/qa");
    SharedPreferences? _prefs = await SharedPreferences.getInstance();
    final id = _prefs.getInt('user_id') ?? 0;
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": prompt, "chat_id": id}),
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decodedBody);
        return data['response'];
      } else {
        return "Error en el servidor";
      }
    } catch (e) {
      return "No se pudo conectar con el servidor";
    }
  }
}
