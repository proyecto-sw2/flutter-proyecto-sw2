import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/pages/create_publication_page.dart';
import 'package:flutter_sw1/src/pages/prueba_page.dart';
import 'package:flutter_sw1/src/services/incident_service.dart';
import 'package:flutter_sw1/src/services/publications_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:flutter_sw1/src/widgets/comments_bottom_sheet.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<dynamic> _publications = [];
  bool _isLoadingPublications = false;
  bool _hasMorePublications = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPublications();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingPublications && _hasMorePublications) {
        _loadMorePublications();
      }
    }
  }

  Future<void> _loadPublications() async {
    if (_isLoadingPublications) return;

    setState(() {
      _isLoadingPublications = true;
    });

    try {
      final response = await PublicationsService.getPublications(
        page: 1,
        limit: 10,
      );
      setState(() {
        _publications = response['publicaciones'] ?? [];
        _currentPage = 1;
        _hasMorePublications = (_publications.length >= 10);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar publicaciones: $e')),
      );
    } finally {
      setState(() {
        _isLoadingPublications = false;
      });
    }
  }

  Future<void> _loadMorePublications() async {
    if (_isLoadingPublications) return;

    setState(() {
      _isLoadingPublications = true;
    });

    try {
      final response = await PublicationsService.getPublications(
        page: _currentPage + 1,
        limit: 10,
      );
      final newPublications = response['publicaciones'] ?? [];

      setState(() {
        _publications.addAll(newPublications);
        _currentPage++;
        _hasMorePublications = newPublications.length >= 10;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar más publicaciones: $e')),
      );
    } finally {
      setState(() {
        _isLoadingPublications = false;
      });
    }
    // _currentIndex =
    //     widget.initialIndex ?? 2; // Usar el índice pasado o 2 por defecto
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Comunidad',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
        ),
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón para crear publicación (sin header "Comunidad")
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreatePublicationPage(),
                      ),
                    );
                    if (result == true) {
                      _loadPublications();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 6,
                    shadowColor: AppColors.primary.withAlpha(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.primary.withAlpha(37),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crear Publicación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Comparte con la comunidad tus dudas',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary.withAlpha(175),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Lista de publicaciones
              Expanded(
                child:
                    _isLoadingPublications && _publications.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : RefreshIndicator(
                          onRefresh: () async {
                            _currentPage = 1;
                            _hasMorePublications = true;
                            _publications.clear();
                            await _loadPublications();
                          },
                          child:
                              _publications.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.article_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay publicaciones aún',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Sé el primero en compartir algo',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : ListView.builder(
                                    controller: _scrollController,
                                    itemCount:
                                        _publications.length +
                                        (_hasMorePublications ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _publications.length) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      return _buildPublicationCard(
                                        _publications[index],
                                      );
                                    },
                                  ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPublicationCard(Map<String, dynamic> publication) {
    String? imageUrl = publication['ruta_media'];
    Map<String, dynamic>? ubicacion = publication['incidente'];
    LatLng? latLng;
    if (ubicacion != null) {
      String posicion = ubicacion['latitud_longitud'];
      latLng = stringToLatLng(posicion);
      // String titulo = ubicacion['tipo_incidente'];
    }
    if (imageUrl != null) {
      imageUrl = imageUrl.trim().replaceAll('`', '').replaceAll(' ', '');
      if (imageUrl.isEmpty) imageUrl = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con usuario y fecha
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 24,
                  child: Text(
                    (publication['usuario']?['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication['usuario']?['name'] ?? 'Usuario',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatDate(publication['fecha_publicacion']),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ubicacion != null && ubicacion.isNotEmpty
                    ? Column(
                      spacing: 12,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return Pruebaa(initialTarget: latLng);
                                },
                              ),
                            );
                          },
                          child: Lottie.asset(
                            'assets/pin.json',
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Text(
                          'Ir',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                    : const SizedBox.shrink(),
              ],
            ),

            const SizedBox(height: 12),

            // Contenido de texto
            if (publication['contenido_texto'] != null &&
                publication['contenido_texto'].isNotEmpty)
              Text(
                publication['contenido_texto'],
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),

            // Imagen si existe
            if (imageUrl != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showFullScreenImage(imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error al cargar imagen',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showCommentsBottomSheet(publication),
                  icon: Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    '${publication['total_comentarios'] ?? 0} comentarios',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              // Imagen en pantalla completa
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Botón de cerrar
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Fecha desconocida';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return DateFormat('dd/MM/yyyy').format(date);
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Ahora';
      }
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  void _showCommentsBottomSheet(Map<String, dynamic> publication) {
    final publicationId = publication['id_publicacion'];
    int? id;

    if (publicationId is int) {
      id = publicationId;
    } else if (publicationId is String) {
      id = int.tryParse(publicationId);
    }

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID de publicación inválido')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CommentsBottomSheet(
            publicationId: id!,
            publicationTitle: publication['contenido_texto'] ?? 'Publicación',
          ),
    );
  }
}
