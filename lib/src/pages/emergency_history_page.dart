import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sw1/src/models/emergency_alert.dart';
import 'package:flutter_sw1/src/services/emergency_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';

class EmergencyHistoryPage extends StatefulWidget {
  const EmergencyHistoryPage({super.key});

  @override
  State<EmergencyHistoryPage> createState() => _EmergencyHistoryPageState();
}

class _EmergencyHistoryPageState extends State<EmergencyHistoryPage> {
  late Future<List<EmergencyAlert>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = EmergencyService.getEmergencyAlerts();
  }

  Future<void> _refresh() async {
    setState(() {
      _alertsFuture = EmergencyService.getEmergencyAlerts();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'fallido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmado':
        return 'Confirmado en Cadena';
      case 'pendiente':
        return 'Pendiente en Blockchain';
      case 'fallido':
        return 'Fallo en Registro';
      default:
        return 'Sin Registro (Offline)';
    }
  }

  Future<void> _downloadCertificate(int id) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await EmergencyService.getEmergencyCertificate(id);
      Navigator.pop(context); // Close dialog

      if (result['status'] == 'confirmado' && result['url'] != null) {
        final url = Uri.parse(result['url']);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('No se pudo abrir el certificado');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Certificado no disponible aún'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _launchEtherscan(String? txHash) async {
    if (txHash == null || txHash.isEmpty) return;
    final url = Uri.parse('https://sepolia.etherscan.io/tx/$txHash');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Etherscan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Emergencias'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<EmergencyAlert>>(
          future: _alertsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error.toString().replaceAll('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Reintentar'),
                      )
                    ],
                  ),
                ),
              );
            }

            final alerts = snapshot.data ?? [];

            if (alerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes emergencias registradas.',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final statusColor = _getStatusColor(alert.blockchainStatus);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              alert.type.name.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                _getStatusText(alert.blockchainStatus),
                                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              alert.createdAt.toLocal().toString().split('.')[0],
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        if (alert.location != null && alert.location!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  alert.location!,
                                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (alert.blockchainStatus == 'confirmado')
                              TextButton.icon(
                                onPressed: () => _downloadCertificate(alert.id),
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                label: const Text('Certificado', style: TextStyle(color: Colors.red)),
                              ),
                            if (alert.txHash != null && alert.txHash!.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => _launchEtherscan(alert.txHash),
                                icon: const Icon(Icons.open_in_browser, color: Colors.blue),
                                label: const Text('Etherscan', style: TextStyle(color: Colors.blue)),
                              ),
                          ],
                        )
                      ],
                    ),
                  ).fadeInUp(duration: Duration(milliseconds: 300 + (index * 100))),
                );
              },
            );
          },
        ),
      ),
    );
  }
}