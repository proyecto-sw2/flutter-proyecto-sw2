import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';

AppBar appBar(String title, BuildContext context) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    iconTheme: IconThemeData(color: Colors.white),
    backgroundColor: AppColors.primary,
    centerTitle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
    ),
    toolbarHeight: 70,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(0.5),
      child: Container(color: Colors.grey.withAlpha(100), height: 1),
    ),
    // elevation: 1,
    actions: [
      IconButton(
        icon: const Icon(
          Icons.chat_bubble_outline,
          size: 24,
          color: Colors.white,
        ),
        onPressed: () {},
      ),
    ],
  );
}
