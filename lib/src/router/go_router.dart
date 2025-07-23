import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/pages/home_page.dart';
import 'package:flutter_sw1/src/pages/splash_page.dart';
import 'package:flutter_sw1/src/pages/emergency_page.dart';
import 'package:flutter_sw1/src/pages/emergency_contacts_page.dart';
import 'package:flutter_sw1/src/pages/panic_button_page.dart';
import 'package:go_router/go_router.dart';

GoRouter createGoRouter(GlobalKey<NavigatorState> navigatorKey) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    errorBuilder: (_, __) => const Scaffold(body: Center(child: Text('Error'))),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/home1', builder: (context, state) => const HomePage()),
      GoRoute(path: '/emergency', builder: (context, state) => const EmergencyPage()),
      GoRoute(path: '/emergency/contacts', builder: (context, state) => const EmergencyContactsPage()),
      GoRoute(path: '/emergency/panic-button', builder: (context, state) => const PanicButtonPage()),
    ],
  );
}
