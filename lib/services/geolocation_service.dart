import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GeolocationService {
  static const double _radioPermitido = 50.0; // 50 metros
  
  // Coordenadas de la parada de Estación Mollet - Sant Fost
  static const String _estacionParadaId = 'estacion_mollet';
  static const double _estacionLatitud = 41.533611;
  static const double _estacionLongitud = 2.217778;
  
  // Coordenadas de la parada de Hospital de Mollet
  static const String _hospitalParadaId = 'hospital_mollet';
  static const double _hospitalLatitud = 41.54362; // Corrected
  static const double _hospitalLongitud = 2.2018799999; // Corrected
  
  // Coordenadas de la parada de Avenida Libertad
  static const String _avenidaParadaId = 'avenida_libertad';
  static const double _avenidaLatitud = 41.536472;
  static const double _avenidaLongitud = 2.212167;

  // Variables para simulación
  Position? _simulatedPosition;
  bool _useSimulatedLocation = false;
  
  // Stream para notificar cambios de ubicación
  static final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  Stream<Position> get locationStream => _locationController.stream;
  
  // Control para evitar notificaciones excesivas
  Position? _lastNotifiedPosition;
  Timer? _debounceTimer;

  /// Activa el modo de simulación con una ubicación específica
  void setSimulatedLocation(double lat, double lng) {
    _simulatedPosition = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    _useSimulatedLocation = true;
    
    print('📍 Ubicación simulada establecida: $lat, $lng');
    print('📍 Modo simulación activo: $_useSimulatedLocation');
    
    // Notificar inmediatamente el cambio de ubicación
    _lastNotifiedPosition = null; // Reset para forzar notificación
    _notifyLocationChange(_simulatedPosition!);
  }

  /// Desactiva el modo de simulación
  void clearSimulatedLocation() {
    _simulatedPosition = null;
    _useSimulatedLocation = false;
    _lastNotifiedPosition = null;
    
    print('📍 Simulación desactivada - Usando ubicación real');
    print('📍 Modo simulación activo: $_useSimulatedLocation');
  }

  /// Verifica si está usando ubicación simulada
  bool get isUsingSimulatedLocation => _useSimulatedLocation;

  /// Notifica cambios de ubicación con debounce para evitar spam
  void _notifyLocationChange(Position position) {
    // Cancelar timer anterior si existe
    _debounceTimer?.cancel();
    
    // Verificar si la posición ha cambiado significativamente
    if (_lastNotifiedPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastNotifiedPosition!.latitude,
        _lastNotifiedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      // Solo notificar si la distancia es mayor a 1 metro
      if (distance < 1.0) {
        return;
      }
    }
    
    // Usar debounce para evitar notificaciones excesivas
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _lastNotifiedPosition = position;
      _locationController.add(position);
    });
  }

  /// Obtiene la ubicación actual (real o simulada)
  Future<Position?> getCurrentLocation() async {
    // Verificar primero si hay simulación activa
    if (_useSimulatedLocation && _simulatedPosition != null) {
      print('📍 Retornando ubicación SIMULADA: ${_simulatedPosition!.latitude}, ${_simulatedPosition!.longitude}');
      return _simulatedPosition;
    }
    
    print('📍 Retornando ubicación REAL');
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Solo notificar ubicación real si no hay simulación activa
      if (!_useSimulatedLocation) {
        _notifyLocationChange(position);
      }
      
      return position;
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      return null;
    }
  }

  /// Verifica permisos de ubicación
  Future<bool> checkLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        return permission == LocationPermission.whileInUse || 
               permission == LocationPermission.always;
      }

      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('Error verificando permisos: $e');
      return false;
    }
  }

  /// Calcula la distancia entre dos puntos
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Verifica si el usuario está cerca de la parada de Estación
  Future<bool> isNearEstacionParada() async {
    Position? currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      return false;
    }

    double distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      _estacionLatitud,
      _estacionLongitud,
    );

    return distance <= _radioPermitido;
  }

  /// Obtiene la distancia actual a la parada de Estación
  Future<double?> getDistanceToEstacionParada() async {
    Position? currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      return null;
    }

    return calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      _estacionLatitud,
      _estacionLongitud,
    );
  }

  /// Verifica si el usuario está cerca de la parada de Hospital
  Future<bool> isNearHospitalParada() async {
    Position? currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      return false;
    }

    double distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      _hospitalLatitud,
      _hospitalLongitud,
    );

    return distance <= _radioPermitido;
  }

  /// Obtiene la distancia actual a la parada de Hospital
  Future<double?> getDistanceToHospitalParada() async {
    Position? currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      return null;
    }

    return calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      _hospitalLatitud,
      _hospitalLongitud,
    );
  }

  /// Verifica si el usuario está cerca de la parada de Avenida Libertad
  Future<bool> isNearAvenidaParada() async {
    Position? currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      return false;
    }

    double distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      _avenidaLatitud,
      _avenidaLongitud,
    );

    return distance <= _radioPermitido;
  }

  /// Obtiene la distancia actual a la parada de Avenida Libertad
  Future<double?> getDistanceToAvenidaParada() async {
    Position? currentPosition = await getCurrentLocation();
    if (currentPosition == null) {
      return null;
    }

    return calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      _avenidaLatitud,
      _avenidaLongitud,
    );
  }

  /// Verifica si el usuario está cerca de una parada específica
  Future<bool> isNearParada(String paradaId) async {
    switch (paradaId) {
      case _estacionParadaId:
        return await isNearEstacionParada();
      case _hospitalParadaId:
        return await isNearHospitalParada();
      case _avenidaParadaId:
        return await isNearAvenidaParada();
      default:
        return true; // Para otras paradas no requiere verificación
    }
  }

  /// Obtiene la distancia a una parada específica
  Future<double?> getDistanceToParada(String paradaId) async {
    switch (paradaId) {
      case _estacionParadaId:
        return await getDistanceToEstacionParada();
      case _hospitalParadaId:
        return await getDistanceToHospitalParada();
      case _avenidaParadaId:
        return await getDistanceToAvenidaParada();
      default:
        return null;
    }
  }

  /// Verifica si una parada requiere verificación de ubicación
  bool requiresLocationVerification(String paradaId) {
    return paradaId == _estacionParadaId || 
           paradaId == _hospitalParadaId || 
           paradaId == _avenidaParadaId;
  }

  /// Inicia el monitoreo de distancia para una parada específica
  void startDistanceMonitoring(String paradaId) {
    // Implementación del monitoreo de distancia
    print('Iniciando monitoreo de distancia para: $paradaId');
  }

  /// Detiene el monitoreo de distancia
  void stopDistanceMonitoring() {
    // Implementación para detener el monitoreo
    print('Deteniendo monitoreo de distancia');
  }

  /// Limpia recursos
  void dispose() {
    _debounceTimer?.cancel();
    _locationController.close();
  }

  // Getters para acceder a las constantes
  double get radioPermitido => _radioPermitido;
  
  String get estacionParadaId => _estacionParadaId;
  Map<String, double> get estacionCoordinates => {
    'latitud': _estacionLatitud,
    'longitud': _estacionLongitud,
  };
  
  String get hospitalParadaId => _hospitalParadaId;
  Map<String, double> get hospitalCoordinates => {
    'latitud': _hospitalLatitud,
    'longitud': _hospitalLongitud,
  };
  
  String get avenidaParadaId => _avenidaParadaId;
  Map<String, double> get avenidaCoordinates => {
    'latitud': _avenidaLatitud,
    'longitud': _avenidaLongitud,
  };
} 