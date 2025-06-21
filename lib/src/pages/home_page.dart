import 'dart:convert';
import 'dart:io';

import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'quiz_page.dart';
import 'create_publication_page.dart';
import '../services/publications_service.dart';
import '../services/content_moderation_service.dart';
import '../widgets/comments_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  final int? initialIndex;
  const HomePage({super.key, this.initialIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;
  List<dynamic> _publications = [];
  bool _isLoadingPublications = false;
  int _currentPage = 1;
  bool _hasMorePublications = true;
  final ScrollController _scrollController = ScrollController();
  File? _imageFile;
  String? _descripcion;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _descripcion = null;
      });
      await _enviarImagen(File(picked.path));
    }
  }

  Future<void> _enviarImagen(File imagen) async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://v9k5scrk-8000.brs.devtunnels.ms/analizar',
    ); // Cambia si usas IP real

    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath('file', imagen.path));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final data = json.decode(respStr);

      if (response.statusCode == 200) {
        setState(() {
          _descripcion = data['descripcion'];
        });
      } else {
        setState(() {
          _descripcion = 'Error: ${data['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _descripcion = 'Error al enviar la imagen: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _limpiarEstado() {
    setState(() {
      _imageFile = null;
      _descripcion = null;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 2;
    _scrollController.addListener(_onScroll);
    if (_currentIndex == 4) {
      _loadPublications();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    _currentIndex =
        widget.initialIndex ?? 2; // Usar el índice pasado o 2 por defecto
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: ConvexAppBar(
        items: [
          TabItem(icon: Icons.document_scanner, title: 'Escáner'),
          TabItem(icon: Icons.error, title: 'Emergencia'),
          TabItem(icon: Icons.home, title: 'Inicio'),
          TabItem(icon: Icons.map, title: 'Incidente'),
          TabItem(icon: Icons.groups, title: 'Comunidad'),
        ],
        backgroundColor: AppColors.primary,
        color: Colors.grey.shade200,
        initialActiveIndex: _currentIndex,
        height: 60,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 4 && _publications.isEmpty) {
            _loadPublications();
          }
        },
      ),
      appBar: _appBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: // Escáner
        return _buildScannerPage();
      case 1: // Emergencia
        return _buildEmergencyPage();
      case 2: // Inicio
        return _buildHomePage();
      case 3: // Incidente
        return _buildIncidentPage();
      case 4: // Comunidad
        return _buildCommunityPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Container(
      padding: EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        children: [
          /*_buildMenuButton(
            icon: Icons.person,
            title: 'Perfil',
            onTap: () {
              // TODO: Implementar navegación a perfil
            },
          ),
          _buildMenuButton(
            icon: Icons.search,
            title: 'Consultas',
            onTap: () {
              // TODO: Implementar navegación a consultas
            },
          ),
          _buildMenuButton(
            icon: Icons.document_scanner,
            title: 'Scanner',
            onTap: () {
              // TODO: Implementar funcionalidad de scanner
            },
          ),
          _buildMenuButton(
            icon: Icons.warning,
            title: 'Emergencia',
            onTap: () {
              // TODO: Implementar funcionalidad de emergencia
            },
          ),
          _buildMenuButton(
            icon: Icons.map,
            title: 'Incidente',
            onTap: () {
              // TODO: Implementar navegación a incidentes
            },
          ),
          _buildMenuButton(
            icon: Icons.groups,
            title: 'Comunidad',
            onTap: () {
              // TODO: Implementar navegación a comunidad
            },
          ),
          _buildMenuButton(
            icon: Icons.quiz,
            title: 'Quiz',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QuizPage()),
              );
            },
          ),*/
        ],
      ),
    );
  }

  Widget _buildScannerPage() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Header con tabs (sin el título principal)
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: const TabBar(
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              tabs: [Tab(text: 'Señales'), Tab(text: 'Multas')],
            ),
          ),

          // Contenido del tab
          Expanded(
            child: TabBarView(
              children: [
                _buildScannerContent('Escaneo de Señales'),
                _buildScannerContent('Escaneo de Multas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent(String title) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Título
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),

              // Imagen o mensaje
              if (_imageFile != null)
                Image.file(_imageFile!)
              else
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.image, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        'No hay imagen seleccionada',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Loading
              if (_isLoading) const CircularProgressIndicator(),

              // Resultado
              if (_descripcion != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _descripcion!,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),

              const SizedBox(height: 20),

              // Botones
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 150,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text(
                        'Cámara',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Galería',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScannerCorners() {
    return [
      // Esquina superior izquierda
      Positioned(top: 0, left: 0, child: _buildCorner(topLeft: true)),
      // Esquina superior derecha
      Positioned(top: 0, right: 0, child: _buildCorner(topRight: true)),
      // Esquina inferior izquierda
      Positioned(bottom: 0, left: 0, child: _buildCorner(bottomLeft: true)),
      // Esquina inferior derecha
      Positioned(bottom: 0, right: 0, child: _buildCorner(bottomRight: true)),
    ];
  }

  Widget _buildCorner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top:
              (topLeft || topRight)
                  ? const BorderSide(color: Colors.black, width: 4)
                  : BorderSide.none,
          left:
              (topLeft || bottomLeft)
                  ? const BorderSide(color: Colors.black, width: 4)
                  : BorderSide.none,
          right:
              (topRight || bottomRight)
                  ? const BorderSide(color: Colors.black, width: 4)
                  : BorderSide.none,
          bottom:
              (bottomLeft || bottomRight)
                  ? const BorderSide(color: Colors.black, width: 4)
                  : BorderSide.none,
        ),
      ),
    );
  }

  void _showScanResult(bool isMulta) {
    // Simular resultado aleatorio
    bool isValid = DateTime.now().millisecondsSinceEpoch % 2 == 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isMulta ? 'Escaneo de Multas' : 'Escaneo de Señales',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Icono de resultado
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isValid ? Colors.blue[400] : Colors.blue[400],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isValid ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 60,
                  ),
                ),

                const SizedBox(height: 40),

                // Botón de resultado
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isValid ? 'Válida' : 'Inválida',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                if (!isValid) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'TEXTO EXPLICATIVO PORQUE ES INVÁLIDA',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, size: 80, color: Colors.red),
          SizedBox(height: 20),
          Text(
            'Página de Emergencia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Sistema de emergencias en desarrollo',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 80, color: AppColors.primary),
          SizedBox(height: 20),
          Text(
            'Página de Incidentes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Mapa de incidentes en desarrollo',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón para crear publicación (sin header "Comunidad")
          Container(
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
                shadowColor: AppColors.primary.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.primary.withOpacity(0.15),
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
                      color: AppColors.primary.withOpacity(0.1),
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
                          color: AppColors.primary.withOpacity(0.7),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  Widget _buildPublicationCard(Map<String, dynamic> publication) {
    String? imageUrl = publication['ruta_media'];
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
                  child: Container(
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

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: AppColors.primary),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Escáner';
      case 1:
        return 'Emergencia';
      case 2:
        return 'Inicio';
      case 3:
        return 'Incidente';
      case 4:
        return 'Comunidad';
      default:
        return 'Inicio';
    }
  }

  AppBar _appBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () {},
        icon: Icon(Icons.menu),
        color: Colors.white,
        iconSize: 26,
      ),
      title: Text(
        _getAppBarTitle(),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1.3,
          fontSize: 26,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.more_vert, color: Colors.white, size: 26),
        ),
      ],
      //shape: RoundedRectangleBorder(
      //  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      //),
      backgroundColor: AppColors.primary,
      centerTitle: true,
    );
  }
}
