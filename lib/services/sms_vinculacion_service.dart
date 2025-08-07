import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/taxista_vinculado.dart';

class SmsVinculacionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Colección para almacenar las vinculaciones de SMS
  static const String _vinculacionesCollection = 'vinculaciones_sms';
  static const String _taxistasCollection = 'taxistas';

  /// Enviar SMS de vinculación para un código de taxi específico
  Future<void> enviarSmsVinculacion(String codigoTaxi, String numeroTelefono) async {
    try {
      print('📱 Enviando SMS de vinculación para $codigoTaxi al $numeroTelefono');
      
      // Validar y formatear el número de teléfono
      final numeroFormateado = _formatearNumeroTelefono(numeroTelefono);
      print('📱 Número formateado: $numeroFormateado');
      
      // Verificar que el código de taxi existe y no está ya vinculado
      final taxistaExistente = await _verificarTaxistaExistente(codigoTaxi);
      
      if (taxistaExistente != null) {
        throw Exception('El código de taxi $codigoTaxi ya está vinculado a otro número');
      }

      // Generar código de verificación único
      final codigoVerificacion = _generarCodigoVerificacion();
      
      // Guardar la solicitud de vinculación en Firestore
      await _guardarSolicitudVinculacion(codigoTaxi, numeroFormateado, codigoVerificacion);
      
      // Enviar SMS usando Firebase Auth (simulado para desarrollo)
      await _enviarSmsFirebase(numeroFormateado, codigoVerificacion, codigoTaxi);
      
      print('✅ Solicitud de vinculación enviada correctamente');
      
    } catch (e) {
      print('❌ Error enviando SMS de vinculación: $e');
      rethrow;
    }
  }

  /// Verificar código de vinculación y completar el proceso
  Future<void> verificarCodigoVinculacion(String codigoTaxi, String numeroTelefono, String codigoVerificacion) async {
    try {
      print('🔍 Verificando código de vinculación para $codigoTaxi');
      
      // Validar y formatear el número de teléfono
      final numeroFormateado = _formatearNumeroTelefono(numeroTelefono);
      print('📱 Número formateado para verificación: $numeroFormateado');
      
      // Buscar la solicitud de vinculación
      final solicitud = await _buscarSolicitudVinculacion(codigoTaxi, numeroFormateado);
      
      if (solicitud == null) {
        throw Exception('No se encontró una solicitud de vinculación válida');
      }
      
      if (solicitud['codigoVerificacion'] != codigoVerificacion) {
        throw Exception('Código de verificación incorrecto');
      }
      
      // Verificar que no haya expirado (15 minutos)
      final timestamp = solicitud['timestamp'] as Timestamp;
      final ahora = DateTime.now();
      final diferencia = ahora.difference(timestamp.toDate());
      
      if (diferencia.inMinutes > 15) {
        throw Exception('El código de verificación ha expirado');
      }
      
      // Completar la vinculación
      await _completarVinculacion(codigoTaxi, numeroFormateado);
      
      // Eliminar la solicitud temporal
      await _eliminarSolicitudVinculacion(codigoTaxi, numeroFormateado);
      
      print('✅ Vinculación completada exitosamente');
      
    } catch (e) {
      print('❌ Error verificando código de vinculación: $e');
      rethrow;
    }
  }

  /// Obtener información del taxista vinculado
  Future<TaxistaVinculado?> obtenerTaxistaVinculado(String codigoTaxi) async {
    try {
      final doc = await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return TaxistaVinculado.fromMap(data, codigoTaxi);
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo taxista vinculado: $e');
      return null;
    }
  }

  /// Verificar si un número de teléfono ya está vinculado
  Future<bool> verificarTelefonoVinculado(String numeroTelefono) async {
    try {
      final query = await _firestore
          .collection(_taxistasCollection)
          .where('numeroTelefono', isEqualTo: numeroTelefono)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando teléfono vinculado: $e');
      return false;
    }
  }

  /// Desvincular un taxista
  Future<void> desvincularTaxista(String codigoTaxi) async {
    try {
      await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .delete();
      
      print('✅ Taxista $codigoTaxi desvinculado correctamente');
    } catch (e) {
      print('❌ Error desvinculando taxista: $e');
      rethrow;
    }
  }

  // Métodos privados

  Future<TaxistaVinculado?> _verificarTaxistaExistente(String codigoTaxi) async {
    try {
      final doc = await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return TaxistaVinculado.fromMap(data, codigoTaxi);
      }
      
      return null;
    } catch (e) {
      print('❌ Error verificando taxista existente: $e');
      return null;
    }
  }

  String _generarCodigoVerificacion() {
    // Generar código de 6 dígitos
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  String _formatearNumeroTelefono(String numeroTelefono) {
    // Limpiar el número de teléfono
    String numeroLimpio = numeroTelefono.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si ya tiene el prefijo +34, devolverlo tal como está
    if (numeroTelefono.startsWith('+34')) {
      return numeroTelefono;
    }
    
    // Si tiene 9 dígitos (número español), agregar +34
    if (numeroLimpio.length == 9) {
      return '+34$numeroLimpio';
    }
    
    // Si tiene 11 dígitos y empieza con 34, agregar +
    if (numeroLimpio.length == 11 && numeroLimpio.startsWith('34')) {
      return '+$numeroLimpio';
    }
    
    // Si tiene 12 dígitos y empieza con 34, agregar +
    if (numeroLimpio.length == 12 && numeroLimpio.startsWith('34')) {
      return '+$numeroLimpio';
    }
    
    // Si no coincide con ningún formato, intentar con +34
    if (numeroLimpio.length >= 9) {
      return '+34${numeroLimpio.substring(numeroLimpio.length - 9)}';
    }
    
    throw Exception('Formato de número de teléfono inválido: $numeroTelefono');
  }

  Future<void> _guardarSolicitudVinculacion(String codigoTaxi, String numeroTelefono, String codigoVerificacion) async {
    await _firestore
        .collection(_vinculacionesCollection)
        .doc('${codigoTaxi}_$numeroTelefono')
        .set({
      'codigoTaxi': codigoTaxi,
      'numeroTelefono': numeroTelefono,
      'codigoVerificacion': codigoVerificacion,
      'timestamp': DateTime.now(),
      'verificado': false,
    });
  }

  Future<Map<String, dynamic>?> _buscarSolicitudVinculacion(String codigoTaxi, String numeroTelefono) async {
    final doc = await _firestore
        .collection(_vinculacionesCollection)
        .doc('${codigoTaxi}_$numeroTelefono')
        .get();
    
    if (doc.exists) {
      return doc.data();
    }
    
    return null;
  }

  Future<void> _completarVinculacion(String codigoTaxi, String numeroTelefono) async {
    await _firestore
        .collection(_taxistasCollection)
        .doc(codigoTaxi)
        .set({
      'codigoTaxi': codigoTaxi,
      'numeroTelefono': numeroTelefono,
      'fechaVinculacion': DateTime.now(),
      'activo': true,
      'ultimaActividad': DateTime.now(),
    });
  }

  Future<void> _eliminarSolicitudVinculacion(String codigoTaxi, String numeroTelefono) async {
    await _firestore
        .collection(_vinculacionesCollection)
        .doc('${codigoTaxi}_$numeroTelefono')
        .delete();
  }

  Future<void> _enviarSmsFirebase(String numeroTelefono, String codigoVerificacion, String codigoTaxi) async {
    try {
      // SOLUCIÓN TEMPORAL: Simular envío de SMS sin Firebase Auth
      // En producción, esto se conectaría con un servicio de SMS real
      
      print('📲 SIMULANDO envío de SMS para $codigoTaxi');
      print('📱 Código de verificación: $codigoVerificacion');
      print('📱 Número: $numeroTelefono');
      print('📱 NOTA: Este es un modo de desarrollo. En producción se enviaría un SMS real.');
      
      // Simular delay de envío
      await Future.delayed(const Duration(seconds: 2));
      
      print('✅ SMS simulado enviado exitosamente');
      
      // NOTA: Para habilitar SMS real, necesitas:
      // 1. Habilitar Phone Authentication en Firebase Console
      // 2. Configurar SHA-1 fingerprint en Firebase
      // 3. Habilitar facturación en Google Cloud
      
    } catch (e) {
      print('❌ Error en envío de SMS simulado: $e');
      rethrow;
    }
  }
} 