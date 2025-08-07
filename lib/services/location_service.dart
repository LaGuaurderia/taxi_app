import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../models/parada.dart';
import '../models/taxi_en_cola.dart';
import '../screens/pantalla_seleccion_parada.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStream;
  static Timer? _proximityCheckTimer;
  static Set<String> _notifiedParadas = {};
  static bool _isMonitoring = false;

  // Configuración para el monitoreo de ubicación
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Actualizar cada 10 metros
  );

  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<void> startProximityMonitoring() async {
    if (_isMonitoring) return;

    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      print('No se tienen permisos de ubicación');
      return;
    }

    // Inicializar el servicio de notificaciones
    await NotificationService.initialize();
    await NotificationService.requestPermissions();

    _isMonitoring = true;
    _notifiedParadas.clear();

    print('🚀 Iniciando monitoreo de proximidad...');

    // Iniciar el stream de ubicación
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      _onPositionChanged,
      onError: (error) {
        print('Error en el stream de ubicación: $error');
      },
    );

    // También hacer una verificación inicial
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print('📍 Ubicación inicial obtenida: ${currentPosition.latitude}, ${currentPosition.longitude}');
      await _checkProximity(currentPosition);
    } catch (e) {
      print('Error obteniendo ubicación inicial: $e');
    }
  }

  static Future<void> stopProximityMonitoring() async {
    _isMonitoring = false;
    _notifiedParadas.clear();
    
    await _positionStream?.cancel();
    _positionStream = null;
    
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = null;
  }

  static Future<void> _onPositionChanged(Position position) async {
    // Usar un timer para evitar demasiadas verificaciones
    _proximityCheckTimer?.cancel();
    _proximityCheckTimer = Timer(const Duration(seconds: 5), () async {
      await _checkProximity(position);
    });
  }

  static Future<void> _checkProximity(Position position) async {
    try {
      print('🔍 Verificando proximidad para: ${position.latitude}, ${position.longitude}');
      
      final nearbyParada = await NotificationService.checkProximity(position);
      
      if (nearbyParada != null) {
        print('🎯 Cerca de parada: ${nearbyParada.nombre}');
        
        // Si no hemos notificado sobre esta parada recientemente
        if (!_notifiedParadas.contains(nearbyParada.id)) {
          print('📱 Enviando notificación para: ${nearbyParada.nombre}');
          await NotificationService.showProximityNotification(nearbyParada);
          _notifiedParadas.add(nearbyParada.id);
          
          // Remover de la lista después de 5 minutos para permitir notificaciones futuras
          Timer(const Duration(minutes: 5), () {
            _notifiedParadas.remove(nearbyParada.id);
            print('⏰ Notificación expirada para: ${nearbyParada.nombre}');
          });
        } else {
          print('⚠️ Ya se notificó recientemente sobre: ${nearbyParada.nombre}');
        }
      } else {
        print('📍 No cerca de ninguna parada');
        // Si no estamos cerca de ninguna parada, limpiar notificaciones
        for (final parada in NotificationService.paradas) {
          await NotificationService.cancelNotification(parada.id);
        }
      }
    } catch (e) {
      print('Error verificando proximidad: $e');
    }
  }

  // Método para verificar proximidad y mostrar alerta si es necesario
  static Future<void> checkProximityAndShowAlert(BuildContext context, Position position) async {
    try {
      print('🔍 Verificando proximidad para alerta: ${position.latitude}, ${position.longitude}');
      
      final nearbyParada = await NotificationService.checkProximity(position);
      
      if (nearbyParada != null) {
        print('🎯 Mostrando alerta para: ${nearbyParada.nombre}');
        
        // Si no hemos mostrado alerta sobre esta parada recientemente
        if (!_notifiedParadas.contains(nearbyParada.id)) {
          showProximityAlert(context, nearbyParada);
          _notifiedParadas.add(nearbyParada.id);
          
          // Remover de la lista después de 5 minutos para permitir alertas futuras
          Timer(const Duration(minutes: 5), () {
            _notifiedParadas.remove(nearbyParada.id);
            print('⏰ Alerta expirada para: ${nearbyParada.nombre}');
          });
        } else {
          print('⚠️ Ya se mostró alerta recientemente sobre: ${nearbyParada.nombre}');
        }
      }
    } catch (e) {
      print('Error verificando proximidad para alerta: $e');
    }
  }

  // Método para mostrar alerta de proximidad
  static void showProximityAlert(BuildContext context, Parada parada) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estás cerca de ${parada.nombre}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Quieres apuntarte a la tanda de esta parada?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Estás a menos de 100 metros de la parada',
                        style: const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Has rechazado apuntarte a la tanda'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Rechazar',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Apuntarse automáticamente a la parada
                await _apuntarseAutomaticamente(context, parada);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apuntarse'),
            ),
          ],
        );
      },
    );
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error obteniendo ubicación actual: $e');
      return null;
    }
  }

  static Future<double> getDistanceToParada(Position currentPosition, Parada parada) async {
    return NotificationService.getDistanceToParada(currentPosition, parada);
  }

  static List<Parada> get paradas => NotificationService.paradas;

  static bool get isMonitoring => _isMonitoring;

  // Método para apuntarse automáticamente a una parada
  static Future<void> _apuntarseAutomaticamente(BuildContext context, Parada parada) async {
    try {
      // Obtener datos del taxista desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final codigoTaxi = prefs.getString('codigoTaxi') ?? 'TAXI001';
      final nombreTaxista = prefs.getString('nombreTaxista') ?? 'Taxista';
      final telefono = prefs.getString('telefono') ?? '+34 621 03 35 28';

      // Crear el taxi en cola
      final taxiEnCola = TaxiEnCola(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        codigoTaxi: codigoTaxi,
        timestamp: DateTime.now(),
      );

      // Obtener la cola actual de la parada
      final colaKey = 'cola_${parada.id}';
      final colaJson = prefs.getString(colaKey);
      List<Map<String, dynamic>> colaActual = [];
      
      if (colaJson != null) {
        colaActual = List<Map<String, dynamic>>.from(
          jsonDecode(colaJson).map((x) => Map<String, dynamic>.from(x))
        );
      }

      // Verificar si ya está en la cola
      final yaEnCola = colaActual.any((taxi) => taxi['codigoTaxi'] == codigoTaxi);
      
      if (yaEnCola) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ya estás apuntado en esta tanda'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Añadir el taxi a la cola
      colaActual.add(taxiEnCola.toMap());
      
      // Guardar la cola actualizada
      await prefs.setString(colaKey, jsonEncode(colaActual));

      print('✅ Taxista apuntado automáticamente a ${parada.nombre}');

      if (context.mounted) {
        // Mostrar mensaje de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Te has apuntado a la tanda de ${parada.nombre}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () async {
                // Navegar a la pantalla de selección de parada con la parada preseleccionada
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => PantallaSeleccionParada(
                      paradaSeleccionadaId: parada.id,
                    ),
                  ),
                  (route) => false, // Eliminar todas las rutas anteriores
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error apuntándose automáticamente: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al apuntarse a la tanda'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
} 