import 'package:flutter/material.dart';
import '../models/cola_taxis.dart';
import '../services/firestore_service.dart';
import '../services/preferences_service.dart';
import '../services/geolocation_service.dart';
import '../services/auth_service.dart';

class PantallaTaxista extends StatefulWidget {
  const PantallaTaxista({super.key});

  @override
  State<PantallaTaxista> createState() => _PantallaTaxistaState();
}

class _PantallaTaxistaState extends State<PantallaTaxista> {
  String? _paradaSeleccionada;
  String? _codigoTaxi;
  bool _estaEnCola = false;
  final FirestoreService _firestoreService = FirestoreService();
  final GeolocationService _geolocationService = GeolocationService();
  final AuthService _authService = AuthService();
  bool _geolocalizacionInicializada = false;
  
  // Variable para activar/desactivar simulación manual
  static const bool modoSimulacion = true;

  @override
  void initState() {
    super.initState();
    _cargarCodigoTaxiAutenticado();
    _verificarEstadoCola();
    _inicializarGeolocalizacion();
  }

  Future<void> _cargarCodigoTaxiAutenticado() async {
    final codigo = await _authService.obtenerIdTaxiActual();
    setState(() {
      _codigoTaxi = codigo;
    });
  }

  Future<void> _cargarCodigoTaxi() async {
    final codigo = await PreferencesService.obtenerCodigoTaxi();
    setState(() {
      _codigoTaxi = codigo;
    });
  }

  Future<void> _verificarEstadoCola() async {
    if (_codigoTaxi == null) return;
    
    try {
      // Verificar en qué parada está el taxi
      Map<String, ColaTaxis> colas = await _firestoreService.getAllColasStream().first;
      
      for (var entry in colas.entries) {
        if (entry.value.taxisEnCola.any((taxi) => taxi.codigoTaxi == _codigoTaxi)) {
          setState(() {
            _estaEnCola = true;
            _paradaSeleccionada = entry.key;
          });
          // Actualizar parada actual en geolocalización
          _geolocationService.actualizarParadaActual(entry.key);
          return;
        }
      }
      
      // Si no está en ninguna cola
      setState(() {
        _estaEnCola = false;
        _paradaSeleccionada = null;
      });
      _geolocationService.actualizarParadaActual(null);
    } catch (e) {
      print('Error al verificar estado de cola: $e');
    }
  }

  Future<void> _inicializarGeolocalizacion() async {
    try {
      bool inicializado = await _geolocationService.inicializar(context);
      if (inicializado) {
        setState(() {
          _geolocalizacionInicializada = true;
        });
        
        // Iniciar monitoreo de ubicación
        _geolocationService.iniciarMonitoreo(
          onCercaDeParada: _onCercaDeParada,
          onAlejadoDeParada: _onAlejadoDeParada,
        );
      }
    } catch (e) {
      print('Error al inicializar geolocalización: $e');
    }
  }

  void _onCercaDeParada(String paradaId, String nombreParada) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Parada Cercana'),
          content: Text('Estás cerca de la parada $nombreParada. ¿Quieres unirte a la cola?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _geolocationService.resetearDialogos();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unirseAColaAutomaticamente(paradaId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA28C7D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Unirme'),
            ),
          ],
        );
      },
    );
  }

  void _onAlejadoDeParada(String paradaId) {
    if (!mounted) return;
    
    String nombreParada = ParadasDisponibles.getParadaById(paradaId).nombre;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Te has alejado'),
          content: Text('Te has alejado de la parada $nombreParada. ¿Quieres salir de la cola?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _geolocationService.resetearDialogos();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _salirDeColaAutomaticamente();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _unirseAColaAutomaticamente(String paradaId) async {
    if (_codigoTaxi == null) return;
    
    try {
      await _firestoreService.anadirTaxiACola(paradaId, _codigoTaxi!);
      setState(() {
        _estaEnCola = true;
        _paradaSeleccionada = paradaId;
      });
      _geolocationService.actualizarParadaActual(paradaId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Te has unido automáticamente a la cola de ${ParadasDisponibles.getParadaById(paradaId).nombre}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error al unirse automáticamente: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _salirDeColaAutomaticamente() async {
    if (_codigoTaxi == null) return;
    
    try {
      await _firestoreService.salirDeCola(_codigoTaxi!);
      setState(() {
        _estaEnCola = false;
        _paradaSeleccionada = null;
      });
      _geolocationService.actualizarParadaActual(null);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Has salido automáticamente de la cola'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error al salir automáticamente: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _apuntarseACola() async {
    if (_paradaSeleccionada == null || _codigoTaxi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una parada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _firestoreService.anadirTaxiACola(_paradaSeleccionada!, _codigoTaxi!);
      setState(() {
        _estaEnCola = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Te has apuntado a la cola de ${ParadasDisponibles.getParadaById(_paradaSeleccionada!).nombre}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String mensaje = 'Error al apuntarse a la cola';
        Color color = Colors.red;
        
        // Verificar si es el error específico de ya estar registrado
        if (e.toString().contains('Ya estás registrado en otra parada')) {
          mensaje = 'Ya estás registrado en otra parada.';
          color = Colors.orange;
        } else {
          mensaje = 'Error al apuntarse a la cola: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  e.toString().contains('Ya estás registrado en otra parada') 
                      ? Icons.warning 
                      : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(mensaje)),
              ],
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _salirDeCola() async {
    if (_codigoTaxi == null) return;

    try {
      await _firestoreService.salirDeCola(_codigoTaxi!);
      setState(() {
        _estaEnCola = false;
        _paradaSeleccionada = null;
      });
      _geolocationService.actualizarParadaActual(null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Has salido de la cola'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error al salir de la cola: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _cerrarSesion() async {
    try {
      await _authService.cerrarSesion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
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

  // Método para construir tarjetas de simulación
  Widget _buildTarjetaSimulacion(String paradaId, String titulo, Color color, IconData icono) {
    return InkWell(
      onTap: () => _simularProximidad(paradaId, titulo),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icono,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF584130),
                ),
              ),
            ),
            Icon(
              Icons.touch_app,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Método para simular proximidad a una parada
  void _simularProximidad(String paradaId, String nombreParada) {
    if (_codigoTaxi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se ha cargado el código de taxi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.location_on,
                color: const Color(0xFFA28C7D),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Simulación de Proximidad'),
            ],
          ),
          content: Text('¿Quieres unirte a la cola de $nombreParada?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('❌ Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unirseAColaSimulacion(paradaId, nombreParada);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA28C7D),
                foregroundColor: Colors.white,
              ),
              child: const Text('✅ Unirme'),
            ),
          ],
        );
      },
    );
  }

  // Método para unirse a la cola desde simulación
  Future<void> _unirseAColaSimulacion(String paradaId, String nombreParada) async {
    if (_codigoTaxi == null) return;
    
    try {
      await _firestoreService.anadirTaxiACola(paradaId, _codigoTaxi!);
      setState(() {
        _estaEnCola = true;
        _paradaSeleccionada = paradaId;
      });
      _geolocationService.actualizarParadaActual(paradaId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Te has unido a la cola de $nombreParada'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String mensaje = 'Error al unirse a la cola';
        Color color = Colors.red;
        
        // Verificar si es el error específico de ya estar registrado
        if (e.toString().contains('Ya estás registrado en otra parada')) {
          mensaje = 'Ya estás registrado en otra parada. Sal primero para cambiar.';
          color = Colors.orange;
        } else {
          mensaje = 'Error al unirse a la cola: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  e.toString().contains('Ya estás registrado en otra parada') 
                      ? Icons.warning 
                      : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(mensaje)),
              ],
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _geolocationService.detenerMonitoreo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        title: Text(
          'Panel Taxista',
          style: TextStyle(
            color: const Color(0xFF584130),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF8F6F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF584130)),
        actions: [
          if (_codigoTaxi != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA28C7D),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _codigoTaxi!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'cerrar_sesion') {
                _cerrarSesion();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'cerrar_sesion',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF584130)),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              // Indicador de geolocalización
              if (_geolocalizacionInicializada) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Geolocalización activa - Te notificaremos cuando estés cerca de una parada',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Simulación Manual (solo si está activada)
              if (modoSimulacion) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sim_card,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modo Simulación - Toca una parada para simular proximidad',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tarjetas de simulación
                Text(
                  'Simular proximidad:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF584130),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tarjeta Hospital Mollet
                _buildTarjetaSimulacion(
                  'hospital',
                  '🏥 Hospital Mollet',
                  Colors.blue,
                  Icons.local_hospital,
                ),
                const SizedBox(height: 8),
                
                // Tarjeta Avenida Libertad
                _buildTarjetaSimulacion(
                  'avenida',
                  '🛣️ Avenida Libertad',
                  Colors.green,
                  Icons.directions_car,
                ),
                const SizedBox(height: 8),
                
                // Tarjeta Estación Mollet-San Fost
                _buildTarjetaSimulacion(
                  'estacion',
                  '🚉 Estación Mollet-San Fost',
                  Colors.purple,
                  Icons.train,
                ),
                
                const SizedBox(height: 24),
              ],
              
              // Selector de parada
              Text(
                'Selecciona una parada:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF584130),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botones de parada
              ...ParadasDisponibles.paradas.map((parada) {
                final isSelected = _paradaSeleccionada == parada.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _paradaSeleccionada = parada.id;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFA28C7D) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFA28C7D) : const Color(0xFFE8E1DA),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: isSelected ? Colors.white : const Color(0xFF584130),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              parada.nombre,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF584130),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              if (_paradaSeleccionada != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _estaEnCola ? null : _apuntarseACola,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA28C7D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Apuntarme a la cola',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _estaEnCola ? _salirDeCola : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.remove_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Salir de la cola',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Lista de taxis en la cola
              if (_paradaSeleccionada != null) ...[
                Text(
                  'Taxis en cola:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF584130),
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: StreamBuilder<ColaTaxis>(
                    stream: _firestoreService.getColaStream(_paradaSeleccionada!),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar la cola: ${snapshot.error}',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      
                      final cola = snapshot.data!;
                      
                      if (cola.taxisEnCola.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E1DA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.queue,
                                size: 48,
                                color: const Color(0xFF584130),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay taxis en cola',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFF584130),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sé el primero en apuntarte',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: const Color(0xFFBDA697),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return ListView.builder(
                                              itemCount: cola.taxisEnCola.length,
                      itemBuilder: (context, index) {
                        final taxi = cola.taxisEnCola[index];
                                                      final isMyTaxi = taxi.codigoTaxi == _codigoTaxi;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isMyTaxi ? const Color(0xFFA28C7D) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE8E1DA),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isMyTaxi ? Colors.white : const Color(0xFFA28C7D),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isMyTaxi ? const Color(0xFFA28C7D) : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Taxi ${taxi.codigoTaxi}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isMyTaxi ? Colors.white : const Color(0xFF584130),
                                        ),
                                      ),
                                      if (isMyTaxi)
                                        Text(
                                          'Tú',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.local_taxi,
                                  color: isMyTaxi ? Colors.white : const Color(0xFF584130),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 