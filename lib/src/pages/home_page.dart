import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sw1/main.dart';
import 'package:flutter_sw1/src/pages/chat_page.dart';
import 'package:flutter_sw1/src/pages/community_page.dart';
import 'package:flutter_sw1/src/pages/emergency_page.dart';
import 'package:flutter_sw1/src/pages/incident_page.dart';
import 'package:flutter_sw1/src/pages/profile_page.dart';
import 'package:flutter_sw1/src/pages/prueba_page.dart';
import 'package:flutter_sw1/src/pages/quiz_page.dart';
import 'package:flutter_sw1/src/pages/scanner_page.dart';
import 'package:flutter_sw1/src/services/notification_service.dart';
import 'package:flutter_sw1/src/services/user_service.dart';
//import 'package:flutter_sw1/src/pages/scanner_page.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _updateUser();
  }

  Future<void> _updateUser() async {
    _prefs = await SharedPreferences.getInstance();
    final deviceToken = _prefs?.getString('fcm_token') ?? '';
    final userId = _prefs?.getInt('user_id') ?? 0;
    final userName = _prefs?.getString('user_name') ?? '';
    if (deviceToken.isNotEmpty && userId != 0) {
      await updateDispositivo(deviceToken, userId);
      print('Dispositivo actualizado: $deviceToken para el usuario $userName');
    } else {
      print('No se pudo actualizar el dispositivo: datos incompletos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Inicio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Container(),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey.shade100,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionCard(
                      icon: Icons.person,
                      title: 'Perfil',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(),
                          ),
                        );
                      },
                    ).backInLeft(duration: const Duration(milliseconds: 500)),
                    _buildOptionCard(
                      icon: Icons.search,
                      title: 'Consultas',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatPage(),
                          ),
                        );
                      },
                    ).backInRight(duration: const Duration(milliseconds: 500)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionCard(
                      icon: Icons.qr_code_scanner,
                      title: 'Scanner',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScannerPage(),
                          ),
                        );
                      },
                    ).backInLeft(duration: const Duration(milliseconds: 600)),
                    _buildOptionCard(
                      icon: Icons.emergency,
                      title: 'Emergencia',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EmergencyPage(),
                          ),
                        );
                      },
                    ).backInRight(duration: const Duration(milliseconds: 600)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionCard(
                      icon: Icons.report,
                      title: 'Incidente',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Pruebaa()),
                        );
                      },
                    ).backInLeft(duration: const Duration(milliseconds: 700)),
                    _buildOptionCard(
                      icon: Icons.groups,
                      title: 'Comunidad',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommunityPage(),
                          ),
                        );
                      },
                    ).backInRight(duration: const Duration(milliseconds: 700)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildQuizCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.40,
          height: MediaQuery.of(context).size.width * 0.40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => QuizPage()),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 25),
        height: MediaQuery.of(context).size.width * 0.40,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.quiz, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            const Text(
              'Quiz',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ).backInUp(duration: const Duration(milliseconds: 800)),
    );
  }
}
