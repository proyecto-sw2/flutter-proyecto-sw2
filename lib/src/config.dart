class ApiConfig {
  
  static const String baseUrl = 'http://localhost:3000';
  
  //Para probar en un dispositivo movil:
  //static const String baseUrl = 'http://direccionIPv4deSuComputadora:3000';
  //ejemplo :'http://192.168.1.100:3000'
  // Para producción, cambiar a:
  // static const String baseUrl = 'https://tu-api-produccion.com';
  
  static const String apiPath = '/api/auth';
  
  static String get loginUrl => '$baseUrl$apiPath/login';
  static String get registerUrl => '$baseUrl$apiPath/register';
}