import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../models/parada.dart';

class LocationTestWidget extends StatefulWidget {
  const LocationTestWidget({super.key});

  @override
  State<LocationTestWidget> createState() => _LocationTestWidgetState();
}

class _LocationTestWidgetState extends State<LocationTestWidget> {
  Position? _currentPosition;
  Parada? _nearbyParada;
  double? _distanceToParada;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _checkProximity();
    } catch (e) {
      print('Error obteniendo ubicación: $e');
    }
  }

  Future<void> _checkProximity() async {
    if (_currentPosition == null) return;

    final nearbyParada = await NotificationService.checkProximity(_currentPosition!);
    if (nearbyParada != null) {
      final distance = await NotificationService.getDistanceToParada(_currentPosition!, nearbyParada);
      setState(() {
        _nearbyParada = nearbyParada;
        _distanceToParada = distance;
      });
    } else {
      setState(() {
        _nearbyParada = null;
        _distanceToParada = null;
      });
    }
  }

  Future<void> _simulateLocation(double lat, double lng, String paradaName) async {
    print('🧪 Simulando ubicación: $lat, $lng ($paradaName)');
    
    // Simular una posición
    final simulatedPosition = Position(
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

    setState(() {
      _currentPosition = simulatedPosition;
    });

    // Verificar proximidad
    final nearbyParada = await NotificationService.checkProximity(simulatedPosition);
    if (nearbyParada != null) {
      final distance = await NotificationService.getDistanceToParada(simulatedPosition, nearbyParada);
      setState(() {
        _nearbyParada = nearbyParada;
        _distanceToParada = distance;
      });

      print('🎯 Cerca de: ${nearbyParada.nombre} (${distance.toStringAsFixed(1)}m)');

      // Mostrar notificación
      await NotificationService.showProximityNotification(nearbyParada);
      
      // También mostrar la alerta de proximidad
      if (mounted) {
        await LocationService.checkProximityAndShowAlert(context, simulatedPosition);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Notificación enviada! Estás cerca de ${nearbyParada.nombre}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _nearbyParada = null;
        _distanceToParada = null;
      });
      
      print('📍 No cerca de ninguna parada');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No estás cerca de ninguna parada'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🧪 Prueba de Geolocalización',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Ubicación actual
        if (_currentPosition != null) ...[
          Text(
            '📍 Ubicación actual:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Color(0xFF888888)),
          ),
          Text(
            'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(color: Color(0xFF888888)),
          ),
          const SizedBox(height: 12),
        ],

        // Parada cercana
        if (_nearbyParada != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎯 Cerca de: ${_nearbyParada!.nombre}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_distanceToParada != null)
                  Text(
                    'Distancia: ${_distanceToParada!.toStringAsFixed(1)} metros',
                    style: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Botones de simulación
        const Text(
          'Simular ubicación:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: () => _simulateLocation(41.548428, 2.212755, 'Hospital de Mollet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF888888),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('🏥 Hospital', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => _simulateLocation(41.540560, 2.213940, 'Avenida Libertad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF888888),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('🏙️ Avenida', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => _simulateLocation(41.545012, 2.208414, 'Estación Mollet-San Fost'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF888888),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('🚂 Estación', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () => _simulateLocation(41.500000, 2.200000, 'Lejos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('📍 Lejos', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Botón para obtener ubicación real
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Obtener ubicación real'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF888888),
            ),
          ),
        ),
      ],
    );
  }
} 