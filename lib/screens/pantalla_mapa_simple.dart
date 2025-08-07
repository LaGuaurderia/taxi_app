import 'package:flutter/material.dart';
import 'dart:math';
import '../services/geolocation_service.dart';

class PantallaMapaSimple extends StatefulWidget {
  const PantallaMapaSimple({Key? key}) : super(key: key);

  @override
  State<PantallaMapaSimple> createState() => _PantallaMapaSimpleState();
}

class _PantallaMapaSimpleState extends State<PantallaMapaSimple> {
  final GeolocationService _geolocationService = GeolocationService();
  
  // Posición simulada
  double _simulatedLat = 41.5298;
  double _simulatedLng = 2.1170;
  
  // Distancias calculadas
  double _distanceToEstacion = 0.0;
  double _distanceToHospital = 0.0;
  double _distanceToAvenida = 0.0;
  
  // Estados de proximidad
  bool _isNearEstacion = false;
  bool _isNearHospital = false;
  bool _isNearAvenida = false;
  
  // Mensaje de estado
  String _statusMessage = '📍 Simulador de ubicación activo';
  
  // Control de actualizaciones
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _calculateSimulatedDistances();
  }

  void _simulateLocation(double lat, double lng) {
    if (_isUpdating) return; // Evitar múltiples actualizaciones simultáneas
    
    setState(() {
      _isUpdating = true;
      _simulatedLat = lat;
      _simulatedLng = lng;
      _statusMessage = '📍 Ubicación simulada: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    });
    
    // Actualizar la ubicación simulada en el servicio
    _geolocationService.setSimulatedLocation(lat, lng);
    
    // Calcular nuevas distancias con la ubicación simulada
    _calculateSimulatedDistances();
    
    // Mostrar feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📍 Ubicación simulada establecida'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _calculateSimulatedDistances() {
    // Distancia a Estación Mollet - Sant Fost
    _distanceToEstacion = _calculateDistance(
      _simulatedLat, _simulatedLng,
      41.533611, 2.217778,
    );
    _isNearEstacion = _distanceToEstacion <= 100.0;

    // Distancia a Hospital de Mollet
    _distanceToHospital = _calculateDistance(
      _simulatedLat, _simulatedLng,
      41.54362, 2.2018799999,
    );
    _isNearHospital = _distanceToHospital <= 100.0;

    // Distancia a Avenida Libertad
    _distanceToAvenida = _calculateDistance(
      _simulatedLat, _simulatedLng,
      41.536472, 2.212167,
    );
    _isNearAvenida = _distanceToAvenida <= 100.0;

    setState(() {
      _isUpdating = false;
    });
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Fórmula de Haversine para calcular distancia entre dos puntos
    const double earthRadius = 6371000; // Radio de la Tierra en metros
    
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLng = (lng2 - lng1) * (pi / 180);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  void _moveRandom() {
    // Generar ubicación aleatoria cerca de las paradas
    final random = DateTime.now().millisecondsSinceEpoch;
    final randomLat = 41.53 + (random % 100) / 10000.0;
    final randomLng = 2.20 + (random % 100) / 10000.0;
    
    _simulateLocation(randomLat, randomLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Simulador de Ubicación'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coordenadas actuales: ${_simulatedLat.toStringAsFixed(6)}, ${_simulatedLng.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  if (_geolocationService.isUsingSimulatedLocation)
                    const Text(
                      '✅ Modo simulación activo',
                      style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botones de simulación
            const Text(
              '📍 Simular ubicación:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Botón Estación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : () => _simulateLocation(41.533611, 2.217778),
                icon: const Icon(Icons.train, size: 20),
                label: const Text('🚉 Estación Mollet - Sant Fost'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Botón Hospital
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : () => _simulateLocation(41.54362, 2.2018799999),
                icon: const Icon(Icons.local_hospital, size: 20),
                label: const Text('🏥 Hospital de Mollet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Botón Avenida
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : () => _simulateLocation(41.536472, 2.212167),
                icon: const Icon(Icons.directions_car, size: 20),
                label: const Text('🛣️ Avenida Libertad'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Botón Aleatorio
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _moveRandom,
                icon: const Icon(Icons.shuffle, size: 20),
                label: const Text('🎲 Ubicación Aleatoria'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Botón Usar Ubicación Real
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : () {
                  _geolocationService.clearSimulatedLocation();
                  setState(() {
                    _statusMessage = '✅ Simulación desactivada - Usando ubicación real';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📍 Usando ubicación real'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.grey,
                    ),
                  );
                },
                icon: const Icon(Icons.location_on, size: 20),
                label: const Text('📍 Usar Ubicación Real'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Información de distancias
            const Text(
              '📏 Distancias a las paradas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Tarjeta Estación
            _buildDistanceCard(
              '🚉 Estación Mollet - Sant Fost',
              _distanceToEstacion,
              _isNearEstacion,
              Colors.orange,
            ),
            
            const SizedBox(height: 8),
            
            // Tarjeta Hospital
            _buildDistanceCard(
              '🏥 Hospital de Mollet',
              _distanceToHospital,
              _isNearHospital,
              Colors.red,
            ),
            
            const SizedBox(height: 8),
            
            // Tarjeta Avenida
            _buildDistanceCard(
              '🛣️ Avenida Libertad',
              _distanceToAvenida,
              _isNearAvenida,
              Colors.green,
            ),
            
            const SizedBox(height: 24),
            
            // Instrucciones
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Instrucciones:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Presiona un botón para simular tu ubicación\n'
                    '2. Ve a la pantalla de paradas para ver los cambios\n'
                    '3. Prueba apuntarte a las colas según tu ubicación\n'
                    '4. Usa "Ubicación Real" para volver a tu posición actual',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceCard(String title, double distance, bool isNear, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNear ? color.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNear ? color : Colors.grey.shade300,
          width: isNear ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isNear ? Icons.check_circle : Icons.cancel,
            color: isNear ? Colors.green : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${distance.toStringAsFixed(0)} metros',
                  style: TextStyle(
                    color: isNear ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
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
} 