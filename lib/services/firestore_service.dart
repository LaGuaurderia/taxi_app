import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cola_taxis.dart';
import '../models/taxi_en_cola.dart';
import '../models/historial.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'colas';

  // Obtener cola en tiempo real
  Stream<ColaTaxis> getColaStream(String paradaId) {
    try {
      return _firestore
          .collection(_collectionName)
          .doc(paradaId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          // Convertir la estructura antigua a la nueva
          final taxisEnCola = _convertirEstructuraAntigua(data);
          return ColaTaxis(
            id: paradaId,
            nombre: data['nombre'] ?? 'Parada $paradaId',
            ubicacion: data['ubicacion'] ?? 'Mollet del Vallès',
            taxisEnCola: taxisEnCola,
          );
        } else {
          return ColaTaxis(
            id: paradaId,
            nombre: 'Parada $paradaId',
            ubicacion: 'Mollet del Vallès',
            taxisEnCola: [],
          );
        }
      }).handleError((error) {
        print('Error en getColaStream: $error');
        // Retornar una cola vacía en caso de error
        return ColaTaxis(
          id: paradaId,
          nombre: 'Parada $paradaId',
          ubicacion: 'Mollet del Vallès',
          taxisEnCola: [],
        );
      });
    } catch (e) {
      print('Error inicializando getColaStream: $e');
      // Retornar un stream con una cola vacía
      return Stream.value(ColaTaxis(
        id: paradaId,
        nombre: 'Parada $paradaId',
        ubicacion: 'Mollet del Vallès',
        taxisEnCola: [],
      ));
    }
  }

  // Obtener todas las colas en tiempo real
  Stream<Map<String, ColaTaxis>> getAllColasStream() {
    try {
      return _firestore
          .collection(_collectionName)
          .snapshots()
          .map((snapshot) {
        Map<String, ColaTaxis> colas = {};
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            // Convertir la estructura antigua a la nueva
            final taxisEnCola = _convertirEstructuraAntigua(data);
            colas[doc.id] = ColaTaxis(
              id: doc.id,
              nombre: data['nombre'] ?? 'Parada ${doc.id}',
              ubicacion: data['ubicacion'] ?? 'Mollet del Vallès',
              taxisEnCola: taxisEnCola,
            );
          } catch (e) {
            print('Error procesando documento ${doc.id}: $e');
            // Continuar con el siguiente documento
            continue;
          }
        }
        return colas;
      }).handleError((error) {
        print('Error en getAllColasStream: $error');
        // Retornar un mapa vacío en caso de error
        return <String, ColaTaxis>{};
      });
    } catch (e) {
      print('Error inicializando getAllColasStream: $e');
      // Retornar un stream con un mapa vacío
      return Stream.value(<String, ColaTaxis>{});
    }
  }

  // Añadir taxi a la cola usando FieldValue.arrayUnion() para evitar duplicados
  Future<void> anadirTaxiACola(String paradaId, String codigoTaxi) async {
    try {
      // Verificar que los parámetros no sean nulos
      if (paradaId.isEmpty || codigoTaxi.isEmpty) {
        throw Exception('ParadaId y codigoTaxi no pueden estar vacíos');
      }

      // Usar una transacción para garantizar consistencia
      await _firestore.runTransaction((transaction) async {
        // Verificar si el taxi ya está en alguna parada
        QuerySnapshot snapshot = await _firestore.collection(_collectionName).get();
        
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            List<Map<String, dynamic>> taxisActual = List<Map<String, dynamic>>.from(data['taxisEnCola'] ?? []);
            final yaExiste = taxisActual.any((taxi) => taxi['codigoTaxi'] == codigoTaxi);
            if (yaExiste) {
              // El taxi ya está en una parada, lanzar excepción
              throw Exception('Ya estás registrado en otra parada.');
            }
          } catch (e) {
            print('Error verificando taxi en documento ${doc.id}: $e');
            continue;
          }
        }
        
        // Si no está en ninguna parada, proceder a añadirlo
        DocumentReference docRef = _firestore.collection(_collectionName).doc(paradaId);
        
        // Crear nuevo taxi con timestamp
        Map<String, dynamic> nuevoTaxi = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'codigoTaxi': codigoTaxi,
          'timestamp': DateTime.now(),
        };
        
        // Verificar si el documento existe
        DocumentSnapshot docSnapshot = await transaction.get(docRef);
        
        if (docSnapshot.exists) {
          // Verificar una vez más que el taxi no esté en esta parada específica
          Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> taxisActual = List<Map<String, dynamic>>.from(data['taxisEnCola'] ?? []);
          final yaExisteEnEstaParada = taxisActual.any((taxi) => taxi['codigoTaxi'] == codigoTaxi);
          
          if (yaExisteEnEstaParada) {
            throw Exception('Ya estás registrado en esta parada.');
          }
          
          // Documento existe, usar update con arrayUnion
          transaction.update(docRef, {
            'taxisEnCola': FieldValue.arrayUnion([nuevoTaxi]),
          });
        } else {
          // Documento no existe, crear nuevo documento
          transaction.set(docRef, {
            'taxisEnCola': [nuevoTaxi],
            'nombre': _getNombreParada(paradaId),
            'ubicacion': _getUbicacionParada(paradaId),
          });
        }
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La operación tardó demasiado. Verifica tu conexión a internet.');
        },
      );
      
      // Registrar en historial
      await _registrarEnHistorial(codigoTaxi, paradaId, 'entrada');
      
      print('✅ Taxi $codigoTaxi añadido exitosamente a la parada $paradaId');
    } catch (e) {
      print('❌ Error al añadir taxi a la cola: $e');
      rethrow;
    }
  }

  // Eliminar taxi de la cola
  Future<void> eliminarTaxiDeCola(String paradaId, String codigoTaxi) async {
    try {
      // Verificar que los parámetros no sean nulos
      if (paradaId.isEmpty || codigoTaxi.isEmpty) {
        throw Exception('ParadaId y codigoTaxi no pueden estar vacíos');
      }

      DocumentReference docRef = _firestore.collection(_collectionName).doc(paradaId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot doc = await transaction.get(docRef);
        
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> taxisActual = List<Map<String, dynamic>>.from(data['taxisEnCola'] ?? []);
          
          taxisActual.removeWhere((taxi) => taxi['codigoTaxi'] == codigoTaxi);
          
          transaction.update(docRef, {
            'taxisEnCola': taxisActual,
          });
        }
      });
      
      // Registrar en historial
      await _registrarEnHistorial(codigoTaxi, paradaId, 'salida');
    } catch (e) {
      print('Error al eliminar taxi de la cola: $e');
      rethrow;
    }
  }

  // Salir de la cola (eliminar taxi de todas las colas)
  Future<void> salirDeCola(String codigoTaxi) async {
    try {
      print('🔍 Buscando taxi $codigoTaxi en todas las colas...');
      
      // Usar una transacción para garantizar consistencia
      await _firestore.runTransaction((transaction) async {
        // Buscar en qué paradas está el taxi
        QuerySnapshot snapshot = await _firestore.collection(_collectionName).get();
        List<DocumentReference> paradasConTaxi = [];
        List<String> paradasIds = [];
        
        for (var doc in snapshot.docs) {
          try {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            List<Map<String, dynamic>> taxisActual = List<Map<String, dynamic>>.from(data['taxisEnCola'] ?? []);
            final existeEnEstaParada = taxisActual.any((taxi) => taxi['codigoTaxi'] == codigoTaxi);
            
            if (existeEnEstaParada) {
              paradasConTaxi.add(doc.reference);
              paradasIds.add(doc.id);
              print('📍 Taxi $codigoTaxi encontrado en parada ${doc.id}');
            }
          } catch (e) {
            print('Error verificando parada ${doc.id}: $e');
            continue;
          }
        }
        
        // Si no está en ninguna cola, no hacer nada
        if (paradasConTaxi.isEmpty) {
          print('ℹ️ El taxi $codigoTaxi no está en ninguna cola');
          return;
        }
        
        // Eliminar el taxi de todas las paradas donde esté
        for (int i = 0; i < paradasConTaxi.length; i++) {
          DocumentReference docRef = paradasConTaxi[i];
          String paradaId = paradasIds[i];
          
          DocumentSnapshot docSnapshot = await transaction.get(docRef);
          if (docSnapshot.exists) {
            Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
            List<Map<String, dynamic>> taxisActual = List<Map<String, dynamic>>.from(data['taxisEnCola'] ?? []);
            
            // Filtrar el taxi específico
            taxisActual.removeWhere((taxi) => taxi['codigoTaxi'] == codigoTaxi);
            
            // Actualizar el documento
            transaction.update(docRef, {
              'taxisEnCola': taxisActual,
            });
            
            print('✅ Taxi $codigoTaxi eliminado de parada $paradaId');
          }
        }
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La operación tardó demasiado. Verifica tu conexión a internet.');
        },
      );
      
      print('🎉 Taxi $codigoTaxi eliminado exitosamente de todas las colas');
      
      // Registrar en historial para cada parada de la que salió
      QuerySnapshot snapshot = await _firestore.collection(_collectionName).get();
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          List<Map<String, dynamic>> taxisActual = List<Map<String, dynamic>>.from(data['taxisEnCola'] ?? []);
          final existiaEnEstaParada = taxisActual.any((taxi) => taxi['codigoTaxi'] == codigoTaxi);
          
          if (existiaEnEstaParada) {
            await _registrarEnHistorial(codigoTaxi, doc.id, 'salida');
          }
        } catch (e) {
          print('Error registrando historial para parada ${doc.id}: $e');
          continue;
        }
      }
    } catch (e) {
      print('❌ Error al salir de la cola: $e');
      rethrow;
    }
  }

  // Registrar acción en el historial
  Future<void> _registrarEnHistorial(String idTaxi, String parada, String accion) async {
    try {
      await _firestore.collection('historial').add({
        'idTaxi': idTaxi,
        'parada': parada,
        'accion': accion,
        'timestamp': DateTime.now(),
      });
      print('Registrado en historial: $idTaxi - $parada - $accion');
    } catch (e) {
      print('Error al registrar en historial: $e');
      // No rethrow para no interrumpir la operación principal
    }
  }

  // Obtener historial de un taxi específico
  Stream<List<HistorialAccion>> getHistorialTaxi(String idTaxi) {
    return _firestore
        .collection('historial')
        .where('idTaxi', isEqualTo: idTaxi)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistorialAccion.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener historial de una parada específica
  Stream<List<HistorialAccion>> getHistorialParada(String parada) {
    return _firestore
        .collection('historial')
        .where('parada', isEqualTo: parada)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistorialAccion.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener todo el historial
  Stream<List<HistorialAccion>> getHistorialCompleto() {
    return _firestore
        .collection('historial')
        .orderBy('timestamp', descending: true)
        .limit(100) // Limitar a los últimos 100 registros
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HistorialAccion.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener estadísticas del historial
  Future<Map<String, dynamic>> getEstadisticasHistorial() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('historial').get();
      
      Map<String, int> entradasPorParada = {};
      Map<String, int> salidasPorParada = {};
      Map<String, int> accionesPorTaxi = {};
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String parada = data['parada'] ?? '';
        String accion = data['accion'] ?? '';
        String idTaxi = data['idTaxi'] ?? '';
        
        // Contar entradas por parada
        if (accion == 'entrada') {
          entradasPorParada[parada] = (entradasPorParada[parada] ?? 0) + 1;
        }
        
        // Contar salidas por parada
        if (accion == 'salida') {
          salidasPorParada[parada] = (salidasPorParada[parada] ?? 0) + 1;
        }
        
        // Contar acciones por taxi
        accionesPorTaxi[idTaxi] = (accionesPorTaxi[idTaxi] ?? 0) + 1;
      }
      
      return {
        'totalRegistros': snapshot.docs.length,
        'entradasPorParada': entradasPorParada,
        'salidasPorParada': salidasPorParada,
        'accionesPorTaxi': accionesPorTaxi,
      };
    } catch (e) {
      print('Error al obtener estadísticas del historial: $e');
      return {};
    }
  }

  // Resetear una cola (vaciar todos los taxis)
  Future<void> resetCola(String paradaId) async {
    try {
      await _firestore.collection('colas').doc(paradaId).update({
        'orden': [],
      });
      
      // Registrar en historial
      await _firestore.collection('historial').add({
        'idTaxi': 'SEDE',
        'parada': paradaId,
        'accion': 'reset_cola',
        'timestamp': DateTime.now(),
      });
      
      print('Cola $paradaId reseteada correctamente');
    } catch (e) {
      print('Error al resetear cola $paradaId: $e');
      rethrow;
    }
  }

  // Asignar servicio a un taxi
  Future<void> asignarServicio(String paradaId, String codigoTaxi, String nota) async {
    try {
      // Eliminar el taxi de la cola
      await eliminarTaxiDeCola(paradaId, codigoTaxi);
      
      // Registrar la asignación en una nueva colección
      await _firestore.collection('servicios_asignados').add({
        'idTaxi': codigoTaxi,
        'parada': paradaId,
        'nota': nota,
        'timestamp': DateTime.now(),
        'estado': 'asignado',
      });
      
      // Registrar en historial
      await _firestore.collection('historial').add({
        'idTaxi': codigoTaxi,
        'parada': paradaId,
        'accion': 'servicio_asignado',
        'timestamp': DateTime.now(),
        'nota': nota,
      });
      
      print('Servicio asignado a $codigoTaxi en $paradaId');
    } catch (e) {
      print('Error al asignar servicio: $e');
      rethrow;
    }
  }

  // Actualizar cola completa (para intercambios de posición)
  Future<void> actualizarCola(String paradaId, List<TaxiEnCola> taxisEnCola) async {
    try {
      // Guardar en la nueva estructura
      final taxisEnColaMap = taxisEnCola.map((taxi) => taxi.toMap()).toList();
      
      await _firestore.collection(_collectionName).doc(paradaId).update({
        'taxisEnCola': taxisEnColaMap,
      });
      
      print('Cola $paradaId actualizada correctamente');
    } catch (e) {
      print('Error al actualizar cola $paradaId: $e');
      rethrow;
    }
  }

  // Método para convertir la estructura antigua de datos a la nueva
  List<TaxiEnCola> _convertirEstructuraAntigua(Map<String, dynamic> data) {
    try {
      // Si ya tiene la estructura nueva, usarla directamente
      if (data.containsKey('taxisEnCola')) {
        final taxisData = data['taxisEnCola'];
        if (taxisData is List) {
          return taxisData.map((x) {
            try {
              // Convertir el timestamp si es necesario
              Map<String, dynamic> taxiMap = Map<String, dynamic>.from(x);
              if (taxiMap['timestamp'] is Timestamp) {
                taxiMap['timestamp'] = (taxiMap['timestamp'] as Timestamp).toDate();
              }
              return TaxiEnCola.fromMap(taxiMap);
            } catch (e) {
              print('Error convirtiendo taxi individual: $e');
              return null;
            }
          }).where((taxi) => taxi != null).cast<TaxiEnCola>().toList();
        }
        return [];
      }
      
      // Si tiene la estructura antigua, convertirla
      if (data.containsKey('orden') && data.containsKey('taxis')) {
        final orden = List<String>.from(data['orden'] ?? []);
        final taxis = List<Map<String, dynamic>>.from(data['taxis'] ?? []);
        
        List<TaxiEnCola> taxisEnCola = [];
        for (int i = 0; i < orden.length; i++) {
          try {
            final codigoTaxi = orden[i];
            final taxiData = taxis.firstWhere(
              (taxi) => taxi['id'] == codigoTaxi,
              orElse: () => {'id': codigoTaxi, 'timestamp': DateTime.now()},
            );
            
            taxisEnCola.add(TaxiEnCola(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
              codigoTaxi: codigoTaxi,
              timestamp: taxiData['timestamp'] is Timestamp 
                  ? (taxiData['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
            ));
          } catch (e) {
            print('Error convirtiendo taxi en posición $i: $e');
            continue;
          }
        }
        return taxisEnCola;
      }
      
      return [];
    } catch (e) {
      print('Error convirtiendo estructura de datos: $e');
      return [];
    }
  }

  // Métodos auxiliares para obtener nombres y ubicaciones de paradas
  String _getNombreParada(String paradaId) {
    switch (paradaId) {
      case 'hospital_mollet':
        return 'Hospital de Mollet';
      case 'avenida_libertad':
        return 'Avenida Libertad';
      case 'estacion_mollet':
        return 'Estación Mollet-San Fost';
      default:
        return 'Parada $paradaId';
    }
  }

  String _getUbicacionParada(String paradaId) {
    switch (paradaId) {
      case 'hospital_mollet':
        return 'Carrer de l\'Hospital, Mollet del Vallès';
      case 'avenida_libertad':
        return 'Avinguda de la Llibertat, Mollet del Vallès';
      case 'estacion_mollet':
        return 'Estació de Mollet-Sant Fost, Mollet del Vallès';
      default:
        return 'Mollet del Vallès';
    }
  }
} 