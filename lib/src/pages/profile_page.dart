import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                'Perfil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar y nombre
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'NOMBRE DE',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              letterSpacing: 1,
                            ),
                          ),
                          const Text(
                            'LA PERSONA',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Lista de datos
                    _buildDataItem('Dato 1'),
                    const SizedBox(height: 16),
                    _buildDataItem('Dato 1'),
                    const SizedBox(height: 16),
                    _buildDataItem('Dato 1'),
                    
                    const SizedBox(height: 40),
                    
                    // Botón de regreso
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 100), // Espacio para navegación
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation
            Container(
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
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataItem(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
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