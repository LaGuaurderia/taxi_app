import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/preferences_service.dart';
import '../services/firestore_service.dart';
import '../services/geolocation_service.dart';
import '../models/cola_taxis.dart';
import '../models/taxi_en_cola.dart';
import '../models/solicitud_cambio.dart';
import 'pantalla_administracion.dart';
import 'pantalla_mapa_simple.dart';

class PantallaSeleccionParada extends StatefulWidget {
  final String? paradaSeleccionadaId;
  
  const PantallaSeleccionParada({
    super.key,
    this.paradaSeleccionadaId,
  });

  @override
  State<PantallaSeleccionParada> createState() => _PantallaSeleccionParadaState();
}

class _PantallaSeleccionParadaState extends State<PantallaSeleccionParada> {
  String? _codigoTaxi;
  String? _telefono;
  ColaTaxis? _paradaSeleccionada;
  bool _estaCargando = false;
  List<SolicitudCambio> _solicitudesPendientes = [];
  List<SolicitudCambio> _misSolicitudes = [];
  final FirestoreService _firestoreService = FirestoreService();
  final GeolocationService _geolocationService = GeolocationService();
  
  // Variables para geolocalización
  bool _locationPermissionGranted = false;
  double? _currentDistanceToEstacion;
  bool _isNearEstacion = false;
  double? _currentDistanceToHospital;
  bool _isNearHospital = false;
  double? _currentDistanceToAvenida;
  bool _isNearAvenida = false;

  // Lista de paradas disponibles
  final List<ColaTaxis> _paradas = [
    ColaTaxis(
      id: 'hospital_mollet',
      nombre: 'Hospital de Mollet',
      ubicacion: 'Carrer de l\'Hospital, Mollet del Vallès',
      taxisEnCola: [
        TaxiEnCola(
          id: '1',
          codigoTaxi: 'M01',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        TaxiEnCola(
          id: '2',
          codigoTaxi: 'M05',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        ),
        TaxiEnCola(
          id: '3',
          codigoTaxi: 'M07',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ],
    ),
    ColaTaxis(
      id: 'avenida_libertad',
      nombre: 'Avenida Libertad',
      ubicacion: 'Avinguda de la Llibertat, Mollet del Vallès',
      taxisEnCola: [
        TaxiEnCola(
          id: '4',
          codigoTaxi: 'M02',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        ),
        TaxiEnCola(
          id: '5',
          codigoTaxi: 'M06',
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        ),
      ],
    ),
    ColaTaxis(
      id: 'estacion_mollet',
      nombre: 'Estación Mollet-San Fost',
      ubicacion: 'Estació de Mollet-Sant Fost, Mollet del Vallès',
      taxisEnCola: [
        TaxiEnCola(
          id: '6',
          codigoTaxi: 'M04',
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        TaxiEnCola(
          id: '7',
          codigoTaxi: 'M08',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        TaxiEnCola(
          id: '8',
          codigoTaxi: 'M10',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ],
    ),
  ];

  StreamSubscription<Position>? _locationSubscription;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _initializeLocationServices();
    
    // Suscribirse a cambios de ubicación con throttling
    _locationSubscription = _geolocationService.locationStream.listen((position) {
      if (mounted) {
        print('📍 Nueva ubicación recibida: ${position.latitude}, ${position.longitude}');
        print('📍 Modo simulación: ${_geolocationService.isUsingSimulatedLocation}');
        
        // Usar throttling para evitar actualizaciones excesivas
        _updateTimer?.cancel();
        _updateTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            // Usar directamente la posición recibida del stream
            _updateLocationDataWithPosition(position);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _updateTimer?.cancel();
    _geolocationService.stopDistanceMonitoring();
    super.dispose();
  }

  Future<void> _cargarSolicitudes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar solicitudes pendientes para este taxi
      final solicitudesKey = 'solicitudes_${_codigoTaxi}';
      final solicitudesJson = prefs.getString(solicitudesKey);
      
      if (solicitudesJson != null) {
        final solicitudesData = jsonDecode(solicitudesJson) as List;
        final solicitudes = solicitudesData.map((solicitudData) {
          return SolicitudCambio.fromMap(Map<String, dynamic>.from(solicitudData));
        }).toList();
        
        setState(() {
          _solicitudesPendientes = solicitudes.where((s) => s.estado == 'pendiente').toList();
        });
      }

      // Cargar mis solicitudes enviadas
      final misSolicitudesKey = 'mis_solicitudes_${_codigoTaxi}';
      final misSolicitudesJson = prefs.getString(misSolicitudesKey);
      
      if (misSolicitudesJson != null) {
        final misSolicitudesData = jsonDecode(misSolicitudesJson) as List;
        final misSolicitudes = misSolicitudesData.map((solicitudData) {
          return SolicitudCambio.fromMap(Map<String, dynamic>.from(solicitudData));
        }).toList();
        
        setState(() {
          _misSolicitudes = misSolicitudes.where((s) => s.estado == 'pendiente').toList();
        });
      }
    } catch (e) {
      print('Error cargando solicitudes: $e');
    }
  }

  void _seleccionarParadaDesdeNotificacion() async {
    final paradaId = widget.paradaSeleccionadaId;
    if (paradaId != null) {
      // Cargar datos actualizados de la cola
      await _cargarColaActualizada(paradaId);
      
      final parada = _paradas.firstWhere(
        (p) => p.id == paradaId,
        orElse: () => _paradas.first,
      );
      setState(() {
        _paradaSeleccionada = parada;
      });
      
      // Mostrar un mensaje informativo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parada seleccionada: ${parada.nombre}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cargarDatos() async {
    final codigo = await PreferencesService.obtenerCodigoTaxi();
    final tel = await PreferencesService.obtenerTelefonoTaxista();
    
    setState(() {
      _codigoTaxi = codigo;
      _telefono = tel;
    });
  }

  /// Inicializa los servicios de geolocalización
  Future<void> _initializeLocationServices() async {
    try {
      bool hasPermission = await _geolocationService.checkLocationPermission();
      
      setState(() {
        _locationPermissionGranted = hasPermission;
      });

      if (hasPermission) {
        await _updateDistanceToEstacion();
        await _updateDistanceToHospital();
        await _updateDistanceToAvenida();
      } else {
        _showLocationPermissionDialog();
      }
    } catch (e) {
      print('Error inicializando servicios de ubicación: $e');
      _showLocationErrorSnackBar('Error al inicializar servicios de ubicación');
    }
  }

  /// Actualiza la distancia a la parada de la estación
  Future<void> _updateDistanceToEstacion() async {
    try {
      // Obtener la ubicación actual (real o simulada)
      Position? currentPosition = await _geolocationService.getCurrentLocation();
      if (currentPosition == null) return;
      
      // Calcular distancia usando la ubicación actual
      double distance = _geolocationService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        _geolocationService.estacionCoordinates['latitud']!,
        _geolocationService.estacionCoordinates['longitud']!,
      );
      
      setState(() {
        _currentDistanceToEstacion = distance;
        _isNearEstacion = distance <= _geolocationService.radioPermitido;
      });
      
      print('📍 Distancia a Estación: ${distance.toStringAsFixed(0)}m (${_geolocationService.isUsingSimulatedLocation ? 'SIMULADA' : 'REAL'})');
    } catch (e) {
      print('Error actualizando distancia: $e');
    }
  }

  /// Actualiza la distancia a la parada del hospital
  Future<void> _updateDistanceToHospital() async {
    try {
      // Obtener la ubicación actual (real o simulada)
      Position? currentPosition = await _geolocationService.getCurrentLocation();
      if (currentPosition == null) return;
      
      // Calcular distancia usando la ubicación actual
      double distance = _geolocationService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        _geolocationService.hospitalCoordinates['latitud']!,
        _geolocationService.hospitalCoordinates['longitud']!,
      );
      
      setState(() {
        _currentDistanceToHospital = distance;
        _isNearHospital = distance <= _geolocationService.radioPermitido;
      });
      
      print('📍 Distancia a Hospital: ${distance.toStringAsFixed(0)}m (${_geolocationService.isUsingSimulatedLocation ? 'SIMULADA' : 'REAL'})');
    } catch (e) {
      print('Error actualizando distancia: $e');
    }
  }

  /// Actualiza la distancia a la parada de Avenida Libertad
  Future<void> _updateDistanceToAvenida() async {
    try {
      // Obtener la ubicación actual (real o simulada)
      Position? currentPosition = await _geolocationService.getCurrentLocation();
      if (currentPosition == null) return;
      
      // Calcular distancia usando la ubicación actual
      double distance = _geolocationService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        _geolocationService.avenidaCoordinates['latitud']!,
        _geolocationService.avenidaCoordinates['longitud']!,
      );
      
      setState(() {
        _currentDistanceToAvenida = distance;
        _isNearAvenida = distance <= _geolocationService.radioPermitido;
      });
      
      print('📍 Distancia a Avenida: ${distance.toStringAsFixed(0)}m (${_geolocationService.isUsingSimulatedLocation ? 'SIMULADA' : 'REAL'})');
    } catch (e) {
      print('Error actualizando distancia: $e');
    }
  }

  /// Actualiza la distancia a una parada específica
  Future<void> _updateDistanceToParada(String paradaId) async {
    try {
      // Obtener la ubicación actual (real o simulada)
      Position? currentPosition = await _geolocationService.getCurrentLocation();
      if (currentPosition == null) return;
      
      double distance;
      String paradaName;
      
      // Calcular distancia según la parada
      if (paradaId == _geolocationService.estacionParadaId) {
        distance = _geolocationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          _geolocationService.estacionCoordinates['latitud']!,
          _geolocationService.estacionCoordinates['longitud']!,
        );
        paradaName = 'Estación';
      } else if (paradaId == _geolocationService.hospitalParadaId) {
        distance = _geolocationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          _geolocationService.hospitalCoordinates['latitud']!,
          _geolocationService.hospitalCoordinates['longitud']!,
        );
        paradaName = 'Hospital';
      } else if (paradaId == _geolocationService.avenidaParadaId) {
        distance = _geolocationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          _geolocationService.avenidaCoordinates['latitud']!,
          _geolocationService.avenidaCoordinates['longitud']!,
        );
        paradaName = 'Avenida';
      } else {
        return; // Parada no reconocida
      }
      
      setState(() {
        if (paradaId == _geolocationService.estacionParadaId) {
          _currentDistanceToEstacion = distance;
          _isNearEstacion = distance <= _geolocationService.radioPermitido;
        } else if (paradaId == _geolocationService.hospitalParadaId) {
          _currentDistanceToHospital = distance;
          _isNearHospital = distance <= _geolocationService.radioPermitido;
        } else if (paradaId == _geolocationService.avenidaParadaId) {
          _currentDistanceToAvenida = distance;
          _isNearAvenida = distance <= _geolocationService.radioPermitido;
        }
      });
      
      print('📍 Distancia a $paradaName: ${distance.toStringAsFixed(0)}m (${_geolocationService.isUsingSimulatedLocation ? 'SIMULADA' : 'REAL'})');
    } catch (e) {
      print('Error actualizando distancia: $e');
    }
  }

  /// Muestra diálogo para solicitar permisos de ubicación
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            '📍 Permisos de Ubicación Requeridos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Esta aplicación necesita acceso a tu ubicación para verificar que estés cerca de la parada antes de unirte a la tanda.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showLocationErrorSnackBar('Sin permisos de ubicación no puedes usar esta función');
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _initializeLocationServices();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA28C7D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Conceder Permisos'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra SnackBar de error de ubicación
  void _showLocationErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  /// Inicia el monitoreo de distancia cuando el usuario se apunta a una parada
  void _startDistanceMonitoring(String paradaId) {
    _geolocationService.startDistanceMonitoring(paradaId);
    
    // Configurar un timer para verificar la distancia periódicamente
    Timer.periodic(const Duration(seconds: 20), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Obtener la ubicación actual (real o simulada)
      Position? currentPosition = await _geolocationService.getCurrentLocation();
      if (currentPosition == null) return;
      
      double distance;
      
      // Calcular distancia según la parada
      if (paradaId == _geolocationService.estacionParadaId) {
        distance = _geolocationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          _geolocationService.estacionCoordinates['latitud']!,
          _geolocationService.estacionCoordinates['longitud']!,
        );
      } else if (paradaId == _geolocationService.hospitalParadaId) {
        distance = _geolocationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          _geolocationService.hospitalCoordinates['latitud']!,
          _geolocationService.hospitalCoordinates['longitud']!,
        );
      } else if (paradaId == _geolocationService.avenidaParadaId) {
        distance = _geolocationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          _geolocationService.avenidaCoordinates['latitud']!,
          _geolocationService.avenidaCoordinates['longitud']!,
        );
      } else {
        return; // Parada no reconocida
      }
      
      setState(() {
        if (paradaId == _geolocationService.estacionParadaId) {
          _currentDistanceToEstacion = distance;
        } else if (paradaId == _geolocationService.hospitalParadaId) {
          _currentDistanceToHospital = distance;
        } else if (paradaId == _geolocationService.avenidaParadaId) {
          _currentDistanceToAvenida = distance;
        }
      });
      
      // Si se alejó más de 100 metros, remover de la cola
      if (distance > _geolocationService.radioPermitido) {
        _handleUserLeftParadaArea(paradaId);
        timer.cancel();
      }
    });
  }

  /// Maneja cuando el usuario se aleja de una parada específica
  void _handleUserLeftParadaArea(String paradaId) async {
    if (_codigoTaxi == null) return;

    try {
      // Remover automáticamente de la cola
      await _firestoreService.eliminarTaxiDeCola(
        paradaId,
        _codigoTaxi!,
      );

      setState(() {
        if (paradaId == _geolocationService.estacionParadaId) {
          _isNearEstacion = false;
          _currentDistanceToEstacion = null;
        } else if (paradaId == _geolocationService.hospitalParadaId) {
          _isNearHospital = false;
          _currentDistanceToHospital = null;
        } else if (paradaId == _geolocationService.avenidaParadaId) {
          _isNearAvenida = false;
          _currentDistanceToAvenida = null;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_off, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🚶 Te has alejado de la parada, has sido retirado de la tanda.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      print('Error removiendo usuario de la cola: $e');
    }
  }

  // Los datos se cargan automáticamente con StreamBuilder
  // Estos métodos se mantienen por compatibilidad
  Future<void> _cargarColaActualizada(String paradaId) async {
    // Implementado con StreamBuilder
  }

  Future<void> _cargarTodasLasColas() async {
    // Implementado con StreamBuilder
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Taxi Mollet del Vallès',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _updateLocationData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Ubicación actualizada'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: '🔄 Actualizar ubicación',
          ),
          IconButton(
            icon: const Icon(Icons.map, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PantallaMapaSimple(),
                ),
              );
            },
            tooltip: '🗺️ Simulador de ubicación',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.black),
            onPressed: () {
              _forceUpdateSimulatedLocation();
            },
            tooltip: '🐛 Forzar actualización simulada',
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.black),
            onPressed: _irAAdministracion,
            tooltip: 'Administración',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del taxista
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_taxi,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taxista: ${_codigoTaxi ?? 'No asignado'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Teléfono: ${_telefono ?? 'No registrado'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botón del mapa
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PantallaMapaSimple(),
                  ),
                );
              },
              icon: const Icon(Icons.map, size: 20),
              label: const Text(
                '🗺️ VER MAPA DE UBICACIÓN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),

          // Mensaje informativo
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Selecciona la parada donde estás y apúntate a la tanda.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E40AF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFC107), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: Color(0xFF856404),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          '🚫 Solo puedes estar en una tanda a la vez',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF856404),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF2196F3), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF1976D2),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          '📍 Estación, Hospital y Avenida: Debes estar a menos de 100m para unirte',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Sección de solicitudes pendientes
          if (_solicitudesPendientes.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFC107)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF856404),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Solicitudes de cambio pendientes (${_solicitudesPendientes.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF856404),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._solicitudesPendientes.map((solicitud) => _buildSolicitudPendiente(solicitud)).toList(),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Lista de paradas en tiempo real
          Expanded(
            child: StreamBuilder<Map<String, ColaTaxis>>(
              stream: _firestoreService.getAllColasStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar datos: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                final colas = snapshot.data ?? {};
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _paradas.length,
                  itemBuilder: (context, index) {
                    final parada = _paradas[index];
                    final colaActualizada = colas[parada.id] ?? parada;
                    return _buildTarjetaParada(colaActualizada);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaParada(ColaTaxis parada) {
    final estaSeleccionada = _paradaSeleccionada?.id == parada.id;
    final yaEnCola = parada.taxisEnCola.any((taxi) => taxi.codigoTaxi == _codigoTaxi);
    final enOtraParada = _paradas.any((p) => 
      p.id != parada.id && 
      p.taxisEnCola.any((taxi) => taxi.codigoTaxi == _codigoTaxi)
    );
    
    // Determinar el estado del taxista
    String estadoTaxista = '';
    Color colorEstado = Colors.grey;
    IconData iconoEstado = Icons.help_outline;
    
    if (yaEnCola) {
      estadoTaxista = 'En esta tanda';
      colorEstado = Colors.green;
      iconoEstado = Icons.check_circle;
    } else if (enOtraParada) {
      estadoTaxista = 'En otra tanda';
      colorEstado = Colors.orange;
      iconoEstado = Icons.warning;
    } else {
      estadoTaxista = 'Disponible';
      colorEstado = Colors.blue;
      iconoEstado = Icons.add_circle_outline;
    }

    // Verificación especial para paradas que requieren ubicación
    bool requiresLocation = _geolocationService.requiresLocationVerification(parada.id);
    String? locationStatus;
    Color? locationColor;
    
    if (requiresLocation) {
      if (!_locationPermissionGranted) {
        locationStatus = 'Sin permisos de ubicación';
        locationColor = Colors.red;
      } else {
        double? currentDistance;
        bool isNear;
        
        if (parada.id == _geolocationService.estacionParadaId) {
          currentDistance = _currentDistanceToEstacion;
          isNear = _isNearEstacion;
        } else if (parada.id == _geolocationService.hospitalParadaId) {
          currentDistance = _currentDistanceToHospital;
          isNear = _isNearHospital;
        } else if (parada.id == _geolocationService.avenidaParadaId) {
          currentDistance = _currentDistanceToAvenida;
          isNear = _isNearAvenida;
        } else {
          currentDistance = null;
          isNear = false;
        }
        
        if (currentDistance != null) {
          if (isNear) {
            locationStatus = 'Cerca (${currentDistance.toStringAsFixed(0)}m)';
            locationColor = Colors.green;
          } else {
            locationStatus = 'Lejos (${currentDistance.toStringAsFixed(0)}m)';
            locationColor = Colors.red;
          }
        } else {
          locationStatus = 'Verificando ubicación...';
          locationColor = Colors.orange;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: estaSeleccionada 
            ? const Color(0xFFF3F4F6)
            : yaEnCola
                ? const Color(0xFFF0FDF4)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: estaSeleccionada 
                ? const Color(0xFF3B82F6).withOpacity(0.15)
                : yaEnCola
                    ? const Color(0xFF22C55E).withOpacity(0.15)
                    : Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: estaSeleccionada 
              ? const Color(0xFF3B82F6)
              : yaEnCola
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFE5E7EB),
          width: estaSeleccionada ? 2 : yaEnCola ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la parada
          InkWell(
            onTap: () {
              setState(() {
                _paradaSeleccionada = _paradaSeleccionada?.id == parada.id ? null : parada;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: estaSeleccionada 
                    ? const Color(0xFF3B82F6)
                    : yaEnCola
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF9FAFB),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Icono de la parada con fondo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: estaSeleccionada 
                          ? Colors.white.withOpacity(0.2)
                          : yaEnCola
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFF6B7280).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconoParada(parada.nombre),
                      color: estaSeleccionada 
                          ? Colors.white 
                          : yaEnCola
                              ? Colors.white
                              : const Color(0xFF374151),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parada.nombre,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: estaSeleccionada 
                                ? Colors.white 
                                : yaEnCola
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          parada.ubicacion,
                          style: TextStyle(
                            fontSize: 14,
                            color: estaSeleccionada 
                                ? Colors.white.withOpacity(0.9)
                                : yaEnCola
                                    ? Colors.white.withOpacity(0.9)
                                    : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badges y controles
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Fila superior: Badge de taxis y estado
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge de número de taxis
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: estaSeleccionada 
                                  ? Colors.white.withOpacity(0.2)
                                  : yaEnCola
                                      ? Colors.white.withOpacity(0.2)
                                      : const Color(0xFF6B7280).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: estaSeleccionada 
                                    ? Colors.white.withOpacity(0.3)
                                    : yaEnCola
                                        ? Colors.white.withOpacity(0.3)
                                        : const Color(0xFF6B7280).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_taxi,
                                  size: 14,
                                  color: estaSeleccionada 
                                      ? Colors.white 
                                      : yaEnCola
                                          ? Colors.white
                                          : const Color(0xFF374151),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${parada.taxisEnCola.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: estaSeleccionada 
                                        ? Colors.white 
                                        : yaEnCola
                                            ? Colors.white
                                            : const Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge de estado del taxista eliminado
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Fila inferior: Indicador de ubicación (si aplica) y botón expandir
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                                            // Indicador de ubicación para paradas que requieren verificación
                  if (requiresLocation && locationStatus != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: locationColor!.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: locationColor!.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _locationPermissionGranted ? Icons.location_on : Icons.location_off,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    locationStatus!,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // Icono de expandir
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: estaSeleccionada 
                                  ? Colors.white.withOpacity(0.2)
                                  : yaEnCola
                                      ? Colors.white.withOpacity(0.2)
                                      : const Color(0xFF6B7280).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              estaSeleccionada ? Icons.expand_less : Icons.expand_more,
                              color: estaSeleccionada 
                                  ? Colors.white 
                                  : yaEnCola
                                      ? Colors.white
                                      : const Color(0xFF374151),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Detalles de la tanda (solo si está seleccionada)
          if (estaSeleccionada) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de la tanda
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.queue,
                          color: const Color(0xFF374151),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tanda actual (${parada.taxisEnCola.length} taxis)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Lista de taxis en la tanda
                  ...parada.taxisEnCola.asMap().entries.map((entry) {
                    final index = entry.key;
                    final taxi = entry.value;
                    return _buildTaxiEnTanda(index + 1, taxi);
                  }).toList(),

                  const SizedBox(height: 12),

                  // Botones para apuntarse/eliminarse
                  if (yaEnCola) ...[
                    // Botón para eliminarse
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _estaCargando ? null : _eliminarseDeTanda,
                        icon: _estaCargando 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.remove_circle_outline),
                        label: Text(
                          _estaCargando ? 'Eliminando...' : 'Eliminarse de la tanda',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Botón para apuntarse
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _estaCargando ? null : _apuntarseATanda,
                        icon: _estaCargando 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(
                          _estaCargando 
                              ? 'Apuntándose...'
                              : (enOtraParada ? 'Cambiar a esta tanda' : 'Apuntarse a la tanda'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: enOtraParada
                              ? Colors.blue
                              : const Color(0xFF888888),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Botón para actualizar ubicación (solo para paradas que requieren verificación)
                  if (requiresLocation) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _estaCargando ? null : () => _updateDistanceToParada(parada.id),
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          'Actualizar ubicación',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSolicitudPendiente(SolicitudCambio solicitud) {
    final tiempoTranscurrido = DateTime.now().difference(solicitud.timestamp);
    final minutosTranscurridos = tiempoTranscurrido.inMinutes;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC107)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz,
                color: Color(0xFF856404),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${solicitud.taxiSolicitante} quiere cambiar contigo',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF856404),
                  ),
                ),
              ),
              Text(
                '${minutosTranscurridos} min',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF856404),
                ),
              ),
            ],
          ),
          if (solicitud.mensaje != null) ...[
            const SizedBox(height: 8),
            Text(
              'Mensaje: ${solicitud.mensaje}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF856404),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _responderSolicitud(solicitud, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Aceptar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _responderSolicitud(solicitud, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC3545),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Rechazar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaxiEnTanda(int posicion, TaxiEnCola taxi) {
    final tiempoEspera = DateTime.now().difference(taxi.timestamp);
    final minutosEspera = tiempoEspera.inMinutes;
    final esMiTaxi = taxi.codigoTaxi == _codigoTaxi;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: esMiTaxi 
              ? [const Color(0xFF888888).withOpacity(0.3), const Color(0xFF666666).withOpacity(0.2)]
              : [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esMiTaxi 
              ? const Color(0xFF888888)
              : const Color(0xFF333333),
          width: esMiTaxi ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: esMiTaxi 
                ? const Color(0xFF888888).withOpacity(0.2)
                : Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Número de posición con fondo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: esMiTaxi 
                    ? [const Color(0xFF888888), const Color(0xFF666666)]
                    : [const Color(0xFF444444), const Color(0xFF333333)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: esMiTaxi 
                    ? const Color(0xFF888888)
                    : const Color(0xFF555555),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$posicion',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Taxi ${taxi.codigoTaxi}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: esMiTaxi 
                            ? const Color(0xFF888888)
                            : Colors.white,
                      ),
                    ),
                    if (esMiTaxi) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: Color(0xFF888888),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Esperando ${minutosEspera} min',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${taxi.timestamp.hour.toString().padLeft(2, '0')}:${taxi.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Botón de solicitar cambio (solo si no es mi taxi y estoy en la misma parada)
              if (!esMiTaxi && _paradaSeleccionada != null && 
                  _paradaSeleccionada!.taxisEnCola.any((t) => t.codigoTaxi == _codigoTaxi)) ...[
                const SizedBox(height: 4),
                IconButton(
                  onPressed: () => _solicitarCambioPosicion(taxi),
                  icon: const Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                  tooltip: 'Solicitar cambio de posición',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconoParada(String nombre) {
    switch (nombre.toLowerCase()) {
      case 'hospital de mollet':
        return Icons.local_hospital;
      case 'avenida libertad':
        return Icons.location_city;
      case 'estación mollet-san fost':
        return Icons.train;
      default:
        return Icons.location_on;
    }
  }

  Future<void> _apuntarseATanda() async {
    if (_codigoTaxi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas un código de taxi para apuntarte'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paradaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una parada primero'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificación especial para paradas que requieren ubicación
    if (_geolocationService.requiresLocationVerification(_paradaSeleccionada!.id)) {
      if (!_locationPermissionGranted) {
        _showLocationPermissionDialog();
        return;
      }

      // Usar las distancias ya calculadas (que incluyen ubicación simulada si está activa)
      bool isNearParada = false;
      double? currentDistance;
      
      if (_paradaSeleccionada!.id == _geolocationService.estacionParadaId) {
        isNearParada = _isNearEstacion;
        currentDistance = _currentDistanceToEstacion;
        print('📍 Verificando Estación - Cerca: $isNearParada, Distancia: ${currentDistance?.toStringAsFixed(0)}m');
      } else if (_paradaSeleccionada!.id == _geolocationService.hospitalParadaId) {
        isNearParada = _isNearHospital;
        currentDistance = _currentDistanceToHospital;
        print('📍 Verificando Hospital - Cerca: $isNearParada, Distancia: ${currentDistance?.toStringAsFixed(0)}m');
      } else if (_paradaSeleccionada!.id == _geolocationService.avenidaParadaId) {
        isNearParada = _isNearAvenida;
        currentDistance = _currentDistanceToAvenida;
        print('📍 Verificando Avenida - Cerca: $isNearParada, Distancia: ${currentDistance?.toStringAsFixed(0)}m');
      }
      
      if (!isNearParada) {
        String distanceText = currentDistance != null 
            ? '${currentDistance.toStringAsFixed(0)} metros'
            : 'distancia desconocida';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_off, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '❌ Debes estar cerca de la parada para unirte a la tanda. (${distanceText})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
    }

    // Verificar si ya está en la cola de esta parada específica
    final yaEnCola = _paradaSeleccionada!.taxisEnCola.any((taxi) => taxi.codigoTaxi == _codigoTaxi);
    if (yaEnCola) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ya estás en la tanda de ${_paradaSeleccionada!.nombre}. No puedes apuntarte dos veces.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Entendido',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    // Verificar si está en otra parada usando StreamBuilder data
    final enOtraParada = _paradas.any((parada) => 
      parada.id != _paradaSeleccionada!.id && 
      parada.taxisEnCola.any((taxi) => taxi.codigoTaxi == _codigoTaxi)
    );

    if (enOtraParada) {
      final otraParada = _paradas.firstWhere((parada) => 
        parada.id != _paradaSeleccionada!.id && 
        parada.taxisEnCola.any((taxi) => taxi.codigoTaxi == _codigoTaxi)
      );

      showDialog(
        context: context,
        barrierDismissible: false, // No permitir cerrar tocando fuera
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('🚫 Ya estás en otra tanda'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ya estás apuntado en la tanda de:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${otraParada.nombre}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¿Quieres cambiarte a la tanda de:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_paradaSeleccionada!.nombre}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solo puedes estar en una tanda a la vez',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cambiarDeTanda(otraParada);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA28C7D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cambiar de tanda',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _estaCargando = true;
    });

    try {
      // Guardar los cambios en Firebase primero
      await _firestoreService.anadirTaxiACola(_paradaSeleccionada!.id, _codigoTaxi!);
      
      // Si la operación fue exitosa, actualizar la UI
      final nuevoTaxi = TaxiEnCola(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        codigoTaxi: _codigoTaxi!,
        timestamp: DateTime.now(),
      );

      setState(() {
        _paradaSeleccionada!.taxisEnCola.add(nuevoTaxi);
        _estaCargando = false;
      });

      // Iniciar monitoreo de distancia si es una parada que requiere verificación
      if (_geolocationService.requiresLocationVerification(_paradaSeleccionada!.id)) {
        _startDistanceMonitoring(_paradaSeleccionada!.id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                                  child: Text(
                    _geolocationService.requiresLocationVerification(_paradaSeleccionada!.id)
                        ? '✅ Te has apuntado a la tanda de ${_paradaSeleccionada!.nombre} (Monitoreo de ubicación activado)'
                        : '✅ Te has apuntado a la tanda de ${_paradaSeleccionada!.nombre}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      print('Error guardando cambios: $e');
      
      // Mostrar mensaje de error más específico
      String mensajeError = 'Error al apuntarse a la tanda';
      String icono = '❌';
      
      if (e.toString().contains('Ya estás registrado')) {
        mensajeError = 'Ya estás registrado en otra parada. Solo puedes estar en una tanda a la vez.';
        icono = '🚫';
      } else if (e.toString().contains('cloud_firestore')) {
        mensajeError = 'Error de conexión con la base de datos. Verifica tu conexión a internet.';
        icono = '📡';
      } else if (e.toString().contains('permission-denied')) {
        mensajeError = 'No tienes permisos para realizar esta acción';
        icono = '🔒';
      } else if (e.toString().contains('Timeout')) {
        mensajeError = 'La operación tardó demasiado. Verifica tu conexión a internet.';
        icono = '⏰';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(icono, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mensajeError,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _apuntarseATanda();
            },
          ),
        ),
      );
    }
  }

  Future<void> _cambiarDeTanda(ColaTaxis paradaAnterior) async {
    // Mostrar indicador de carga
    setState(() {
      _estaCargando = true;
    });

    try {
      // Guardar los cambios en Firebase primero
      await _firestoreService.eliminarTaxiDeCola(paradaAnterior.id, _codigoTaxi!);
      await _firestoreService.anadirTaxiACola(_paradaSeleccionada!.id, _codigoTaxi!);
      
      // Si la operación fue exitosa, actualizar la UI
      setState(() {
        // Remover de la tanda anterior
        paradaAnterior.taxisEnCola.removeWhere((taxi) => taxi.codigoTaxi == _codigoTaxi);
        
        // Agregar a la nueva tanda
        final nuevoTaxi = TaxiEnCola(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          codigoTaxi: _codigoTaxi!,
          timestamp: DateTime.now(),
        );
        _paradaSeleccionada!.taxisEnCola.add(nuevoTaxi);
        
        _estaCargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🔄 Cambio exitoso: ${paradaAnterior.nombre} → ${_paradaSeleccionada!.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      print('Error cambiando de tanda: $e');
      
      // Mostrar mensaje de error más específico
      String mensajeError = 'Error al cambiar de tanda';
      String icono = '❌';
      
      if (e.toString().contains('cloud_firestore')) {
        mensajeError = 'Error de conexión con la base de datos. Verifica tu conexión a internet.';
        icono = '📡';
      } else if (e.toString().contains('permission-denied')) {
        mensajeError = 'No tienes permisos para realizar esta acción';
        icono = '🔒';
      } else if (e.toString().contains('Timeout')) {
        mensajeError = 'La operación tardó demasiado. Verifica tu conexión a internet.';
        icono = '⏰';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(icono, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mensajeError,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _cambiarDeTanda(paradaAnterior);
            },
          ),
        ),
      );
    }
  }

  Future<void> _solicitarCambioPosicion(TaxiEnCola taxiDestino) async {
    if (_codigoTaxi == null || _paradaSeleccionada == null) return;

    // Verificar que no sea el mismo taxi
    if (taxiDestino.codigoTaxi == _codigoTaxi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes solicitar cambio contigo mismo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que no haya una solicitud pendiente ya
    final solicitudExistente = _misSolicitudes.any((s) => 
      s.taxiSolicitado == taxiDestino.codigoTaxi && 
      s.paradaId == _paradaSeleccionada!.id &&
      s.estado == 'pendiente'
    );

    if (solicitudExistente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tienes una solicitud pendiente con este taxi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo para confirmar la solicitud
    final mensaje = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Solicitar cambio con ${taxiDestino.codigoTaxi}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Quieres solicitar intercambiar tu posición con este taxi?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Mensaje opcional',
                  hintText: 'Explica por qué quieres cambiar de posición...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  // Guardar el mensaje temporalmente
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final mensajeController = context.findAncestorWidgetOfExactType<TextField>();
                Navigator.of(context).pop(mensajeController?.controller?.text ?? '');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar solicitud'),
            ),
          ],
        );
      },
    );

    if (mensaje == null) return; // Usuario canceló

    // Crear la solicitud
    final solicitud = SolicitudCambio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taxiSolicitante: _codigoTaxi!,
      taxiSolicitado: taxiDestino.codigoTaxi,
      paradaId: _paradaSeleccionada!.id,
      timestamp: DateTime.now(),
      estado: 'pendiente',
      mensaje: mensaje.isNotEmpty ? mensaje : null,
    );

    // Guardar la solicitud
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar en mis solicitudes
      final misSolicitudesKey = 'mis_solicitudes_${_codigoTaxi}';
      final misSolicitudesActuales = _misSolicitudes;
      misSolicitudesActuales.add(solicitud);
      await prefs.setString(misSolicitudesKey, jsonEncode(misSolicitudesActuales.map((s) => s.toMap()).toList()));
      
      // Guardar en las solicitudes del taxi destino
      final solicitudesDestinoKey = 'solicitudes_${taxiDestino.codigoTaxi}';
      final solicitudesDestinoJson = prefs.getString(solicitudesDestinoKey);
      List<SolicitudCambio> solicitudesDestino = [];
      
      if (solicitudesDestinoJson != null) {
        final solicitudesData = jsonDecode(solicitudesDestinoJson) as List;
        solicitudesDestino = solicitudesData.map((solicitudData) {
          return SolicitudCambio.fromMap(Map<String, dynamic>.from(solicitudData));
        }).toList();
      }
      
      solicitudesDestino.add(solicitud);
      await prefs.setString(solicitudesDestinoKey, jsonEncode(solicitudesDestino.map((s) => s.toMap()).toList()));

      setState(() {
        _misSolicitudes.add(solicitud);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solicitud enviada a ${taxiDestino.codigoTaxi}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enviando solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _responderSolicitud(SolicitudCambio solicitud, bool aceptar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Actualizar estado de la solicitud
      final solicitudActualizada = solicitud.copyWith(
        estado: aceptar ? 'aceptada' : 'rechazada',
      );

      // Actualizar en las solicitudes del taxi solicitado
      final solicitudesDestinoKey = 'solicitudes_${solicitud.taxiSolicitado}';
      final solicitudesDestinoJson = prefs.getString(solicitudesDestinoKey);
      if (solicitudesDestinoJson != null) {
        final solicitudesData = jsonDecode(solicitudesDestinoJson) as List;
        List<SolicitudCambio> solicitudesDestino = solicitudesData.map((solicitudData) {
          return SolicitudCambio.fromMap(Map<String, dynamic>.from(solicitudData));
        }).toList();
        
        final index = solicitudesDestino.indexWhere((s) => s.id == solicitud.id);
        if (index != -1) {
          solicitudesDestino[index] = solicitudActualizada;
          await prefs.setString(solicitudesDestinoKey, jsonEncode(solicitudesDestino.map((s) => s.toMap()).toList()));
        }
      }

      // Actualizar en mis solicitudes
      final misSolicitudesKey = 'mis_solicitudes_${solicitud.taxiSolicitante}';
      final misSolicitudesJson = prefs.getString(misSolicitudesKey);
      if (misSolicitudesJson != null) {
        final misSolicitudesData = jsonDecode(misSolicitudesJson) as List;
        List<SolicitudCambio> misSolicitudes = misSolicitudesData.map((solicitudData) {
          return SolicitudCambio.fromMap(Map<String, dynamic>.from(solicitudData));
        }).toList();
        
        final index = misSolicitudes.indexWhere((s) => s.id == solicitud.id);
        if (index != -1) {
          misSolicitudes[index] = solicitudActualizada;
          await prefs.setString(misSolicitudesKey, jsonEncode(misSolicitudes.map((s) => s.toMap()).toList()));
        }
      }

      // Si se aceptó, realizar el intercambio
      if (aceptar) {
        await _realizarIntercambio(solicitud);
      }

      // Actualizar listas locales
      setState(() {
        _solicitudesPendientes.removeWhere((s) => s.id == solicitud.id);
        _misSolicitudes.removeWhere((s) => s.id == solicitud.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aceptar ? 'Solicitud aceptada' : 'Solicitud rechazada'),
          backgroundColor: aceptar ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error procesando solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _realizarIntercambio(SolicitudCambio solicitud) async {
    try {
      final parada = _paradas.firstWhere((p) => p.id == solicitud.paradaId);
      final taxisActualizados = List<TaxiEnCola>.from(parada.taxisEnCola);
      
      final indexSolicitante = taxisActualizados.indexWhere((t) => t.codigoTaxi == solicitud.taxiSolicitante);
      final indexSolicitado = taxisActualizados.indexWhere((t) => t.codigoTaxi == solicitud.taxiSolicitado);
      
      if (indexSolicitante != -1 && indexSolicitado != -1) {
        // Intercambiar posiciones
        final temp = taxisActualizados[indexSolicitante];
        taxisActualizados[indexSolicitante] = taxisActualizados[indexSolicitado];
        taxisActualizados[indexSolicitado] = temp;
        
        // Actualizar la parada
        final paradaIndex = _paradas.indexWhere((p) => p.id == solicitud.paradaId);
        if (paradaIndex != -1) {
          setState(() {
            _paradas[paradaIndex] = ColaTaxis(
              id: parada.id,
              nombre: parada.nombre,
              ubicacion: parada.ubicacion,
              taxisEnCola: taxisActualizados,
            );
          });
        }

        // Guardar en Firebase
        await _firestoreService.actualizarCola(solicitud.paradaId, taxisActualizados);
      }
    } catch (e) {
      print('Error realizando intercambio: $e');
    }
  }

  void _eliminarseDeTanda() async {
    if (_paradaSeleccionada == null || _codigoTaxi == null) return;

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🚪 Salir de la tanda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres salir de la tanda de:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_paradaSeleccionada!.nombre}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Perderás tu posición en la cola',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Salir de la tanda',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    // Mostrar indicador de carga
    setState(() {
      _estaCargando = true;
    });

    try {
      // Guardar los cambios en Firebase primero
      await _firestoreService.eliminarTaxiDeCola(_paradaSeleccionada!.id, _codigoTaxi!);
      
      // Si la operación fue exitosa, actualizar la UI
      setState(() {
        _paradaSeleccionada!.taxisEnCola.removeWhere(
          (taxi) => taxi.codigoTaxi == _codigoTaxi,
        );
        _estaCargando = false;
      });

      // Detener monitoreo de distancia si es una parada que requiere verificación
      if (_geolocationService.requiresLocationVerification(_paradaSeleccionada!.id)) {
        _geolocationService.stopDistanceMonitoring();
      }

      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🚪 Has salido de la tanda de ${_paradaSeleccionada!.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      print('Error guardando cambios: $e');
      
      // Mostrar mensaje de error más específico
      String mensajeError = 'Error al eliminarse de la tanda';
      String icono = '❌';
      
      if (e.toString().contains('cloud_firestore')) {
        mensajeError = 'Error de conexión con la base de datos. Verifica tu conexión a internet.';
        icono = '📡';
      } else if (e.toString().contains('permission-denied')) {
        mensajeError = 'No tienes permisos para realizar esta acción';
        icono = '🔒';
      } else if (e.toString().contains('Timeout')) {
        mensajeError = 'La operación tardó demasiado. Verifica tu conexión a internet.';
        icono = '⏰';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(icono, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mensajeError,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _eliminarseDeTanda();
            },
          ),
        ),
      );
    }
  }

  void _irAAdministracion() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PantallaAdministracion(),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      await PreferencesService.limpiarDatosTaxista();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLocationData() async {
    if (!mounted) return;
    
    try {
      // Actualizar distancias para todas las paradas que requieren verificación
      await _updateDistanceToParada(_geolocationService.estacionParadaId);
      await _updateDistanceToParada(_geolocationService.hospitalParadaId);
      await _updateDistanceToParada(_geolocationService.avenidaParadaId);
      
      // No necesitamos setState aquí porque _updateDistanceToParada ya lo hace
    } catch (e) {
      print('Error actualizando ubicación: $e');
    }
  }

  /// Actualiza las distancias usando una posición específica (del stream)
  Future<void> _updateLocationDataWithPosition(Position position) async {
    if (!mounted) return;
    
    try {
      print('📍 Actualizando distancias con posición específica: ${position.latitude}, ${position.longitude}');
      
      // Calcular distancias usando la posición recibida del stream
      double distanceEstacion = _geolocationService.calculateDistance(
        position.latitude,
        position.longitude,
        _geolocationService.estacionCoordinates['latitud']!,
        _geolocationService.estacionCoordinates['longitud']!,
      );
      
      double distanceHospital = _geolocationService.calculateDistance(
        position.latitude,
        position.longitude,
        _geolocationService.hospitalCoordinates['latitud']!,
        _geolocationService.hospitalCoordinates['longitud']!,
      );
      
      double distanceAvenida = _geolocationService.calculateDistance(
        position.latitude,
        position.longitude,
        _geolocationService.avenidaCoordinates['latitud']!,
        _geolocationService.avenidaCoordinates['longitud']!,
      );
      
      setState(() {
        _currentDistanceToEstacion = distanceEstacion;
        _isNearEstacion = distanceEstacion <= _geolocationService.radioPermitido;
        
        _currentDistanceToHospital = distanceHospital;
        _isNearHospital = distanceHospital <= _geolocationService.radioPermitido;
        
        _currentDistanceToAvenida = distanceAvenida;
        _isNearAvenida = distanceAvenida <= _geolocationService.radioPermitido;
      });
      
      print('📍 Distancias actualizadas - Estación: ${distanceEstacion.toStringAsFixed(0)}m, Hospital: ${distanceHospital.toStringAsFixed(0)}m, Avenida: ${distanceAvenida.toStringAsFixed(0)}m');
    } catch (e) {
      print('Error actualizando ubicación con posición específica: $e');
    }
  }

  /// Fuerza la actualización de la ubicación simulada
  Future<void> _forceUpdateSimulatedLocation() async {
    if (!mounted) return;
    
    try {
      print('🐛 Forzando actualización de ubicación simulada...');
      print('📍 Modo simulación activo: ${_geolocationService.isUsingSimulatedLocation}');
      
      // Obtener la ubicación actual (debería ser simulada si está activa)
      Position? currentPosition = await _geolocationService.getCurrentLocation();
      if (currentPosition != null) {
        print('📍 Ubicación actual: ${currentPosition.latitude}, ${currentPosition.longitude}');
      }
      
      // Forzar actualización de todas las distancias
      await _updateLocationData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🐛 Ubicación forzada: ${_geolocationService.isUsingSimulatedLocation ? 'SIMULADA' : 'REAL'}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error forzando actualización: $e');
    }
  }
} 