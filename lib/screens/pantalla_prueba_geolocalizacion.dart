import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geolocation_service.dart';

class PantallaPruebaGeolocalizacion extends StatefulWidget {
  const PantallaPruebaGeolocalizacion({Key? key}) : super(key: key);

  @override
  State<PantallaPruebaGeolocalizacion> createState() => _PantallaPruebaGeolocalizacionState();
}

class _PantallaPruebaGeolocalizacionState extends State<PantallaPruebaGeolocalizacion> {
  final GeolocationService _geolocationService = GeolocationService();
  
  Position? _currentPosition;
  bool _isLoading = true;
  String _statusMessage = 'Cargando ubicación...';
  
  // Distancias a las paradas
  double? _distanceToEstacion;
  double? _distanceToHospital;
  double? _distanceToAvenida;
  
  bool _isNearEstacion = false;
  bool _isNearHospital = false;
  bool _isNearAvenida = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Verificando permisos de ubicación...';
      });

      // Verificar permisos
      bool hasPermission = await _geolocationService.checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ Permisos de ubicación denegados';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Obteniendo ubicación actual...';
      });

      // Obtener ubicación actual
      Position? position = await _geolocationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ No se pudo obtener la ubicación';
        });
        return;
      }
      
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _statusMessage = '✅ Ubicación obtenida';
      });

      // Calcular distancias
      await _calculateDistances();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });
    }
  }

  Future<void> _calculateDistances() async {
    try {
      // Calcular distancia a Estación
      _distanceToEstacion = await _geolocationService.getDistanceToEstacionParada();
      _isNearEstacion = _distanceToEstacion != null && _distanceToEstacion! <= _geolocationService.radioPermitido;
      
      // Calcular distancia a Hospital
      _distanceToHospital = await _geolocationService.getDistanceToHospitalParada();
      _isNearHospital = _distanceToHospital != null && _distanceToHospital! <= _geolocationService.radioPermitido;
      
      // Calcular distancia a Avenida
      _distanceToAvenida = await _geolocationService.getDistanceToAvenidaParada();
      _isNearAvenida = _distanceToAvenida != null && _distanceToAvenida! <= _geolocationService.radioPermitido;
      
      setState(() {});
    } catch (e) {
      print('Error calculando distancias: $e');
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Actualizando ubicación...';
    });

    try {
      Position? newPosition = await _geolocationService.getCurrentLocation();
      if (newPosition == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ No se pudo obtener la ubicación';
        });
        return;
      }
      
      setState(() {
        _currentPosition = newPosition;
        _isLoading = false;
        _statusMessage = '✅ Ubicación actualizada';
      });

      await _calculateDistances();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error actualizando: $e';
      });
    }
  }

  Widget _buildParadaCard(String name, double? distance, bool isNear, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNear ? Colors.green : Colors.grey[300]!,
          width: isNear ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF584130),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distance != null 
                    ? '${distance.toStringAsFixed(1)} metros'
                    : 'Distancia no disponible',
                  style: TextStyle(
                    fontSize: 14,
                    color: distance != null ? Color(0xFFBDA697) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isNear ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isNear ? 'CERCA' : 'LEJOS',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        title: const Text(
          'Prueba de Geolocalización',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28C7D)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel de estado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _statusMessage.contains('✅') 
                                ? Icons.check_circle 
                                : Icons.error,
                              color: _statusMessage.contains('✅') 
                                ? Colors.green 
                                : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF584130),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_currentPosition != null) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Tu ubicación actual:',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF584130),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Latitud: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBDA697),
                            ),
                          ),
                          Text(
                            'Longitud: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBDA697),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Información del radio
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E1DA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA28C7D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFA28C7D),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Radio permitido: ${_geolocationService.radioPermitido} metros',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF584130),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Distancias a las paradas
                  const Text(
                    'Distancias a las paradas:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF584130),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildParadaCard(
                    'Estación Mollet - Sant Fost',
                    _distanceToEstacion,
                    _isNearEstacion,
                    Colors.red,
                  ),
                  
                  _buildParadaCard(
                    'Hospital de Mollet',
                    _distanceToHospital,
                    _isNearHospital,
                    Colors.green,
                  ),
                  
                  _buildParadaCard(
                    'Avenida Libertad',
                    _distanceToAvenida,
                    _isNearAvenida,
                    Colors.orange,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón de actualización
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _refreshLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar ubicación'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA28C7D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Información adicional
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Información útil:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Las paradas marcadas como "CERCA" te permitirán apuntarte a la tanda',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                        Text(
                          '• Las paradas marcadas como "LEJOS" no te permitirán unirte',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                        Text(
                          '• Usa el botón de actualización para refrescar tu ubicación',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 