import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cola_taxis.dart';
import '../models/taxi_en_cola.dart';
import '../services/firestore_service.dart';

class PantallaAdministracion extends StatefulWidget {
  const PantallaAdministracion({super.key});

  @override
  State<PantallaAdministracion> createState() => _PantallaAdministracionState();
}

class _PantallaAdministracionState extends State<PantallaAdministracion> {
  bool _autenticado = false;
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _mostrandoPassword = false;
  bool _cargando = false;
  final FirestoreService _firestoreService = FirestoreService();

  // Lista de paradas
  List<ColaTaxis> _paradas = [
    ColaTaxis(
      id: 'hospital_mollet',
      nombre: 'Hospital de Mollet',
      ubicacion: 'Carrer de l\'Hospital, Mollet del Vallès',
      taxisEnCola: [],
    ),
    ColaTaxis(
      id: 'avenida_libertad',
      nombre: 'Avenida Libertad',
      ubicacion: 'Avinguda de la Llibertat, Mollet del Vallès',
      taxisEnCola: [],
    ),
    ColaTaxis(
      id: 'estacion_mollet',
      nombre: 'Estación Mollet-San Fost',
      ubicacion: 'Estació de Mollet-Sant Fost, Mollet del Vallès',
      taxisEnCola: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    // Los datos se cargan automáticamente con StreamBuilder
    // Este método se mantiene por compatibilidad con el botón de refresh
  }

  Future<void> _autenticar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
    });

    // Simular verificación
    await Future.delayed(const Duration(seconds: 1));

    if (_passwordController.text == '123admin') {
      setState(() {
        _autenticado = true;
        _cargando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceso autorizado'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _cargando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña incorrecta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _quitarPrimero(String paradaId) async {
    try {
      final paradaIndex = _paradas.indexWhere((p) => p.id == paradaId);
      if (paradaIndex != -1 && _paradas[paradaIndex].taxisEnCola.isNotEmpty) {
        final taxisActualizados = List<TaxiEnCola>.from(_paradas[paradaIndex].taxisEnCola);
        taxisActualizados.removeAt(0);
        
        setState(() {
          _paradas[paradaIndex] = ColaTaxis(
            id: _paradas[paradaIndex].id,
            nombre: _paradas[paradaIndex].nombre,
            ubicacion: _paradas[paradaIndex].ubicacion,
            taxisEnCola: taxisActualizados,
          );
        });

        // Guardar en Firebase
        await _firestoreService.actualizarCola(paradaId, taxisActualizados);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primer taxi removido de la cola'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resetearCola(String paradaId) async {
    try {
      final paradaIndex = _paradas.indexWhere((p) => p.id == paradaId);
      if (paradaIndex != -1) {
        setState(() {
          _paradas[paradaIndex] = ColaTaxis(
            id: _paradas[paradaIndex].id,
            nombre: _paradas[paradaIndex].nombre,
            ubicacion: _paradas[paradaIndex].ubicacion,
            taxisEnCola: [],
          );
        });

        // Guardar en Firebase
        await _firestoreService.resetCola(paradaId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cola reseteada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reordenarTaxis(String paradaId, int oldIndex, int newIndex) async {
    try {
      final paradaIndex = _paradas.indexWhere((p) => p.id == paradaId);
      if (paradaIndex != -1) {
        final taxisActualizados = List<TaxiEnCola>.from(_paradas[paradaIndex].taxisEnCola);
        
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final taxi = taxisActualizados.removeAt(oldIndex);
        taxisActualizados.insert(newIndex, taxi);
        
        setState(() {
          _paradas[paradaIndex] = ColaTaxis(
            id: _paradas[paradaIndex].id,
            nombre: _paradas[paradaIndex].nombre,
            ubicacion: _paradas[paradaIndex].ubicacion,
            taxisEnCola: taxisActualizados,
          );
        });

        // Guardar en Firebase
        await _firestoreService.actualizarCola(paradaId, taxisActualizados);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Taxi ${taxi.codigoTaxi} reordenado'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_autenticado) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text(
            'Panel de Administración',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 2,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 4,
                shadowColor: Colors.grey.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono de administración
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Acceso Administrativo',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa la contraseña para acceder al panel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Campo de contraseña
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_mostrandoPassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFF6B7280)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _mostrandoPassword ? Icons.visibility : Icons.visibility_off,
                                color: const Color(0xFF6B7280),
                              ),
                              onPressed: () {
                                setState(() {
                                  _mostrandoPassword = !_mostrandoPassword;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide(color: Color(0xFFDC2626), width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa la contraseña';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botón de acceso
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _autenticar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Acceder',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Panel de Administración',
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
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              setState(() {
                _autenticado = false;
                _passwordController.clear();
              });
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con información
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Administrador',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      StreamBuilder<Map<String, ColaTaxis>>(
                        stream: _firestoreService.getAllColasStream(),
                        builder: (context, snapshot) {
                          final totalTaxis = snapshot.data?.values.fold(0, (sum, parada) => sum + parada.taxisEnCola.length) ?? 0;
                          return Text(
                            'Total de taxis en cola: $totalTaxis',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de paradas en tiempo real
          Expanded(
            child: StreamBuilder<Map<String, ColaTaxis>>(
              stream: _firestoreService.getAllColasStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
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
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _paradas.map((parada) {
                      final colaActualizada = colas[parada.id] ?? parada;
                      return _buildTarjetaParada(colaActualizada);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaParada(ColaTaxis parada) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la parada
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Icono de la parada
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconoParada(parada.nombre),
                    color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parada.ubicacion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge con número de taxis
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_taxi,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${parada.taxisEnCola.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contenido de la parada
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                 // Lista de taxis en la cola
                 if (parada.taxisEnCola.isNotEmpty) ...[
                   Row(
                     children: [
                       const Icon(
                         Icons.swap_vert,
                         color: Color(0xFF6B7280),
                         size: 20,
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: const Text(
                           'Taxis en cola (usa las flechas para reordenar):',
                           style: TextStyle(
                             fontSize: 16,
                             fontWeight: FontWeight.w600,
                             color: Colors.black,
                           ),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Column(
                     children: parada.taxisEnCola.asMap().entries.map((entry) {
                       final index = entry.key;
                       final taxi = entry.value;
                       return _buildTaxiEnColaReordenable(index + 1, taxi, index);
                     }).toList(),
                   ),
                 ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'No hay taxis en esta cola',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: parada.taxisEnCola.isNotEmpty 
                            ? () => _quitarPrimero(parada.id)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        label: const Text('Quitar primero'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: parada.taxisEnCola.isNotEmpty 
                            ? () => _resetearCola(parada.id)
                            : null,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Resetear cola'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
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
              ],
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
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Badge de posición
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
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
                  taxi.codigoTaxi,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Esperando: ${minutosEspera} min',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${taxi.timestamp.hour.toString().padLeft(2, '0')}:${taxi.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxiEnColaReordenable(int posicion, TaxiEnCola taxi, int index) {
    final tiempoEspera = DateTime.now().difference(taxi.timestamp);
    final minutosEspera = tiempoEspera.inMinutes;
    
    // Buscar la parada que contiene este taxi, con manejo de error
    final parada = _paradas.firstWhere(
      (p) => p.taxisEnCola.contains(taxi),
      orElse: () => _paradas.isNotEmpty ? _paradas.first : ColaTaxis(
        id: 'unknown',
        nombre: 'Parada Desconocida',
        ubicacion: 'Ubicación Desconocida',
        taxisEnCola: [],
      ),
    );

    return Container(
      key: ValueKey(taxi.id),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Badge de posición
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
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
                  taxi.codigoTaxi,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Esperando: ${minutosEspera} min',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Botones de reordenamiento
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: index > 0 ? () => _reordenarTaxis(parada.id, index, index - 1) : null,
                icon: const Icon(Icons.keyboard_arrow_up),
                color: index > 0 ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
                tooltip: 'Mover arriba',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                onPressed: index < parada.taxisEnCola.length - 1 ? () => _reordenarTaxis(parada.id, index, index + 1) : null,
                icon: const Icon(Icons.keyboard_arrow_down),
                color: index < parada.taxisEnCola.length - 1 ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
                tooltip: 'Mover abajo',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Text(
            '${taxi.timestamp.hour.toString().padLeft(2, '0')}:${taxi.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconoParada(String nombre) {
    if (nombre.contains('Hospital')) {
      return Icons.local_hospital;
    } else if (nombre.contains('Avenida')) {
      return Icons.streetview;
    } else if (nombre.contains('Estación')) {
      return Icons.train;
    }
    return Icons.location_on;
  }
} 