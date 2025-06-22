import 'package:flutter/material.dart';
import 'package:flutter_animated_splash/flutter_animated_splash.dart';
import 'package:flutter_sw1/src/pages/home_page.dart';
//import 'package:flutter_sw1/src/pages/home1_page.dart';
import 'package:flutter_sw1/src/pages/login_page.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  SharedPreferences? _prefs;
  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final token = _prefs?.getString('auth_token') ?? '';
    if (token.isNotEmpty) {
      // Si hay un token, redirigir a la página de inicio
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      });
    } else {
      // Si no hay token, permanecer en la pantalla de splash
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplash(
      type: Transition.scale,
      backgroundColor: AppColors.primary,
      navigator: const LoginPage(),
      durationInSeconds: 2,
      child: Positioned(
        top: 0,
        left: 0,
        right: 10,
        bottom: 10,
        child: Center(child: Image.asset('assets/logo.png', width: 250)),
      ),
    );
  }
}
