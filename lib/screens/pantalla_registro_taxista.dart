import 'package:flutter/material.dart';
import '../services/taxista_auth_service.dart';
import '../services/preferences_service.dart';
import 'pantalla_seleccion_parada.dart';

class PantallaRegistroTaxista extends StatefulWidget {
  const PantallaRegistroTaxista({super.key});

  @override
  State<PantallaRegistroTaxista> createState() => _PantallaRegistroTaxistaState();
}

class _PantallaRegistroTaxistaState extends State<PantallaRegistroTaxista> {
  final _formKey = GlobalKey<FormState>();
  final _codigoTaxiController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final TaxistaAuthService _authService = TaxistaAuthService();
  
  bool _estaCargando = false;
  bool _registroCompletado = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;
  String? _codigoTaxiSeleccionado;
  
  // Lista de códigos de taxi disponibles
  final List<String> _codigosTaxiDisponibles = List.generate(99, (index) => 'M${(index + 1).toString().padLeft(2, '0')}');

  @override
  void initState() {
    super.initState();
    // Pre-llenar con el número de teléfono del usuario
    _telefonoController.text = '621 03 35 28';
  }

  @override
  void dispose() {
    _codigoTaxiController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f6f3),
      appBar: AppBar(
        title: const Text(
          'Registro de Taxista',
          style: TextStyle(
            color: Color(0xFF584130),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF584130)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFf8f6f3)],
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
                              colors: [const Color(0xFFa28c7d), const Color(0xFF8b7a6b)],
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
                            Icons.person_add,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Registro de Taxista',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF584130),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crea tu cuenta de taxista',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFbda697),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        if (!_registroCompletado) ...[
                          _buildFormularioRegistro(),
                        ] else ...[
                          _buildRegistroCompletado(),
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

  Widget _buildFormularioRegistro() {
    return Column(
      children: [
        // Código de taxi
        const Text(
          'Código de taxi',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF584130),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _codigoTaxiSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Selecciona tu código',
            prefixIcon: Icon(Icons.local_taxi, color: Color(0xFFa28c7d)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFa28c7d), width: 2),
            ),
          ),
          items: _codigosTaxiDisponibles.map((String codigo) {
            return DropdownMenuItem<String>(
              value: codigo,
              child: Text(codigo),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _codigoTaxiSeleccionado = newValue;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor selecciona un código de taxi';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Nombre
        const Text(
          'Nombre completo',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF584130),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Tu nombre completo',
            prefixIcon: Icon(Icons.person, color: Color(0xFFa28c7d)),
            hintText: 'Juan Pérez García',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFa28c7d), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            if (value.length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Teléfono
        const Text(
          'Número de teléfono',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF584130),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _telefonoController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Número de teléfono',
            prefixIcon: Icon(Icons.phone, color: Color(0xFFa28c7d)),
            prefixText: '+34 ',
            hintText: '621 03 35 28',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFa28c7d), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu número de teléfono';
            }
            final numeroLimpio = value.replaceAll(RegExp(r'[^\d]'), '');
            if (numeroLimpio.length < 9) {
              return 'El número debe tener al menos 9 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Contraseña
        const Text(
          'Contraseña',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF584130),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_mostrarPassword,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            prefixIcon: const Icon(Icons.lock, color: Color(0xFFa28c7d)),
            suffixIcon: IconButton(
              icon: Icon(
                _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFFa28c7d),
              ),
              onPressed: () {
                setState(() {
                  _mostrarPassword = !_mostrarPassword;
                });
              },
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFa28c7d), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa una contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Confirmar contraseña
        const Text(
          'Confirmar contraseña',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF584130),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_mostrarConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirma tu contraseña',
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFa28c7d)),
            suffixIcon: IconButton(
              icon: Icon(
                _mostrarConfirmPassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFFa28c7d),
              ),
              onPressed: () {
                setState(() {
                  _mostrarConfirmPassword = !_mostrarConfirmPassword;
                });
              },
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFa28c7d), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor confirma tu contraseña';
            }
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Botón de registro
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _estaCargando ? null : _registrarTaxista,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFa28c7d),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
                    'Registrarse',
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

  Widget _buildRegistroCompletado() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          '¡Registro completado!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF584130),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Tu cuenta $_codigoTaxiSeleccionado ha sido creada exitosamente',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFbda697),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _continuarAApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFa28c7d),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continuar a la aplicación',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _registrarTaxista() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaCargando = true;
    });

    try {
      // Limpiar el número de teléfono
      final numeroLimpio = _telefonoController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
      final numeroTelefono = '+34$numeroLimpio';
      
      await _authService.registrarTaxista(
        _codigoTaxiSeleccionado!,
        _nombreController.text.trim(),
        numeroTelefono,
        _passwordController.text,
      );
      
      setState(() {
        _registroCompletado = true;
        _estaCargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro completado exitosamente'),
          backgroundColor: Colors.green,
        ),
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

  Future<void> _continuarAApp() async {
    try {
      // Guardar la información localmente
      await PreferencesService.guardarCodigoTaxi(_codigoTaxiSeleccionado!);
      await PreferencesService.guardarTelefonoTaxista(_telefonoController.text.trim());

      if (mounted) {
        // Navegar a la pantalla de selección de parada
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PantallaSeleccionParada(),
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
} 