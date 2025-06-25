import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_sw1/firebase_options.dart';
import 'package:flutter_sw1/src/router/go_router.dart';
import 'package:flutter_sw1/src/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  final notificationService = NotificationService(navigatorKey);
  await notificationService.initFCM();
  FirebaseMessaging.onBackgroundMessage(handleBackGroundMessage);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Asistente Legal',
      locale: const Locale('es', 'ES'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routerConfig: createGoRouter(navigatorKey),
    );
  }
}

Future<void> handleBackGroundMessage(RemoteMessage message) async {
  // Aquí puedes manejar la notificación en segundo plano
  print(
    'Background message: ${message.notification?.title} - ${message.notification?.body}',
  );
  // Por ejemplo, podrías mostrar una notificación local o actualizar el estado de la aplicación
}
