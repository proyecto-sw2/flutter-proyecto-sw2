import 'package:flutter/material.dart';
import 'package:flutter_sw1/src/services/message_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          final userId = prefs.getInt('user_id') ?? 0;

          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('¿Eliminar mensajes?'),
                content: const Text(
                  '¿Estás seguro de que deseas eliminar todos los mensajes del chat?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Eliminar'),
                  ),
                ],
              );
            },
          );

          if (confirm == true) {
            await eliminarMensajesDelChat(userId);
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Mensajes eliminados'),
                  content: const Text(
                    'Todos los mensajes del chat han sido eliminados.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Aceptar'),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    ],
  );
}
