import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/taxista.dart';
import 'preferences_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream del usuario actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Iniciar sesión
  Future<UserCredential> iniciarSesion(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Obtener datos del taxista y guardar localmente
      if (result.user != null) {
        await _cargarDatosTaxista(result.user!.uid);
      }
      
      return result;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      rethrow;
    }
  }

  // Registrar nuevo taxista
  Future<UserCredential> registrarTaxista(String email, String password, String idTaxi) async {
    try {
      // Verificar que el ID de taxi no esté en uso
      bool idTaxiDisponible = await _verificarIdTaxiDisponible(idTaxi);
      if (!idTaxiDisponible) {
        throw Exception('El ID de taxi $idTaxi ya está en uso');
      }

      // Crear usuario en Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento del taxista en Firestore
      if (result.user != null) {
        Taxista taxista = Taxista(
          uid: result.user!.uid,
          idTaxi: idTaxi,
          email: email,
          fechaRegistro: DateTime.now(),
        );

        await _firestore
            .collection('taxistas')
            .doc(result.user!.uid)
            .set(taxista.toMap());

        // Guardar datos localmente
        await PreferencesService.guardarCodigoTaxi(idTaxi);
        await PreferencesService.guardarEmailTaxista(email);
      }

      return result;
    } catch (e) {
      print('Error al registrar taxista: $e');
      rethrow;
    }
  }

  // Verificar si un ID de taxi está disponible
  Future<bool> _verificarIdTaxiDisponible(String idTaxi) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('taxistas')
          .where('idTaxi', isEqualTo: idTaxi)
          .get();
      
      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error al verificar ID de taxi: $e');
      return false;
    }
  }

  // Cargar datos del taxista y guardar localmente
  Future<void> _cargarDatosTaxista(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('taxistas')
          .doc(uid)
          .get();

      if (doc.exists) {
        Taxista taxista = Taxista.fromMap(doc.data() as Map<String, dynamic>, uid);
        await PreferencesService.guardarCodigoTaxi(taxista.idTaxi);
        await PreferencesService.guardarEmailTaxista(taxista.email);
      }
    } catch (e) {
      print('Error al cargar datos del taxista: $e');
    }
  }

  // Obtener datos del taxista actual
  Future<Taxista?> obtenerTaxistaActual() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('taxistas')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return Taxista.fromMap(doc.data() as Map<String, dynamic>, user.uid);
      }
      return null;
    } catch (e) {
      print('Error al obtener taxista actual: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    try {
      await _auth.signOut();
      await PreferencesService.limpiarDatosTaxista();
    } catch (e) {
      print('Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // Verificar si el usuario está autenticado
  bool get estaAutenticado => _auth.currentUser != null;

  // Obtener ID de taxi del usuario actual
  Future<String?> obtenerIdTaxiActual() async {
    try {
      Taxista? taxista = await obtenerTaxistaActual();
      return taxista?.idTaxi;
    } catch (e) {
      print('Error al obtener ID de taxi actual: $e');
      return null;
    }
  }

  // Verificar si el usuario es de la sede
  bool esUsuarioSede() {
    User? user = _auth.currentUser;
    return user?.email == 'central@radiotaxi.com';
  }

  // Obtener el rol del usuario actual
  String obtenerRolUsuario() {
    if (esUsuarioSede()) {
      return 'sede';
    }
    return 'taxista';
  }

  // Cambiar contraseña
  Future<void> cambiarContrasena(String nuevaContrasena) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(nuevaContrasena);
      }
    } catch (e) {
      print('Error al cambiar contraseña: $e');
      rethrow;
    }
  }

  // Enviar email de restablecimiento de contraseña
  Future<void> enviarEmailRestablecimiento(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error al enviar email de restablecimiento: $e');
      rethrow;
    }
  }

  // Guardar datos del taxista localmente
  Future<void> guardarDatosTaxistaLocalmente(String idTaxi, String telefono) async {
    try {
      await PreferencesService.guardarCodigoTaxi(idTaxi);
      await PreferencesService.guardarTelefonoTaxista(telefono);
    } catch (e) {
      print('Error al guardar datos localmente: $e');
      rethrow;
    }
  }

  // Obtener ID de taxi por teléfono
  Future<String?> obtenerIdTaxiPorTelefono(String telefono) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('taxistas')
          .where('telefono', isEqualTo: telefono)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return data['idTaxi'] as String?;
      }
      return null;
    } catch (e) {
      print('Error al obtener ID de taxi por teléfono: $e');
      return null;
    }
  }
} 