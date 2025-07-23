class ApiConfig {
  // static const String baseUrl = 'http://localhost:3000';
  static const String baseUrl = 'http://192.168.0.7:3000';
  // https://v9k5scrk-3000.brs.devtunnels.ms/
  //Para probar en un dispositivo movil:
  //static const String baseUrl = 'http://direccionIPv4deSuComputadora:3000';
  //ejemplo :'http://192.168.1.100:3000'
  // Para producción, cambiar a:
  // static const String baseUrl = 'https://tu-api-produccion.com';
  static const String baseIA = 'https://v9k5scrk-5000.brs.devtunnels.ms';
  static const String baseIAImg = 'https://v9k5scrk-8000.brs.devtunnels.ms';
  static const String apiPath = '/api/auth';

  static String get loginUrl => '$baseUrl$apiPath/login';
  static String get registerUrl => '$baseUrl$apiPath/register';
}
