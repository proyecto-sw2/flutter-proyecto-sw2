import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart'; 

class ContentModerationService {
  
  // Moderación básica de imágenes (sin APIs externas)
  static Future<SafeSearchResult> analyzeImage(File imageFile) async {
    try {
      // Verificar tamaño del archivo (máximo 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        return SafeSearchResult(
          adult: 5, // VERY_LIKELY para rechazar
          violence: 1,
          racy: 1,
          medical: 1,
          spoof: 1,
        );
      }

      // Verificar extensión del archivo
      final extension = imageFile.path.split('.').last.toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!allowedExtensions.contains(extension)) {
        return SafeSearchResult(
          adult: 5, // VERY_LIKELY para rechazar
          violence: 1,
          racy: 1,
          medical: 1,
          spoof: 1,
        );
      }

      // Aprobar todas las imágenes que pasen las verificaciones básicas
      return SafeSearchResult(
        adult: 1, // VERY_UNLIKELY (aprobar)
        violence: 1,
        racy: 1,
        medical: 1,
        spoof: 1,
      );
    } catch (e) {
      // En caso de error, rechazar la imagen
      return SafeSearchResult(
        adult: 5,
        violence: 1,
        racy: 1,
        medical: 1,
        spoof: 1,
      );
    }
  }
  
  // Analizar imagen con Google Vision API
  /*static Future<SafeSearchResult> analyzeImage(File imageFile) async {
    try {
      // Convertir imagen a base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Usar la API key desde el archivo centralizado
      final url = 'https://vision.googleapis.com/v1/images:annotate?key=${ApiKeys.visionApiKey}';
      
      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image
            },
            'features': [
              {
                'type': 'SAFE_SEARCH_DETECTION',
                'maxResults': 1
              }
            ]
          }
        ]
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final safeSearch = data['responses'][0]['safeSearchAnnotation'];
        
        return SafeSearchResult(
          adult: _getLikelihoodLevel(safeSearch['adult']),
          violence: _getLikelihoodLevel(safeSearch['violence']),
          racy: _getLikelihoodLevel(safeSearch['racy']),
          medical: _getLikelihoodLevel(safeSearch['medical']),
          spoof: _getLikelihoodLevel(safeSearch['spoof']),
        );
      } else {
        throw Exception('Error en Vision API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error analizando imagen: $e');
    }
  }*/
  
  // Analizar texto con Perspective API (Google)
  static Future<TextModerationResult> analyzeText(String text) async {
    try {
      const url = 'https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze';
      
      final requestBody = {
        'requestedAttributes': {
          'TOXICITY': {},
          'SEVERE_TOXICITY': {},
          'IDENTITY_ATTACK': {},
          'INSULT': {},
          'PROFANITY': {},
          'THREAT': {},
        },
        'comment': {
          'text': text
        },
        'languages': ['es', 'en'],
      };
      
      // Usar la API key desde el archivo centralizado
      final response = await http.post(
        Uri.parse('$url?key=${ApiKeys.perspectiveApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final scores = data['attributeScores'];
        
        return TextModerationResult(
          toxicity: scores['TOXICITY']['summaryScore']['value'],
          severeToxicity: scores['SEVERE_TOXICITY']['summaryScore']['value'],
          identityAttack: scores['IDENTITY_ATTACK']['summaryScore']['value'],
          insult: scores['INSULT']['summaryScore']['value'],
          profanity: scores['PROFANITY']['summaryScore']['value'],
          threat: scores['THREAT']['summaryScore']['value'],
        );
      } else {
        throw Exception('Error en Perspective API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error analizando texto: $e');
    }
  }
  
  static int _getLikelihoodLevel(String likelihood) {
    switch (likelihood) {
      case 'VERY_UNLIKELY': return 1;
      case 'UNLIKELY': return 2;
      case 'POSSIBLE': return 3;
      case 'LIKELY': return 4;
      case 'VERY_LIKELY': return 5;
      default: return 1;
    }
  }
}

class SafeSearchResult {
  final int adult;
  final int violence;
  final int racy;
  final int medical;
  final int spoof;
  
  SafeSearchResult({
    required this.adult,
    required this.violence,
    required this.racy,
    required this.medical,
    required this.spoof,
  });
  
  bool get isAppropriate {
    // Considera inapropiado si cualquier categoría es LIKELY (4) o VERY_LIKELY (5)
    return adult < 4 && violence < 4 && racy < 4;
  }
  
  String get reason {
    List<String> reasons = [];
    if (adult >= 4) {
      if (adult == 5 && violence == 1 && racy == 1) {
        // Caso especial: error de archivo
        reasons.add('archivo no válido o demasiado grande');
      } else {
        reasons.add('contenido adulto');
      }
    }
    if (violence >= 4) reasons.add('violencia');
    if (racy >= 4) reasons.add('contenido sugerente');
    return reasons.join(', ');
  }
}

class TextModerationResult {
  final double toxicity;
  final double severeToxicity;
  final double identityAttack;
  final double insult;
  final double profanity;
  final double threat;
  
  TextModerationResult({
    required this.toxicity,
    required this.severeToxicity,
    required this.identityAttack,
    required this.insult,
    required this.profanity,
    required this.threat,
  });
  
  bool get isAppropriate {
    // Umbral de 0.7 para considerar contenido inapropiado
    return toxicity < 0.7 && 
           severeToxicity < 0.7 && 
           identityAttack < 0.7 && 
           insult < 0.7 && 
           profanity < 0.7 && 
           threat < 0.7;
  }
  
  String get reason {
    List<String> reasons = [];
    if (toxicity >= 0.7) reasons.add('contenido tóxico');
    if (severeToxicity >= 0.7) reasons.add('contenido muy tóxico');
    if (identityAttack >= 0.7) reasons.add('ataque de identidad');
    if (insult >= 0.7) reasons.add('insultos');
    if (profanity >= 0.7) reasons.add('profanidad');
    if (threat >= 0.7) reasons.add('amenazas');
    return reasons.join(', ');
  }
}