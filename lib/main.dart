import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/router/go_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Asistente Legal',
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
    );
  }
}
