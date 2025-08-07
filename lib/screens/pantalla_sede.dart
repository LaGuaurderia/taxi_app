import 'package:flutter/material.dart';
import '../models/cola_taxis.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class PantallaSede extends StatefulWidget {
  const PantallaSede({super.key});

  @override
  State<PantallaSede> createState() => _PantallaSedeState();
}

class _PantallaSedeState extends State<PantallaSede> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  // Mapa de iconos para cada parada
  final Map<String, IconData> _iconosParadas = {
    'hospital': Icons.local_hospital,
    'avenida': Icons.streetview,
    'estacion': Icons.train,
  };

  // Mapa de emojis para cada parada
  final Map<String, String> _emojisParadas = {
    'hospital': '🏥',
    'avenida': '🛣️',
    'estacion': '🚉',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        title: Text(
          'Panel Sede',
          style: TextStyle(
            color: const Color(0xFF584130),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF8F6F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF584130)),
        actions: [
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
              
              // Título principal
              Text(
                'Gestión de Colas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF584130),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Control en tiempo real de las paradas',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFFBDA697),
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
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar las colas',
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF584130),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFFBDA697),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    if (!snapshot.hasData) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28C7D)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Cargando colas...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF584130),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final colas = snapshot.data!;
                    
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ParadasDisponibles.paradas.map((parada) {
                        final cola = colas[parada.id] ?? ColaTaxis(
                          id: parada.id,
                          nombre: parada.nombre,
                          ubicacion: 'Mollet del Vallès',
                          taxisEnCola: [],
                        );
                        final numTaxis = cola.taxisEnCola.length;
                        final isAdvertencia = numTaxis > 5;
                        
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Encabezado de la columna
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA28C7D),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Emoji y icono
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _emojisParadas[parada.id] ?? '📍',
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _iconosParadas[parada.id] ?? Icons.location_on,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        parada.nombre,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$numTaxis taxis',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Lista de taxis
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isAdvertencia 
                                          ? const Color(0xFFF9D5D3) 
                                          : const Color(0xFFE8E1DA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isAdvertencia 
                                            ? const Color(0xFFE57373) 
                                            : const Color(0xFFD7CCC8),
                                        width: 1,
                                      ),
                                    ),
                                    child: cola.taxisEnCola.isEmpty
                                        ? _buildEmptyState()
                                        : _buildTaxiList(cola, parada.id, isAdvertencia),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Información adicional
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E1DA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD7CCC8),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF584130),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de colas',
                            style: TextStyle(
                              color: const Color(0xFF584130),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toca 🗑️ para eliminar un taxi. Las colas con más de 5 taxis se muestran en rojo.',
                            style: TextStyle(
                              color: const Color(0xFF584130),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue,
            size: 48,
            color: const Color(0xFF584130).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin taxis',
            style: TextStyle(
              fontSize: 16,
              color: const Color(0xFF584130),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay taxis en esta parada',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF584130).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaxiList(ColaTaxis cola, String paradaId, bool isAdvertencia) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cola.taxisEnCola.length,
      itemBuilder: (context, index) {
        final taxi = cola.taxisEnCola[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAdvertencia 
                      ? const Color(0xFFE57373).withOpacity(0.3)
                      : const Color(0xFFE8E1DA),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Número de posición
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA28C7D),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Código del taxi y tiempo de espera
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Taxi',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF584130).withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: const Color(0xFF584130).withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatearTiempoEspera(taxi.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF584130).withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          taxi.codigoTaxi,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF584130),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getColorTiempoEspera(_calcularMinutosEspera(taxi.timestamp)).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getColorTiempoEspera(_calcularMinutosEspera(taxi.timestamp)).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Esperando ${_formatearTiempoEspera(taxi.timestamp)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getColorTiempoEspera(_calcularMinutosEspera(taxi.timestamp)),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón eliminar
                  InkWell(
                    onTap: () => _eliminarTaxi(paradaId, taxi.codigoTaxi),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Método para obtener el color según el tiempo de espera
  Color _getColorTiempoEspera(int minutos) {
    if (minutos < 5) {
      return Colors.green;
    } else if (minutos < 15) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Método para calcular minutos de espera
  int _calcularMinutosEspera(DateTime timestamp) {
    return DateTime.now().difference(timestamp).inMinutes;
  }

  // Método para formatear tiempo de espera
  String _formatearTiempoEspera(DateTime timestamp) {
    final diferencia = DateTime.now().difference(timestamp);
    final minutos = diferencia.inMinutes;
    final horas = diferencia.inHours;
    
    if (horas > 0) {
      return '${horas}h ${minutos % 60}m';
    } else {
      return '${minutos}m';
    }
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