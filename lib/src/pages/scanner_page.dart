import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header con tabs
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(
                      'Escaner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 2,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Señales'),
                      Tab(text: 'Multas'),
                    ],
                  ),
                ],
              ),
            ),
            
            // Contenido del tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildScannerContent('Escaneo de Señales'),
                  _buildScannerContent('Escaneo de Multas'),
                ],
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScannerContent(String title) {
    return Expanded(
      child: Padding(
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
      ),
    );
  }
  
  List<Widget> _buildScannerCorners() {
    return [
      // Esquina superior izquierda
      Positioned(
        top: 0,
        left: 0,
        child: _buildCorner(
          topLeft: true,
        ),
      ),
      // Esquina superior derecha
      Positioned(
        top: 0,
        right: 0,
        child: _buildCorner(
          topRight: true,
        ),
      ),
      // Esquina inferior izquierda
      Positioned(
        bottom: 0,
        left: 0,
        child: _buildCorner(
          bottomLeft: true,
        ),
      ),
      // Esquina inferior derecha
      Positioned(
        bottom: 0,
        right: 0,
        child: _buildCorner(
          bottomRight: true,
        ),
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
  
  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Inicio', () => context.go('/home')),
          _buildNavItem(Icons.fullscreen, 'Escáner', () {}),
          _buildNavItem(Icons.error, 'Emergencia', () {}),
          _buildNavItem(Icons.map, 'Incidente', () {}),
          _buildNavItem(Icons.groups, 'Comunidad', () {}),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
} 