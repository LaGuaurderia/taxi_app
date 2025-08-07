import 'package:flutter/material.dart';
import '../models/cola_taxis.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class PantallaSedeWeb extends StatefulWidget {
  const PantallaSedeWeb({super.key});

  @override
  State<PantallaSedeWeb> createState() => _PantallaSedeWebState();
}

class _PantallaSedeWebState extends State<PantallaSedeWeb> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // Mapa de iconos y emojis para cada parada
  final Map<String, IconData> _iconosParadas = {
    'hospital': Icons.local_hospital,
    'avenida': Icons.streetview,
    'estacion': Icons.train,
  };

  final Map<String, String> _emojisParadas = {
    'hospital': '🏥',
    'avenida': '🛣️',
    'estacion': '🚉',
  };

  final Map<String, String> _nombresParadas = {
    'hospital': 'Hospital Mollet',
    'avenida': 'Avenida Libertad',
    'estacion': 'Estación Mollet-San Fost',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        title: const Text('Central Radio Taxi'),
        backgroundColor: const Color(0xFFE8E1DA),
        elevation: 2,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFA28C7D),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SEDE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título principal
              const Text(
                'Gestión de Colas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF584130),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Control en tiempo real de las paradas',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFBDA697),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Columnas de paradas
              Expanded(
                child: StreamBuilder<Map<String, ColaTaxis>>(
                  stream: _firestoreService.getAllColasStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error al cargar las colas',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF584130),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: const TextStyle(
                                color: Color(0xFFBDA697),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28C7D)),
                        ),
                      );
                    }

                    final colas = snapshot.data ?? {};
                    
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive: 1 columna en móvil, 3 en desktop
                        final isMobile = constraints.maxWidth < 800;
                        
                        if (isMobile) {
                          return _buildMobileLayout(colas);
                        } else {
                          return _buildDesktopLayout(colas);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Map<String, ColaTaxis> colas) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildColumnaParada('hospital', colas['hospital'])),
        const SizedBox(width: 16),
        Expanded(child: _buildColumnaParada('avenida', colas['avenida'])),
        const SizedBox(width: 16),
        Expanded(child: _buildColumnaParada('estacion', colas['estacion'])),
      ],
    );
  }

  Widget _buildMobileLayout(Map<String, ColaTaxis> colas) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildColumnaParada('hospital', colas['hospital']),
          const SizedBox(height: 16),
          _buildColumnaParada('avenida', colas['avenida']),
          const SizedBox(height: 16),
          _buildColumnaParada('estacion', colas['estacion']),
        ],
      ),
    );
  }

  Widget _buildColumnaParada(String paradaId, ColaTaxis? cola) {
            final taxis = cola?.taxisEnCola.map((taxi) => taxi.codigoTaxi).toList() ?? [];
    final nombreParada = _nombresParadas[paradaId] ?? paradaId;
    final emoji = _emojisParadas[paradaId] ?? '📍';
    final icono = _iconosParadas[paradaId] ?? Icons.location_on;
    
    // Color de fondo según cantidad de taxis
    Color colorFondo = const Color(0xFFE8E1DA);
    if (taxis.length > 5) {
      colorFondo = const Color(0xFFF9D5D3); // Color de advertencia
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la parada
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreParada,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF584130),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              icono,
                              size: 16,
                              color: const Color(0xFFBDA697),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${taxis.length} taxis en cola',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFBDA697),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge con contador
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA28C7D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${taxis.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido de la cola
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: taxis.isNotEmpty ? () => _resetCola(paradaId) : null,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: taxis.isNotEmpty ? () => _asignarServicio(paradaId, taxis.first) : null,
                            icon: const Icon(Icons.assignment, size: 18),
                            label: const Text('Asignar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Lista de taxis
                    Expanded(
                      child: taxis.isEmpty
                          ? _buildEmptyState()
                          : _buildTaxiList(paradaId, taxis),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_taxi,
            size: 48,
            color: const Color(0xFFBDA697),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin taxis en cola',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFBDA697),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxiList(String paradaId, List<String> taxis) {
    return ListView.builder(
      itemCount: taxis.length,
      itemBuilder: (context, index) {
        final codigoTaxi = taxis[index];
        final posicion = index + 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFA28C7D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$posicion',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              codigoTaxi,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF584130),
              ),
            ),
            subtitle: Text(
              'Posición $posicion en la cola',
              style: const TextStyle(
                color: Color(0xFFBDA697),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón asignar servicio
                IconButton(
                  onPressed: () => _asignarServicio(paradaId, codigoTaxi),
                  icon: const Icon(
                    Icons.assignment,
                    color: Colors.green,
                  ),
                  tooltip: 'Asignar servicio',
                ),
                // Botón eliminar
                IconButton(
                  onPressed: () => _eliminarTaxi(paradaId, codigoTaxi),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  tooltip: 'Eliminar de la cola',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _eliminarTaxi(String paradaId, String codigoTaxi) async {
    try {
      await _firestoreService.eliminarTaxiDeCola(paradaId, codigoTaxi);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Taxi $codigoTaxi eliminado de la cola'),
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
                Text('Error al eliminar el taxi: $e'),
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

  Future<void> _resetCola(String paradaId) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vaciar Cola'),
          content: Text('¿Estás seguro de que quieres vaciar la cola de ${_nombresParadas[paradaId]}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Vaciar'),
            ),
          ],
        );
      },
    );

    if (confirmacion == true) {
      try {
        await _firestoreService.resetCola(paradaId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Cola de ${_nombresParadas[paradaId]} vaciada'),
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
                  Text('Error al vaciar la cola: $e'),
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
  }

  void _asignarServicio(String paradaId, String codigoTaxi) {
    final notaController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Asignar Servicio - $codigoTaxi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Taxi: $codigoTaxi'),
              Text('Parada: ${_nombresParadas[paradaId]}'),
              const SizedBox(height: 16),
              const Text('Nota del servicio (opcional):'),
              const SizedBox(height: 8),
              TextField(
                controller: notaController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Cliente en puerta principal',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestoreService.asignarServicio(paradaId, codigoTaxi, notaController.text);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Servicio asignado a $codigoTaxi'),
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
                            Text('Error al asignar servicio: $e'),
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
              },
              child: const Text('Asignar'),
            ),
          ],
        );
      },
    );
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
} 