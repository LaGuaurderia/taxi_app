import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/preferences_service.dart';
import '../models/cola_taxis.dart';
import '../models/taxi_en_cola.dart';
import 'firestore_test_screen.dart';
import 'pantalla_registro_taxista.dart';
import 'pantalla_prueba_geolocalizacion.dart';
import 'pantalla_mapa_simple.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  String? _codigoTaxi;
  String? _telefono;
  List<ColaTaxis> _puntosCalientes = [];
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarPuntosCalientes();
    // Prueba de conexión con Firestore al iniciar
    testFirestoreConnection();
  }

  Future<void> _cargarDatos() async {
    final codigo = await PreferencesService.obtenerCodigoTaxi();
    final tel = await PreferencesService.obtenerTelefonoTaxista();
    
    setState(() {
      _codigoTaxi = codigo;
      _telefono = tel;
    });
  }

  // Prueba mínima de conexión con Firestore
  void testFirestoreConnection() async {
    try {
      await FirebaseFirestore.instance
          .collection('debug_test')
          .add({'timestamp': DateTime.now()});
      print('✅ Conexión con Firestore OK');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Conexión con Firestore OK'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error de Firestore: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('❌ Error de Firestore: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _cargarPuntosCalientes() async {
    setState(() {
      _estaCargando = true;
    });

    // Simular carga de datos
    await Future.delayed(const Duration(seconds: 1));

    // Datos de ejemplo
    final puntosCalientes = [
      ColaTaxis(
        id: '1',
        nombre: 'Aeropuerto Tenerife Sur',
        ubicacion: 'Granadilla de Abona',
        taxisEnCola: [
          TaxiEnCola(
            id: '1',
            codigoTaxi: 'M1',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
          TaxiEnCola(
            id: '2',
            codigoTaxi: 'M3',
            timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
          ),
          TaxiEnCola(
            id: '3',
            codigoTaxi: 'M7',
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        ],
      ),
      ColaTaxis(
        id: '2',
        nombre: 'Puerto de Los Cristianos',
        ubicacion: 'Arona',
        taxisEnCola: [
          TaxiEnCola(
            id: '4',
            codigoTaxi: 'M2',
            timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
          ),
          TaxiEnCola(
            id: '5',
            codigoTaxi: 'M5',
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        ],
      ),
      ColaTaxis(
        id: '3',
        nombre: 'Centro Comercial Siam Mall',
        ubicacion: 'Adeje',
        taxisEnCola: [
          TaxiEnCola(
            id: '6',
            codigoTaxi: 'M4',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
          TaxiEnCola(
            id: '7',
            codigoTaxi: 'M6',
            timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          ),
          TaxiEnCola(
            id: '8',
            codigoTaxi: 'M8',
            timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        ],
      ),
    ];

    setState(() {
      _puntosCalientes = puntosCalientes;
      _estaCargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        title: const Text('Puntos Calientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaRegistroTaxista(),
                ),
              );
            },
            tooltip: 'Registro de Taxista',
          ),
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirestoreTestScreen(),
                ),
              );
            },
            tooltip: 'Pantalla de prueba Firestore',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: testFirestoreConnection,
            tooltip: 'Probar conexión Firestore',
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaPruebaGeolocalizacion(),
                ),
              );
            },
            tooltip: 'Prueba de Geolocalización',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPuntosCalientes,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E1DA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA28C7D), width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_taxi,
                  color: Color(0xFFA28C7D),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taxista: ${_codigoTaxi ?? 'No asignado'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF584130),
                        ),
                      ),
                      Text(
                        'Teléfono: ${_telefono ?? 'No registrado'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFBDA697),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botones de prueba de geolocalización
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaPruebaGeolocalizacion(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 24),
                  label: const Text(
                    '📊 INFO DE GEOLOCALIZACIÓN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaMapaSimple(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 24),
                  label: const Text(
                    '🗺️ MAPA INTERACTIVO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D58),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),

          // Lista de puntos calientes
          Expanded(
            child: _estaCargando
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28C7D)),
                    ),
                  )
                : _puntosCalientes.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay puntos calientes disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFBDA697),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _puntosCalientes.length,
                        itemBuilder: (context, index) {
                          final punto = _puntosCalientes[index];
                          return _buildPuntoCaliente(punto);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuntoCaliente(ColaTaxis punto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Encabezado del punto caliente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFA28C7D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        punto.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${punto.taxisEnCola.length} taxis',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  punto.ubicacion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Lista de taxis en cola
          if (punto.taxisEnCola.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Taxis en cola:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF584130),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...punto.taxisEnCola.asMap().entries.map((entry) {
                    final index = entry.key;
                    final taxi = entry.value;
                    return _buildTaxiEnCola(index + 1, taxi);
                  }).toList(),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'No hay taxis en cola',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFBDA697),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Botón de acción
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _unirseACola(punto),
              icon: const Icon(Icons.add),
              label: Text(
                'Unirse a cola de ${punto.nombre}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
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
        ],
      ),
    );
  }

  Widget _buildTaxiEnCola(int posicion, TaxiEnCola taxi) {
    final tiempoEspera = DateTime.now().difference(taxi.timestamp);
    final minutosEspera = tiempoEspera.inMinutes;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E1DA), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFA28C7D),
              borderRadius: BorderRadius.circular(16),
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
                Text(
                  'Taxi ${taxi.codigoTaxi}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF584130),
                  ),
                ),
                Text(
                  'Esperando ${minutosEspera} min',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBDA697),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${taxi.timestamp.hour.toString().padLeft(2, '0')}:${taxi.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFBDA697),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _unirseACola(ColaTaxis punto) {
    if (_codigoTaxi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas un código de taxi para unirte a la cola'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar si ya está en la cola
    final yaEnCola = punto.taxisEnCola.any((taxi) => taxi.codigoTaxi == _codigoTaxi);
    if (yaEnCola) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya estás en esta cola'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Agregar a la cola
    final nuevoTaxi = TaxiEnCola(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      codigoTaxi: _codigoTaxi!,
      timestamp: DateTime.now(),
    );

    setState(() {
      punto.taxisEnCola.add(nuevoTaxi);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Te has unido a la cola de ${punto.nombre}'),
        backgroundColor: Colors.green,
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
} 