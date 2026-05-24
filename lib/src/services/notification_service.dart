import 'dart:convert';
import 'dart:developer' show log;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sw1/src/pages/incident_page.dart';
import 'package:flutter_sw1/src/services/incident_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationService(this.navigatorKey);
  initFCM() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await _firebaseMessaging.requestPermission();
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      prefs.setString('fcm_token', token);
    } else {
      print('Failed to get FCM token');
    }

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print(
        'Initial message: ${initialMessage.notification?.title} - ${initialMessage.notification?.body}',
      );
      navigatorKey.currentContext?.go('/prueba');
      // Aquí puedes manejar la notificación inicial si la aplicación se abrió desde una notificación
      // navigatorKey.currentState?.pushNamed(
      //   '/notification',
      //   arguments: initialMessage,
      // );
    }
    print('==== FCM Initialized ====');

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
        'Received message: ${message.notification?.title} - ${message.notification?.body}',
      );

      final context = navigatorKey.currentContext;

      if (context == null) return;

      final latitud = message.data['latitud'] ?? message.data['latitude'];
      final longitud = message.data['longitud'] ?? message.data['longitude'];
      
      if (latitud != null && longitud != null) {
        final LatLng latLng = stringToLatLng('$latitud,$longitud');
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => IncidentPage(initialTarget: latLng),
          ),
        );
      }

      print('==== App opened from notification ====');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
        'Foreground message: ${message.notification?.title} - ${message.notification?.body}',
      );
      
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final latitud = message.data['latitud'] ?? message.data['latitude'];
      final longitud = message.data['longitud'] ?? message.data['longitude'];
      final title = message.notification?.title ?? 'Nueva notificación';
      final body = message.notification?.body ?? 'Tienes una nueva actualización.';

      // Mostrar el diálogo
      final bool? ir = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: Text('$body\n¿Deseas ver los detalles?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cerrar'),
              ),
              if (latitud != null && longitud != null)
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Ver Mapa'),
                ),
            ],
          );
        },
      );

      if (ir == true && latitud != null && longitud != null) {
        final LatLng latLng = stringToLatLng('$latitud,$longitud');
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => IncidentPage(initialTarget: latLng),
          ),
        );
      }
    });

    // FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
    //   // print('Background message: ${message.notification?.title} - ${message.notification?.body}');
    //   // Aquí puedes manejar la notificación en segundo plano
    // });
  }

  // ===== NOTIFICACIONES DE EMERGENCIA =====

  Future<bool> sendEmergencyNotification({
    required String deviceToken,
    required String userName,
    required String alertType,
    required String location,
    String? videoUrl,
    String? description,
  }) async {
    if (deviceToken.isEmpty) return false;

    final credentials = await _getAccessToken();
    final accessToken = credentials.accessToken.data;
    final projectId = dotenv.env['PROJECT_ID'];

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    final message = {
      'message': {
        'token': deviceToken,
        'notification': {
          'title': '🚨 ALERTA DE EMERGENCIA',
          'body': '$userName ha activado el botón de pánico',
        },
        'data': {
          'type': 'emergency_alert',
          'alertType': alertType,
          'userName': userName,
          'location': location,
          'videoUrl': videoUrl ?? '',
          'description': description ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'emergency_sound',
            'channel_id': 'emergency_alerts',
            'priority': 'high',
            'default_sound': true,
            'default_vibrate_timings': true,
            'default_light_settings': true,
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'emergency_sound.wav',
              'badge': 1,
              'category': 'EMERGENCY_ALERT',
            },
          },
        },
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Emergency notification sent successfully.');
      return true;
    } else {
      print('Failed to send emergency notification: ${response.body}');
      return false;
    }
  }

  Future<AccessCredentials> _getAccessToken() async {
    final serviceAccountPath = dotenv.env['PATH_TO_SECRET'];

    String serviceAccountJson = await rootBundle.loadString(
      serviceAccountPath!,
    );

    // log("json: $serviceAccountJson");
    final serviceAccount = ServiceAccountCredentials.fromJson(
      serviceAccountJson,
    );

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    final client = await clientViaServiceAccount(serviceAccount, scopes);
    return client.credentials;
  }

  Future<bool> sendPushNotification({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (deviceToken.isEmpty) return false;

    final credentials = await _getAccessToken();
    final accessToken = credentials.accessToken.data;
    final projectId = dotenv.env['PROJECT_ID'];

    log("accessToken: $dotenv.env['PROJECT_ID']");

    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    final message = {
      'message': {
        'token': deviceToken,
        'notification': {'title': title, 'body': body},
        'data': data ?? {},
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully.');
      return true;
    } else {
      print('Failed to send notification: ${response.body}');
      return false;
    }
  }
}
