import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      appBar: _appBar(),
    );
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
        'Inicio',
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
