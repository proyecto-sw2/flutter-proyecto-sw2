import 'dart:convert';
import 'package:http/http.dart' as http;

// 192.168.0.15
class GptService {
  final String baseUrl = 'http://10.0.2.2:5000';

  Future<String> getChatResponse(String prompt) async {
    final url = Uri.parse("$baseUrl/qa");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"question": prompt}),
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
