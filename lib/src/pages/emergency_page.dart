import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/pages/emergency_contacts_page.dart';
import 'package:flutter_sw1/src/pages/panic_button_page.dart';
import 'package:flutter_sw1/src/pages/emergency_history_page.dart';
import 'package:flutter_sw1/src/pages/local_evidences_page.dart';
import 'package:flutter_sw1/src/services/emergency_sync_service.dart';
import 'package:flutter_sw1/src/services/offline_emergency_queue.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:animate_do/animate_do.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  int _pendingAlerts = 0;
  SyncStatus _syncStatus = SyncStatus.idle;

  @override
  void initState() {
    super.initState();
    _loadPending();
    // Iniciar el servicio de sync y escuchar cambios de estado
    EmergencySyncService.instance.start();
    EmergencySyncService.instance.statusStream.listen((status) {
      if (!mounted) return;
      setState(() => _syncStatus = status);
      if (status == SyncStatus.done || status == SyncStatus.error) {
        _loadPending();
      }
    });
  }

  Future<void> _loadPending() async {
    final count = await OfflineEmergencyQueue.getPendingCount();
    if (mounted) setState(() => _pendingAlerts = count);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Emergencia'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_pendingAlerts > 0)
            _SyncBadge(
              count: _pendingAlerts,
              status: _syncStatus,
              onTap: () => EmergencySyncService.instance.syncPending(),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Alerta offline pendiente
                if (_pendingAlerts > 0)
                  _PendingSyncBanner(
                    count: _pendingAlerts,
                    status: _syncStatus,
                    onSync: () => EmergencySyncService.instance.syncPending(),
                  ).fadeInDown(duration: const Duration(milliseconds: 300)),

                if (_pendingAlerts > 0) const SizedBox(height: 12),

                // ── Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Column(children: [
                    const Icon(Icons.emergency, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    const Text(
                      'Sistema de Emergencia',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acceso rápido a funciones de seguridad',
                      style: TextStyle(fontSize: 14, color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ]),
                ).fadeInDown(duration: const Duration(milliseconds: 500)),

                const SizedBox(height: 24),

                // ── Botón de pánico
                _PanicButtonCard(
                  onTap: () => _showConfirmation(context),
                ).fadeInUp(duration: const Duration(milliseconds: 600)),

                const SizedBox(height: 20),

                // ── Opciones adicionales
                Row(children: [
                  Expanded(
                    child: _buildOption(
                      context,
                      icon: Icons.contacts,
                      title: 'Contactos',
                      subtitle: 'Gestionar contactos de emergencia',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EmergencyContactsPage())),
                    ).fadeInLeft(duration: const Duration(milliseconds: 700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildOption(
                      context,
                      icon: Icons.history,
                      title: 'Historial',
                      subtitle: 'Ver alertas anteriores',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EmergencyHistoryPage())),
                    ).fadeInRight(duration: const Duration(milliseconds: 700)),
                  ),
                ]),

                const SizedBox(height: 12),

                // Nuevo Botón de Evidencias Locales (HU02)
                _buildOption(
                  context,
                  icon: Icons.video_library,
                  title: 'Mis Evidencias',
                  subtitle: 'Videos firmados localmente',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LocalEvidencesPage())),
                ).fadeInUp(duration: const Duration(milliseconds: 800)),

                const SizedBox(height: 20),

                // ── Info de seguridad
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Información de Seguridad',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          '• El botón grabará hasta 15 min de video y enviará tu ubicación\n'
                          '• Tus contactos serán notificados por WhatsApp y email\n'
                          '• Funciona sin internet: sincroniza al recuperar señal\n'
                          '• Solo usa en situaciones de emergencia real',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                              height: 1.5),
                        ),
                      ]),
                ).fadeInUp(duration: const Duration(milliseconds: 800)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: color),
                  const SizedBox(height: 8),
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 10, color: color.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning, color: Colors.red, size: 28),
          SizedBox(width: 8),
          Expanded(child: Text('Confirmar Emergencia')),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres activar el botón de pánico?',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text('Esta acción:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Grabará hasta 15 min de video'),
            Text('• Enviará tu ubicación exacta'),
            Text('• Notificará a contactos por WhatsApp y email'),
            SizedBox(height: 12),
            Text('Solo usa en emergencias reales.',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PanicButtonPage()),
              ).then((_) => _loadPending());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _PanicButtonCard extends StatelessWidget {
  const _PanicButtonCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.red.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.emergency, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🚨 BOTÓN DE PÁNICO',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 4),
                    Text('Activar alerta de emergencia',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                    SizedBox(height: 2),
                    Text('📧 WhatsApp + Email a contactos',
                        style: TextStyle(fontSize: 11, color: Colors.white60)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PendingSyncBanner extends StatelessWidget {
  const _PendingSyncBanner({
    required this.count,
    required this.status,
    required this.onSync,
  });
  final int count;
  final SyncStatus status;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final isSyncing = status == SyncStatus.syncing;
    final isDone = status == SyncStatus.done;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDone ? Colors.green.shade300 : Colors.orange.shade300),
      ),
      child: Row(children: [
        Icon(
          isDone ? Icons.check_circle : Icons.sync,
          color: isDone ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isDone
                ? 'Alertas sincronizadas correctamente'
                : isSyncing
                    ? 'Sincronizando alertas offline...'
                    : '$count alerta(s) pendiente(s) de enviar',
            style: TextStyle(
                color: isDone ? Colors.green.shade800 : Colors.orange.shade800,
                fontSize: 13),
          ),
        ),
        if (!isSyncing && !isDone)
          TextButton(
            onPressed: onSync,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text('Reenviar',
                style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        if (isSyncing) const SizedBox(width: 10),
        if (isSyncing)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
      ]),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge(
      {required this.count, required this.status, required this.onTap});
  final int count;
  final SyncStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.sync, color: Colors.white),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                  color: Colors.orange, shape: BoxShape.circle),
              child: Text('$count',
                  style:
                      const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}
