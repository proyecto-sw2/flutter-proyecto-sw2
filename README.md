# 🚗 Asistente Legal - Flutter App

Una aplicación móvil desarrollada en Flutter que proporciona asistencia legal y gestión de incidentes de tránsito en tiempo real.

## 📱 Características Principales

- 🗺️ **Mapas interactivos** con Google Maps
- 📍 **Reporte de incidentes** en tiempo real
- 🔔 **Notificaciones push** para alertas de incidentes
- 💬 **Chat con IA** para asistencia legal
- 👥 **Comunidad** para compartir experiencias
- 🔐 **Autenticación biométrica** y por credenciales
- 🎯 **Quiz educativo** sobre leyes de tránsito
- 📷 **Escáner de documentos** con cámara

## 🚀 Instalación y Ejecución

### Prerrequisitos
- Flutter SDK (versión estable)
- Android Studio / VS Code
- Dispositivo Android o emulador
- Cuenta de Firebase configurada

### Pasos para ejecutar:
```bash
1. flutter pub get
2. flutter run
```

## 🔔 Sistema de Notificaciones Push

### 📋 Descripción General

La aplicación utiliza **Firebase Cloud Messaging (FCM)** para manejar notificaciones push en tiempo real. El sistema permite a los usuarios recibir alertas cuando se reportan nuevos incidentes de tránsito en su área.

## 🚨 Módulo de Emergencia

### 📋 Descripción General

El módulo de emergencia proporciona funcionalidades de seguridad avanzadas, incluyendo gestión de contactos de emergencia y sistema de alertas de pánico con notificaciones en tiempo real.

### 🏗️ Arquitectura del Sistema

```
lib/
├── main.dart                           # Inicialización de FCM
├── src/models/
│   ├── emergency_alert.dart            # Modelo de alertas de emergencia
│   └── emergency_contact.dart          # Modelo de contactos de emergencia
├── src/services/
│   ├── notification_service.dart       # Servicio principal de notificaciones
│   ├── emergency_service.dart          # Servicio de emergencia
│   ├── incident_service.dart           # Creación de incidentes + envío de notificaciones
│   └── user_service.dart               # Actualización de tokens de dispositivo
├── src/pages/
│   ├── emergency_page.dart             # Página principal de emergencia
│   ├── emergency_contacts_page.dart    # Gestión de contactos
│   └── panic_button_page.dart          # Botón de pánico con grabación
└── firebase_options.dart               # Configuración de Firebase
```

### 🔄 Flujo de Emergencia

#### 1. **Activación del Botón de Pánico:**
- Usuario presiona botón de emergencia
- App solicita confirmación
- Inicia grabación de video (máx 5 min)
- Obtiene ubicación GPS automáticamente
- Envía alerta al backend

#### 2. **Notificaciones a Contactos:**
- **WebSocket**: Para contactos conectados en tiempo real ✅
- **Push Notifications**: Para contactos con app instalada ✅
- **SMS**: Para contactos con número de teléfono (futuro)
- **Email**: Para contactos con email (futuro)

#### 3. **Gestión de Contactos:**
- Máximo 5 contactos por usuario
- Sistema de prioridades (1-5)
- Información completa (nombre, teléfono, email, relación)
- Tokens FCM para notificaciones push

### 📤 Envío de Notificaciones de Emergencia

#### **Cuándo se Envían:**
- Cuando un usuario activa el botón de pánico
- Se notifica a todos los contactos de emergencia configurados

#### **Datos Incluidos:**
```dart
{
  "title": "🚨 ALERTA DE EMERGENCIA",
  "body": "Usuario ha activado el botón de pánico",
  "data": {
    "type": "emergency_alert",
    "alertId": "123",
    "userId": "1",
    "userName": "Juan Pérez",
    "videoUrl": "https://s3.amazonaws.com/...",
    "location": "Madrid, España",
    "latitude": "40.4168",
    "longitude": "-3.7038",
    "duration": "300"
  }
}
```

### 🎯 Características del Sistema de Emergencia

✅ **Botón de pánico** con confirmación de seguridad  
✅ **Grabación de video** automática (máx 5 min)  
✅ **Geolocalización** en tiempo real  
✅ **Gestión de contactos** completa  
✅ **Notificaciones push** de alta prioridad  
✅ **WebSocket** para tiempo real  
✅ **Integración** con sistema existente  
✅ **Interfaz intuitiva** con colores de emergencia  

### 🏗️ Arquitectura del Sistema

```
lib/
├── main.dart                           # Inicialización de FCM
├── src/services/
│   ├── notification_service.dart       # Servicio principal de notificaciones
│   ├── incident_service.dart           # Creación de incidentes + envío de notificaciones
│   └── user_service.dart               # Actualización de tokens de dispositivo
└── firebase_options.dart               # Configuración de Firebase
```

### 🔄 Flujo de Notificaciones

#### 1. **Inicialización del Sistema**
```dart
// En main.dart
final notificationService = NotificationService(navigatorKey);
await notificationService.initFCM();
FirebaseMessaging.onBackgroundMessage(handleBackGroundMessage);
```

#### 2. **Estados de la Aplicación**

**🔴 App Cerrada → Se Abre con Notificación:**
- La app se abre automáticamente cuando se toca una notificación
- Navega directamente a la página del incidente reportado

**🟡 App en Segundo Plano → Se Abre con Notificación:**
- Al tocar la notificación, la app se trae al primer plano
- Navega automáticamente a la ubicación del incidente en el mapa

**🟢 App Abierta (Foreground):**
- Muestra un diálogo interactivo preguntando si desea ver el incidente
- Opciones: "Cancelar" o "Ir" al incidente

### 📤 Envío de Notificaciones

#### **Cuándo se Envían:**
- Cuando un usuario reporta un nuevo incidente de tránsito
- Se notifica a todos los usuarios registrados (excepto al que reportó)

#### **Datos Incluidos:**
```dart
{
  "title": "Tipo de incidente (ej: ACCIDENTE)",
  "body": "Descripción del incidente",
  "data": {
    "latitud": "12.345678",
    "longitud": "-98.765432"
  }
}
```

### 🔧 Configuración Técnica

#### **Firebase Setup:**
```dart
// firebase_options.dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDGYQ2ALqy36V21XewLal6XSynT7xDSkoY',
  appId: '1:570490622645:android:aec3333007629da67164fc',
  messagingSenderId: '570490622645',
  projectId: 'proyecto-sw1-c8ae5',
  storageBucket: 'proyecto-sw1-c8ae5.firebasestorage.app',
);
```

#### **Variables de Entorno (.env):**
```env
PROJECT_ID=proyecto-sw1-c8ae5
PATH_TO_SECRET=assets/secret.json
```

### 📱 Gestión de Tokens de Dispositivo

#### **Obtención del Token:**
- Se solicita al usuario permiso para notificaciones
- Se genera un token único de FCM para el dispositivo
- Se almacena localmente en SharedPreferences

#### **Sincronización con Servidor:**
- El token se envía automáticamente al servidor al iniciar sesión
- Se actualiza cuando el usuario abre la aplicación
- Permite enviar notificaciones específicas a cada dispositivo

### 🎯 Características del Sistema

✅ **Notificaciones en tiempo real** cuando se crean incidentes  
✅ **Navegación automática** a la ubicación del incidente  
✅ **Diálogos interactivos** cuando la app está abierta  
✅ **Manejo de diferentes estados** de la aplicación  
✅ **Autenticación segura** con Google APIs  
✅ **Persistencia de tokens** en SharedPreferences  
✅ **Sincronización con servidor** de tokens de dispositivo  

### 🔍 Funcionalidades Implementadas

#### **NotificationService (notification_service.dart):**
- Inicialización de Firebase Messaging
- Manejo de permisos de notificación
- Gestión de tokens de dispositivo
- Envío de notificaciones push
- Navegación automática a incidentes

#### **Manejo de Estados:**
- **Foreground**: Diálogo interactivo
- **Background**: Navegación directa al incidente
- **Terminated**: Apertura de app y navegación

#### **Autenticación:**
- Uso de Google Service Account
- Tokens de acceso para FCM API
- Seguridad en el envío de notificaciones

### 🛠️ Dependencias Utilizadas

```yaml
dependencies:
  firebase_messaging: ^15.2.7
  firebase_core: ^3.14.0
  googleapis_auth: ^2.0.0
  shared_preferences: ^2.2.2
  flutter_dotenv: ^5.2.1
```

### 📊 Logs y Debugging

El sistema incluye logs detallados para debugging:
```dart
print('FCM Token: $token');
print('==== FCM Initialized ====');
print('Foreground message: ${message.notification?.title}');
print('Notification sent successfully.');
```

### 🔮 Posibles Mejoras Futuras

1. **Notificaciones locales** para app en segundo plano
2. **Badge count** para mostrar notificaciones no leídas
3. **Categorías de notificación** por tipo de incidente
4. **Configuración de notificaciones** por usuario
5. **Notificaciones programadas** para recordatorios
6. **Análisis de engagement** de notificaciones

## 🛠️ Tecnologías Utilizadas

- **Frontend**: Flutter/Dart
- **Backend**: API REST
- **Notificaciones**: Firebase Cloud Messaging
- **Mapas**: Google Maps Flutter
- **Autenticación**: Firebase Auth + Biometría
- **Estado**: Riverpod
- **Navegación**: Go Router

## 📄 Licencia

Este proyecto es parte del curso de desarrollo móvil.

---

**Desarrollado con ❤️ usando Flutter**