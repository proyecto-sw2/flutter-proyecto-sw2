import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'quiz_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Índice inicial en "Inicio"

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
        initialActiveIndex: 2,
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
          _buildMenuButton(
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
          ),
        ],
      ),
    );
  }

  Widget _buildScannerPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner,
            size: 80,
            color: AppColors.primary,
          ),
          SizedBox(height: 20),
          Text(
            'Página de Escáner',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Funcionalidad de escáner en desarrollo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      backgroundColor: AppColors.primary,
      centerTitle: true,
    );
  }
}
