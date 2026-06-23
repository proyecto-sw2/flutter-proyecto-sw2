import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_sw1/src/services/local_evidence_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';

class LocalEvidencesPage extends StatefulWidget {
  const LocalEvidencesPage({super.key});

  @override
  State<LocalEvidencesPage> createState() => _LocalEvidencesPageState();
}

class _LocalEvidencesPageState extends State<LocalEvidencesPage> {
  List<LocalEvidence> _evidences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvidences();
  }

  Future<void> _loadEvidences() async {
    final evs = await LocalEvidenceService.getEvidences();
    setState(() {
      _evidences = evs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mis Evidencias Locales'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _evidences.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _evidences.length,
                  itemBuilder: (context, index) {
                    return _EvidenceCard(evidence: _evidences[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay evidencias guardadas localmente',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final LocalEvidence evidence;
  const _EvidenceCard({required this.evidence});

  void _openPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(videoPath: evidence.path, evidence: evidence),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(evidence.timestamp);
    final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openPlayer(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniatura
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.black,
                  child: evidence.thumbnailPath.isNotEmpty && File(evidence.thumbnailPath).existsSync()
                      ? Image.file(File(evidence.thumbnailPath), fit: BoxFit.cover)
                      : const Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(width: 16),
              // Detalles
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grabación $formattedDate',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.security, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Firmado Digitalmente', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hash: ${evidence.hash.substring(0, 15)}...',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String videoPath;
  final LocalEvidence evidence;
  
  const VideoPlayerPage({super.key, required this.videoPath, required this.evidence});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _isPlaying = true;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  void _showSignatureDetails() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Detalles de Seguridad'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hash SHA-256 (Original):', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.evidence.hash, style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 12),
              const Text('Firma Digital RSA Local:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.evidence.signature, style: const TextStyle(fontSize: 10)),
              const SizedBox(height: 12),
              const Text('Ruta Física:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(widget.evidence.path, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showSignatureDetails,
            tooltip: 'Detalles de Firma',
          )
        ],
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controller),
                    VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.red)),
                    Center(
                      child: IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: _togglePlay,
                      ),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
