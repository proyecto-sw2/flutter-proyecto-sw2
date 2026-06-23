import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;

class LocalEvidence {
  final String id;
  final String path;
  final String hash;
  final String signature;
  final String timestamp;
  final String thumbnailPath;

  LocalEvidence({
    required this.id,
    required this.path,
    required this.hash,
    required this.signature,
    required this.timestamp,
    required this.thumbnailPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'hash': hash,
        'signature': signature,
        'timestamp': timestamp,
        'thumbnailPath': thumbnailPath,
      };

  factory LocalEvidence.fromJson(Map<String, dynamic> json) => LocalEvidence(
        id: json['id'],
        path: json['path'],
        hash: json['hash'],
        signature: json['signature'],
        timestamp: json['timestamp'],
        thumbnailPath: json['thumbnailPath'] ?? '',
      );
}

class LocalEvidenceService {
  static const String _keyPrivateKey = 'evidence_private_key';
  static const String _keyPublicKey = 'evidence_public_key';
  static const String _keyRegistry = 'local_evidences_registry';

  // ── 1. Gestin de Llaves RSA ───────────────────────────────────────────────

  static Future<void> _ensureKeysExist() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyPrivateKey) || !prefs.containsKey(_keyPublicKey)) {
      // Generar nuevas llaves RSA de 2048 bits
      final keyGen = RSAKeyGenerator()
        ..init(crypto.ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          _getSecureRandom(),
        ));
      
      final pair = keyGen.generateKeyPair();
      final publicKey = pair.publicKey as RSAPublicKey;
      final privateKey = pair.privateKey as RSAPrivateKey;

      final pemPublicKey = _encodePublicKeyToPem(publicKey);
      final pemPrivateKey = _encodePrivateKeyToPem(privateKey);

      await prefs.setString(_keyPublicKey, pemPublicKey);
      await prefs.setString(_keyPrivateKey, pemPrivateKey);
    }
  }

  static Future<String> getPublicKey() async {
    await _ensureKeysExist();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPublicKey) ?? '';
  }

  // ── 2. Guardado y Firma de Video ──────────────────────────────────────────

  static Future<LocalEvidence> saveAndSignVideo(File tempVideoFile) async {
    await _ensureKeysExist();
    
    // Calcular Hash SHA-256
    final bytes = await tempVideoFile.readAsBytes();
    final hashDigest = sha256.convert(bytes);
    final videoHash = hashDigest.toString();

    // Firmar el Hash
    final prefs = await SharedPreferences.getInstance();
    final pemPrivateKey = prefs.getString(_keyPrivateKey)!;
    final privateKey = _parsePrivateKeyFromPem(pemPrivateKey);
    
    final signer = encrypt_pkg.Signer(encrypt_pkg.RSASigner(encrypt_pkg.RSASignDigest.SHA256, privateKey: privateKey));
    final signature = signer.sign(videoHash).base64;

    // Mover a Directorio Seguro Local
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'evidence_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final savedVideo = await tempVideoFile.copy('${appDir.path}/$fileName');

    // Generar miniatura
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: savedVideo.path,
      thumbnailPath: appDir.path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 200,
      quality: 75,
    );

    // Crear Entidad y Guardar en Registro
    final evidence = LocalEvidence(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: savedVideo.path,
      hash: videoHash,
      signature: signature,
      timestamp: DateTime.now().toIso8601String(),
      thumbnailPath: thumbPath ?? '',
    );

    await _addToRegistry(evidence);

    return evidence;
  }

  // ── 3. Registro Local (JSON) ──────────────────────────────────────────────

  static Future<void> _addToRegistry(LocalEvidence evidence) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyRegistry);
    List<dynamic> list = jsonStr != null ? jsonDecode(jsonStr) : [];
    list.add(evidence.toJson());
    await prefs.setString(_keyRegistry, jsonEncode(list));
  }

  static Future<List<LocalEvidence>> getEvidences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyRegistry);
    if (jsonStr == null) return [];
    
    List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => LocalEvidence.fromJson(e)).toList().reversed.toList();
  }

  // ── Utilidades RSA ────────────────────────────────────────────────────────

  static FortunaRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(crypto.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  static String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    // Usaremos un string simple de n y e ya que codificar PEM real en Dart manual es largo,
    // y encrypt puede leer directamente RSAPublicKey o podemos usar PEM.
    // Usaremos el serializador de pointycastle / encrypt.
    // Para simplificar la compatibilidad con el backend, enviamos la llave pblica codificada as:
    return '{"n": "${publicKey.n.toString()}", "e": "${publicKey.exponent.toString()}"}';
  }

  static String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    return '{"n": "${privateKey.n.toString()}", "d": "${privateKey.privateExponent.toString()}", "p": "${privateKey.p.toString()}", "q": "${privateKey.q.toString()}"}';
  }

  static RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
    final map = jsonDecode(pem);
    final n = BigInt.parse(map['n']);
    final d = BigInt.parse(map['d']);
    final p = BigInt.parse(map['p']);
    final q = BigInt.parse(map['q']);
    // RSAPrivateKey(n, d, p, q)
    return RSAPrivateKey(n, d, p, q);
  }
}
