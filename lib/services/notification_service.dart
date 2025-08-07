import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import '../models/parada.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  // Lista de paradas con coordenadas exactas de Mollet del Vallès
  static const List<Parada> _paradas = [
    Parada(
      id: 'hospital_mollet',
      nombre: 'Hospital de Mollet',
      ubicacion: 'Carrer de l\'Hospital, Mollet del Vallès',
      latitud: 41.548428, // Coordenadas exactas del Hospital de Mollet
      longitud: 2.212755,
      radioMetros: 100.0,
    ),
    Parada(
      id: 'avenida_libertad',
      nombre: 'Avenida Libertad',
      ubicacion: 'Avinguda de la Llibertat, Mollet del Vallès',
      latitud: 41.540560, // Coordenadas exactas de Avenida Libertad
      longitud: 2.213940,
      radioMetros: 100.0,
    ),
    Parada(
      id: 'estacion_mollet',
      nombre: 'Estación Mollet-San Fost',
      ubicacion: 'Estació de Mollet-Sant Fost, Mollet del Vallès',
      latitud: 41.545012, // Coordenadas exactas de la estación
      longitud: 2.208414,
      radioMetros: 100.0,
    ),
  ];

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Aquí se manejará la navegación cuando se toque la notificación
    // Se implementará en el main.dart
    print('Notificación tocada: ${response.payload}');
  }

  static void setNotificationCallback(Function(NotificationResponse) callback) {
    _notifications.initialize(
      const InitializationSettings(),
      onDidReceiveNotificationResponse: callback,
    );
  }

  static Future<void> requestPermissions() async {
    // Para Android, los permisos se solicitan automáticamente
    // Para iOS, se solicitan explícitamente
    await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> showProximityNotification(Parada parada) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'proximity_channel',
      'Proximidad a Paradas',
      channelDescription: 'Notificaciones cuando estás cerca de una parada',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      _getNotificationId(parada.id),
      'Estás cerca de la parada ${parada.nombre}',
      '¿Quieres apuntarte a la tanda?',
      platformChannelSpecifics,
      payload: parada.id,
    );
  }

  static int _getNotificationId(String paradaId) {
    // Generar un ID único para cada parada
    return paradaId.hashCode;
  }

  static Future<void> cancelNotification(String paradaId) async {
    await _notifications.cancel(_getNotificationId(paradaId));
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static List<Parada> get paradas => _paradas;

  static Future<Parada?> checkProximity(Position currentPosition) async {
    for (final parada in _paradas) {
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        parada.latitud,
        parada.longitud,
      );

      if (distance <= parada.radioMetros) {
        return parada;
      }
    }
    return null;
  }

  static Future<double> getDistanceToParada(Position currentPosition, Parada parada) async {
    return Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      parada.latitud,
      parada.longitud,
    );
  }
} 