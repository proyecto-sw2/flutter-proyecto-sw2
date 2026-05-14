import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PublicationsService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> getPublications({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/publicaciones?page=$page&limit=$limit',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al obtener publicaciones: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<List<dynamic>> getComments(int publicationId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/publicaciones/$publicationId/comentarios',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['comentarios'] ?? [];
      } else {
        throw Exception('Error al obtener comentarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> createComment(
    int publicationId,
    String content,
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/publicaciones/$publicationId/comentarios';
      print('🔗 URL de comentario: $url');
      print('📝 Contenido: $content');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: json.encode({'contenido_texto': content}),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        // Error más específico
        String errorMessage = 'Error al crear comentario';

        try {
          final errorBody = json.decode(response.body);
          if (errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          }
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty ? response.body : 'Error desconocido';
        }

        throw Exception(
          '❌ Error ${response.statusCode}: $errorMessage\n🔗 URL: $url',
        );
      }
    } catch (e) {
      throw Exception('💥 Error: $e');
    }
  }

  static Future<Map<String, dynamic>> createReply(
    int publicationId,
    int parentCommentId,
    String content,
  ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}/publicaciones/$publicationId/comentarios/$parentCommentId/respuestas';
      print('🔗 URL de respuesta: $url');
      print('📝 Contenido: $content');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getToken()}',
        },
        body: json.encode({'contenido_texto': content}),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('🔧 Response Headers: ${response.headers}');

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        // Error más específico con detalles del servidor
        String errorMessage = 'Error al crear respuesta';

        try {
          final errorBody = json.decode(response.body);
          if (errorBody['message'] != null) {
            errorMessage = errorBody['message'];
          } else if (errorBody['error'] != null) {
            errorMessage = errorBody['error'];
          }
        } catch (e) {
          // Si no se puede parsear el JSON, usar el body como texto
          errorMessage =
              response.body.isNotEmpty ? response.body : 'Error desconocido';
        }

        throw Exception(
          '❌ Error ${response.statusCode}: $errorMessage\n🔗 URL: $url\n📝 Contenido enviado: $content',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
          '🌐 Error de conexión: Verifica tu conexión a internet y que el servidor esté funcionando. Detalles: $e',
        );
      } else if (e.toString().contains('FormatException')) {
        throw Exception('📄 Error de formato en la respuesta del servidor: $e');
      } else {
        throw Exception('💥 Error inesperado: $e');
      }
    }
  }

  static Future<void> createPubMaps(String titulo, String desc, int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final url = ApiConfig.baseUrl;
    final uri = Uri.parse('$url/publicaciones');
    final token = prefs.getString('auth_token') ?? '';
    final contenidoTexto = '$titulo -- $desc';

    if (token.isEmpty) {
      print('❌ Token de autenticación no encontrado');
      return;
    }

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contenido_texto': contenidoTexto,
          'id_incidente': id,
        }),
      );

      if (response.statusCode == 201) {
        print('✅ Publicacion creada exitosamente');
        return;
      } else {
        print('⚠️ Error al crear incidente: ${response.statusCode}');
        print('Detalles: ${response.body}');
      }
    } catch (e) {
      print('❌ Error de red o inesperado: $e');
    }
  }
}
