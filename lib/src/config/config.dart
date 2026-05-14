class ApiConfig {
  // TU ÚNICA URL DE NGROK (Cámbiala cada vez que inicies ngrok)
  static const String ngrokUrl = 'https://nasir-unsaveable-marcela.ngrok-free.dev';

  // Redirigimos por prefijos definidos en el proxy.js
  static const String baseUrl = '$ngrokUrl/api';    // Apunta al 3000
  static const String baseIA = '$ngrokUrl/ia';      // Apunta al 5000
  static const String baseIAImg = '$ngrokUrl/img';  // Apunta al 8000

  static const String apiPath = '/auth'; // Quitamos /api porque ya está en baseUrl

  static String get loginUrl => '$baseUrl$apiPath/login';
  static String get registerUrl => '$baseUrl$apiPath/register';
}