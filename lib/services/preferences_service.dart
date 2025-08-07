import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _codigoTaxiKey = 'codigo_taxi';
  static const String _emailTaxistaKey = 'email_taxista';
  static const String _telefonoTaxistaKey = 'telefono_taxista';
  static const String _nombreTaxistaKey = 'nombre_taxista';

  // Guardar código de taxi
  static Future<void> guardarCodigoTaxi(String codigoTaxi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codigoTaxiKey, codigoTaxi);
  }

  // Obtener código de taxi
  static Future<String?> obtenerCodigoTaxi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_codigoTaxiKey);
  }

  // Verificar si ya se ha configurado el código de taxi
  static Future<bool> tieneCodigoTaxi() async {
    final codigo = await obtenerCodigoTaxi();
    return codigo != null && codigo.isNotEmpty;
  }

  // Limpiar código de taxi
  static Future<void> limpiarCodigoTaxi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codigoTaxiKey);
  }

  // Guardar email del taxista
  static Future<void> guardarEmailTaxista(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailTaxistaKey, email);
  }

  // Obtener email del taxista
  static Future<String?> obtenerEmailTaxista() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailTaxistaKey);
  }

  // Guardar teléfono del taxista
  static Future<void> guardarTelefonoTaxista(String telefono) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_telefonoTaxistaKey, telefono);
  }

  // Obtener teléfono del taxista
  static Future<String?> obtenerTelefonoTaxista() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_telefonoTaxistaKey);
  }

  // Guardar nombre del taxista
  static Future<void> guardarNombreTaxista(String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nombreTaxistaKey, nombre);
  }

  // Obtener nombre del taxista
  static Future<String?> obtenerNombreTaxista() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nombreTaxistaKey);
  }

  // Limpiar todos los datos del taxista
  static Future<void> limpiarDatosTaxista() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_codigoTaxiKey);
    await prefs.remove(_emailTaxistaKey);
    await prefs.remove(_telefonoTaxistaKey);
    await prefs.remove(_nombreTaxistaKey);
  }
} 