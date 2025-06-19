import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'quiz_page.dart';

class HomePage extends StatefulWidget {
  final int? initialIndex;
  const HomePage({super.key, this.initialIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 2; // Usar el índice pasado o 2 por defecto
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
              labelStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: 'Señales'),
                Tab(text: 'Multas'),
              ],
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
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
          
          const Spacer(),
          
          // Marco de escaneo
          Container(
            width: 200,
            height: 200,
            child: Stack(
              children: [
                // Esquinas del marco
                ..._buildScannerCorners(),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Botón Escanear
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showScanResult(title.contains('Multas')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Escanear',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildScannerCorners() {
    return [
      // Esquina superior izquierda
      Positioned(
        top: 0,
        left: 0,
        child: _buildCorner(topLeft: true),
      ),
      // Esquina superior derecha
      Positioned(
        top: 0,
        right: 0,
        child: _buildCorner(topRight: true),
      ),
      // Esquina inferior izquierda
      Positioned(
        bottom: 0,
        left: 0,
        child: _buildCorner(bottomLeft: true),
      ),
      // Esquina inferior derecha
      Positioned(
        bottom: 0,
        right: 0,
        child: _buildCorner(bottomRight: true),
      ),
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
          top: (topLeft || topRight) ? const BorderSide(color: Colors.black, width: 4) : BorderSide.none,
          left: (topLeft || bottomLeft) ? const BorderSide(color: Colors.black, width: 4) : BorderSide.none,
          right: (topRight || bottomRight) ? const BorderSide(color: Colors.black, width: 4) : BorderSide.none,
          bottom: (bottomLeft || bottomRight) ? const BorderSide(color: Colors.black, width: 4) : BorderSide.none,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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
          Icon(
            Icons.warning,
            size: 80,
            color: Colors.red,
          ),
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
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
          Icon(
            Icons.map,
            size: 80,
            color: AppColors.primary,
          ),
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups,
            size: 80,
            color: AppColors.primary,
          ),
          SizedBox(height: 20),
          Text(
            'Página de Comunidad',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Funciones de comunidad en desarrollo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
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
            Icon(
              icon,
              size: 30,
              color: AppColors.primary,
            ),
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
