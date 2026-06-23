import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../config/config.dart';
import '../theme/app_colors.dart';

class PublicVerificationPage extends StatefulWidget {
  const PublicVerificationPage({super.key});

  @override
  State<PublicVerificationPage> createState() => _PublicVerificationPageState();
}

class _PublicVerificationPageState extends State<PublicVerificationPage> {
  final TextEditingController _txHashController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  Future<void> _verifyHash() async {
    final txHash = _txHashController.text.trim();
    if (txHash.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/public/incidentes/verificar/$txHash');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          _result = jsonDecode(response.body);
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'El txHash ingresado no existe en los registros de la aplicación.';
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudo conectar a Sepolia o el sistema no está disponible temporalmente.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: no se pudo consultar el sistema.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación en Blockchain', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Consulta un reporte directamente en la blockchain de Ethereum (Sepolia)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _txHashController,
              decoration: InputDecoration(
                labelText: 'Ingresa el txHash',
                hintText: '0x...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _txHashController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyHash,
              icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search),
              label: const Text('Verificar Autenticidad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 30),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            if (_result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified, color: Colors.green),
                              SizedBox(width: 10),
                              Text('Reporte Verificado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                          const Divider(),
                          _buildDetailRow('Hash del Reporte (SHA-256):', _result!['hash_reporte'] ?? 'No disponible'),
                          _buildDetailRow('Descripción:', _result!['descripcion'] ?? 'No disponible'),
                          _buildDetailRow('Coordenadas GPS:', _result!['gps'] ?? 'No disponible'),
                          _buildDetailRow('Fecha/Hora (Timestamp):', _result!['timestamp_bd'] != null ? DateTime.parse(_result!['timestamp_bd']).toLocal().toString() : 'No disponible'),
                          const SizedBox(height: 12),
                          const Text('Estado Blockchain:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(_result!['estado_confirmacion']?.toString().toUpperCase() ?? 'PENDIENTE', style: const TextStyle(fontSize: 16)),
                          
                          if (_result!['video_url'] != null) ...[
                            const SizedBox(height: 12),
                            const Text('Evidencia Multimedia:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            ElevatedButton.icon(
                              onPressed: () => _launchUrl(_result!['video_url']),
                              icon: const Icon(Icons.video_library),
                              label: const Text('Ver Video de Evidencia'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                          
                          if (_result!['error'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('Nota: ${_result!["error"]}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(height: 20),
                          if (_result!['etherscan_url'] != null)
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () => _launchUrl(_result!['etherscan_url']),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Ver en Etherscan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
