import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/taxista_registro.dart';

class TaxistaAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _taxistasCollection = 'taxistas_registro';

  /// Registrar un nuevo taxista
  Future<void> registrarTaxista(String codigoTaxi, String nombre, String numeroTelefono, String password) async {
    try {
      print('📝 Registrando taxista $codigoTaxi');
      
      // Verificar que el código de taxi no esté ya registrado
      final taxistaExistente = await _verificarTaxistaExistente(codigoTaxi);
      if (taxistaExistente != null) {
        throw Exception('El código de taxi $codigoTaxi ya está registrado');
      }

      // Verificar que el número de teléfono no esté ya registrado
      final telefonoExistente = await _verificarTelefonoExistente(numeroTelefono);
      if (telefonoExistente) {
        throw Exception('El número de teléfono ya está registrado');
      }

      // Generar hash de la contraseña
      final passwordHash = _generarPasswordHash(password);
      
      // Crear el registro del taxista
      final taxista = TaxistaRegistro(
        codigoTaxi: codigoTaxi,
        nombre: nombre,
        numeroTelefono: numeroTelefono,
        passwordHash: passwordHash,
        fechaRegistro: DateTime.now(),
        activo: true,
        ultimaActividad: DateTime.now(),
      );

      // Guardar en Firestore
      await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .set(taxista.toMap());

      print('✅ Taxista $codigoTaxi registrado exitosamente');
      
    } catch (e) {
      print('❌ Error registrando taxista: $e');
      rethrow;
    }
  }

  /// Autenticar un taxista
  Future<TaxistaRegistro?> autenticarTaxista(String codigoTaxi, String password) async {
    try {
      print('🔐 Autenticando taxista $codigoTaxi');
      
      // Buscar el taxista
      final doc = await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .get();
      
      if (!doc.exists) {
        print('❌ Taxista $codigoTaxi no encontrado');
        return null;
      }

      final data = doc.data()!;
      final taxista = TaxistaRegistro.fromMap(data, codigoTaxi);
      
      // Verificar si está activo
      if (!taxista.activo) {
        print('❌ Taxista $codigoTaxi está inactivo');
        return null;
      }

      // Verificar contraseña
      if (!_verificarPasswordHash(password, taxista.passwordHash)) {
        print('❌ Contraseña incorrecta para taxista $codigoTaxi');
        return null;
      }

      // Actualizar última actividad
      await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .update({
        'ultimaActividad': DateTime.now(),
      });

      print('✅ Taxista $codigoTaxi autenticado exitosamente');
      return taxista;
      
    } catch (e) {
      print('❌ Error autenticando taxista: $e');
      return null;
    }
  }

  /// Obtener información de un taxista
  Future<TaxistaRegistro?> obtenerTaxista(String codigoTaxi) async {
    try {
      final doc = await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return TaxistaRegistro.fromMap(data, codigoTaxi);
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo taxista: $e');
      return null;
    }
  }

  /// Cambiar contraseña
  Future<void> cambiarPassword(String codigoTaxi, String passwordActual, String nuevaPassword) async {
    try {
      print('🔑 Cambiando contraseña para taxista $codigoTaxi');
      
      // Verificar contraseña actual
      final taxista = await autenticarTaxista(codigoTaxi, passwordActual);
      if (taxista == null) {
        throw Exception('Contraseña actual incorrecta');
      }

      // Generar hash de la nueva contraseña
      final nuevaPasswordHash = _generarPasswordHash(nuevaPassword);
      
      // Actualizar en Firestore
      await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .update({
        'passwordHash': nuevaPasswordHash,
        'ultimaActividad': DateTime.now(),
      });

      print('✅ Contraseña cambiada exitosamente para taxista $codigoTaxi');
      
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      rethrow;
    }
  }

  /// Desactivar taxista
  Future<void> desactivarTaxista(String codigoTaxi) async {
    try {
      await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .update({
        'activo': false,
        'ultimaActividad': DateTime.now(),
      });
      
      print('✅ Taxista $codigoTaxi desactivado');
    } catch (e) {
      print('❌ Error desactivando taxista: $e');
      rethrow;
    }
  }

  /// Obtener todos los taxistas activos
  Stream<List<TaxistaRegistro>> getTaxistasActivos() {
    return _firestore
        .collection(_taxistasCollection)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaxistaRegistro.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Métodos privados

  Future<TaxistaRegistro?> _verificarTaxistaExistente(String codigoTaxi) async {
    try {
      final doc = await _firestore
          .collection(_taxistasCollection)
          .doc(codigoTaxi)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        return TaxistaRegistro.fromMap(data, codigoTaxi);
      }
      
      return null;
    } catch (e) {
      print('❌ Error verificando taxista existente: $e');
      return null;
    }
  }

  Future<bool> _verificarTelefonoExistente(String numeroTelefono) async {
    try {
      final query = await _firestore
          .collection(_taxistasCollection)
          .where('numeroTelefono', isEqualTo: numeroTelefono)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error verificando teléfono existente: $e');
      return false;
    }
  }

  String _generarPasswordHash(String password) {
    // Generar salt único
    final random = Random.secure();
    final salt = List<int>.generate(16, (i) => random.nextInt(256));
    
    // Combinar password con salt
    final bytes = utf8.encode(password + salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
    
    // Generar hash SHA-256
    final hash = sha256.convert(bytes);
    
    // Retornar salt + hash en formato hexadecimal
    return salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join() + hash.toString();
  }

  bool _verificarPasswordHash(String password, String storedHash) {
    try {
      // Extraer salt (primeros 32 caracteres)
      final saltHex = storedHash.substring(0, 32);
      final hashHex = storedHash.substring(32);
      
      // Convertir salt de hex a bytes
      final salt = List<int>.generate(16, (i) {
        final start = i * 2;
        return int.parse(saltHex.substring(start, start + 2), radix: 16);
      });
      
      // Generar hash con el mismo salt
      final bytes = utf8.encode(password + salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
      final hash = sha256.convert(bytes);
      
      // Comparar hashes
      return hash.toString() == hashHex;
    } catch (e) {
      print('❌ Error verificando hash de contraseña: $e');
      return false;
    }
  }
} 