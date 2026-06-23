import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/models/incident.dart';
import 'package:flutter_sw1/src/services/incident_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MisIncidentesPage extends StatefulWidget {
  const MisIncidentesPage({super.key});

  @override
  State<MisIncidentesPage> createState() => _MisIncidentesPageState();
}

class _MisIncidentesPageState extends State<MisIncidentesPage> {
  List<Incidente> _incidentes = [];
  bool _cargando = true;
  final Set<int> _descargando = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final lista = await getMisIncidentes();
    if (mounted) setState(() {
      _incidentes = lista;
      _cargando = false;
    });
  }

  Future<void> _obtenerCertificado(Incidente incidente, {bool compartir = false}) async {
    setState(() => _descargando.add(incidente.idIncidente));
    try {
      final resultado = await descargarCertificado(incidente.idIncidente);

      if (!mounted) return;

      if (resultado.pendienteMsg != null) {
        _mostrarInfo(resultado.pendienteMsg!);
        return;
      }

      final bytes = resultado.bytes!;
      final dir = await getTemporaryDirectory();
      final archivo = File(
          '${dir.path}/certificado-incidente-${incidente.idIncidente}.pdf');
      await archivo.writeAsBytes(bytes);

      if (compartir) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(archivo.path)],
            text:
                'Certificado blockchain de mi reporte #${incidente.idIncidente}',
          ),
        );
      } else {
        final resultado = await OpenFile.open(archivo.path);
        if (resultado.type != ResultType.done && mounted) {
          _mostrarError(
              'No se encontró una app para abrir PDF. Intenta compartirlo.');
        }
      }
    } catch (e) {
      if (mounted) _mostrarError('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _descargando.remove(incidente.idIncidente));
    }
  }

  void _mostrarInfo(String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.hourglass_top, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 8),
          const Text('Registro pendiente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(mensaje),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(mensaje, textAlign: TextAlign.center)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mis Incidentes',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _incidentes.isEmpty
              ? _buildVacio()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _incidentes.length,
                    itemBuilder: (ctx, i) =>
                        _buildTarjeta(_incidentes[i]),
                  ),
                ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.report_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No tienes incidentes reportados',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTarjeta(Incidente inc) {
    final status = inc.blockchainStatus ?? 'sin_registro';
    final confirmado = status == 'confirmado';
    final pendiente = status == 'pendiente';
    final descargandoEste = _descargando.contains(inc.idIncidente);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    inc.tipoIncidente.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                _chipBlockchain(status),
              ],
            ),
            const SizedBox(height: 10),

            // ── Datos ────────────────────────────────────────────────────
            Text(inc.descripcion,
                style:
                    const TextStyle(fontSize: 13, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.location_on,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(inc.latitudLongitud,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
              const Spacer(),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(inc.fechaIncidente),
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ]),

            // ── txHash ───────────────────────────────────────────────────
            if (inc.txHash != null) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.link, size: 13, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    inc.txHash!,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey,
                        fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 12),

            // ── Botones ──────────────────────────────────────────────────
            if (confirmado)
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: descargandoEste
                        ? null
                        : () => _obtenerCertificado(inc),
                    icon: descargandoEste
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Abrir PDF',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: descargandoEste
                        ? null
                        : () =>
                            _obtenerCertificado(inc, compartir: true),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Compartir',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ])
            else if (pendiente)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _mostrarInfo(
                    'La transacción blockchain está siendo procesada. '
                    'El certificado PDF estará disponible una vez que sea confirmada en Sepolia.',
                  ),
                  icon: const Icon(Icons.hourglass_top,
                      size: 16, color: Colors.orange),
                  label: const Text('Certificado pendiente',
                      style:
                          TextStyle(fontSize: 12, color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sin registro blockchain',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chipBlockchain(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case 'confirmado':
        color = Colors.green.shade700;
        icon = Icons.verified;
        label = 'Confirmado';
        break;
      case 'pendiente':
        color = Colors.orange.shade700;
        icon = Icons.hourglass_top;
        label = 'Pendiente';
        break;
      case 'fallido':
        color = Colors.red.shade700;
        icon = Icons.error_outline;
        label = 'Fallido';
        break;
      default:
        color = Colors.grey.shade600;
        icon = Icons.help_outline;
        label = 'Sin registro';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
