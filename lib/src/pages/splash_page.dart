import 'package:flutter/material.dart';
import 'package:flutter_animated_splash/flutter_animated_splash.dart';
//import 'package:flutter_sw1/src/pages/home1_page.dart';
import 'package:flutter_sw1/src/pages/login_page.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

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
