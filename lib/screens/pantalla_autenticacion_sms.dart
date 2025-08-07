import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/preferences_service.dart';
import 'pantalla_seleccion_parada.dart';

class PantallaAutenticacionSMS extends StatefulWidget {
  const PantallaAutenticacionSMS({super.key});

  @override
  State<PantallaAutenticacionSMS> createState() => _PantallaAutenticacionSMSState();
}

class _PantallaAutenticacionSMSState extends State<PantallaAutenticacionSMS> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoController = TextEditingController();
  final _codigoController = TextEditingController();
  
  bool _estaCargando = false;
  bool _codigoEnviado = false;
  bool _verificacionCompletada = false;
  String? _telefonoVerificado;
  
  // Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;
  
  // Lista de IDs de taxi disponibles
  final List<String> _idsTaxiDisponibles = List.generate(32, (index) => 'M${index + 1}');
  String? _idTaxiSeleccionado;

  @override
  void dispose() {
    _telefonoController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF8F8F8)],
          ),
        ),
        child: Center(
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
                        // Logo y título
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF666666), const Color(0xFF555555)],
                            ),
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
                            Icons.local_taxi,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Taxi Mollet del Vallès',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Acceso Taxistas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Botón de acceso directo
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: ElevatedButton.icon(
                            onPressed: _estaCargando ? null : _accesoDirecto,
                            icon: const Icon(Icons.login, size: 20),
                            label: const Text(
                              'Entrar sin logearse',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF666666),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        
                        if (!_verificacionCompletada) ...[
                          // Paso 1: Ingreso de teléfono
                          if (!_codigoEnviado) ...[
                            _buildTelefonoStep(),
                          ] else ...[
                            // Paso 2: Verificación de código
                            _buildCodigoStep(),
                          ],
                        ] else ...[
                          // Paso 3: Selección de ID de taxi
                          _buildIdTaxiStep(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelefonoStep() {
    return Column(
      children: [
        const Text(
          'Ingresa tu número de teléfono',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telefonoController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Número de teléfono',
            prefixIcon: Icon(Icons.phone, color: Color(0xFF666666)),
            hintText: '621 03 35 28',
            prefixText: '+34 ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF666666), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu número de teléfono';
            }
            if (value.length < 9) {
              return 'El número debe tener al menos 9 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _estaCargando ? null : _enviarCodigo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF666666),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _estaCargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Enviar código',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodigoStep() {
    return Column(
      children: [
        const Text(
          'Código de verificación',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Se ha enviado un SMS al ${_telefonoController.text}',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Código de 6 dígitos',
            prefixIcon: Icon(Icons.security, color: Color(0xFF666666)),
            hintText: '123456',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF666666), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el código';
            }
            if (value.length != 6) {
              return 'El código debe tener 6 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _estaCargando ? null : _reenviarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Reenviar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _estaCargando ? null : _verificarCodigo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF666666),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _estaCargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verificar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIdTaxiStep() {
    return Column(
      children: [
        const Text(
          'Selecciona tu ID de taxi',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _idTaxiSeleccionado,
          decoration: const InputDecoration(
            labelText: 'ID de Taxi',
            prefixIcon: Icon(Icons.local_taxi, color: Color(0xFF666666)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF666666), width: 2),
            ),
          ),
          items: _idsTaxiDisponibles.map((String id) {
            return DropdownMenuItem<String>(
              value: id,
              child: Text(id),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _idTaxiSeleccionado = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona un ID de taxi';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _estaCargando ? null : _completarRegistro,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF666666),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _estaCargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Completar registro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _enviarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaCargando = true;
    });

    try {
      final numeroTelefono = _telefonoController.text.trim();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: numeroTelefono,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Verificación instantánea o auto-relleno por Google Play Services
          await _auth.signInWithCredential(credential);
          print("✅ Verificación completada automáticamente");
          
          setState(() {
            _verificacionCompletada = true;
            _telefonoVerificado = numeroTelefono;
            _estaCargando = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verificación completada automáticamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          print("❌ Error en la verificación: ${e.message}");
          
          setState(() {
            _estaCargando = false;
          });

          String mensajeError = 'Error en la verificación';
          if (e.code == 'invalid-phone-number') {
            mensajeError = 'Número de teléfono inválido';
            print('⚠️ Número de teléfono inválido');
          } else if (e.code == 'too-many-requests') {
            mensajeError = 'Cuota superada. Espera o usa modo prueba';
            print('🚫 Cuota superada. Espera o usa modo prueba');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensajeError),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          print("📲 Código enviado. ID de verificación: $verificationId");
          
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codigoEnviado = true;
            _estaCargando = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código enviado al teléfono'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("⏳ Tiempo de espera agotado para auto-rellenar código");
          setState(() {
            _estaCargando = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verificarCodigo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaCargando = true;
    });

    try {
      final codigoIngresado = _codigoController.text.trim();
      
      if (_verificationId == null) {
        throw Exception('No hay un ID de verificación válido. Envía el código primero.');
      }

      // Crear credencial con el código ingresado
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: codigoIngresado,
      );

      // Verificar el código con Firebase
      await _auth.signInWithCredential(credential);
      
      setState(() {
        _verificacionCompletada = true;
        _telefonoVerificado = _telefonoController.text;
        _estaCargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código verificado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      String mensajeError = 'Error verificando el código';
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-verification-code') {
          mensajeError = 'Código de verificación inválido';
        } else if (e.code == 'session-expired') {
          mensajeError = 'Sesión expirada. Envía el código nuevamente';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reenviarCodigo() async {
    setState(() {
      _estaCargando = true;
    });

    try {
      final numeroTelefono = _telefonoController.text.trim();
      
      await _auth.verifyPhoneNumber(
        phoneNumber: numeroTelefono,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          print("✅ Verificación completada automáticamente en reenvío");
          
          setState(() {
            _verificacionCompletada = true;
            _telefonoVerificado = numeroTelefono;
            _estaCargando = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verificación completada automáticamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          print("❌ Error en el reenvío: ${e.message}");
          
          setState(() {
            _estaCargando = false;
          });

          String mensajeError = 'Error en el reenvío';
          if (e.code == 'too-many-requests') {
            mensajeError = 'Demasiados intentos. Espera un momento';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensajeError),
              backgroundColor: Colors.red,
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          print("📲 Código reenviado. ID de verificación: $verificationId");
          
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _estaCargando = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código reenviado'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("⏳ Tiempo de espera agotado para auto-rellenar código");
          setState(() {
            _estaCargando = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaCargando = true;
    });

    try {
      // Guardar localmente
      await PreferencesService.guardarCodigoTaxi(_idTaxiSeleccionado!);
      await PreferencesService.guardarTelefonoTaxista(_telefonoVerificado!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro completado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navegar a la pantalla de selección de parada
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PantallaSeleccionParada(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para acceso directo sin autenticación
  Future<void> _accesoDirecto() async {
    setState(() {
      _estaCargando = true;
    });

    try {
      // Asignar un ID de taxi por defecto
      const idTaxiDesarrollo = 'M99';
      const telefonoDesarrollo = '+34 621 03 35 28';
      
      // Guardar localmente
      await PreferencesService.guardarCodigoTaxi(idTaxiDesarrollo);
      await PreferencesService.guardarTelefonoTaxista(telefonoDesarrollo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso exitoso sin autenticación'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navegar a la pantalla de selección de parada inmediatamente
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PantallaSeleccionParada(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      String mensaje = 'Error al acceder sin autenticación';
      if (e.toString().contains('network')) {
        mensaje = 'Error de conexión. Verifica tu internet';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
         }
   }
} 