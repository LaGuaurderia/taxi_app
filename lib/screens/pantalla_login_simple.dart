import 'package:flutter/material.dart';
import '../services/taxista_auth_service.dart';
import '../services/preferences_service.dart';
import 'pantalla_seleccion_parada.dart';
import 'pantalla_autenticacion.dart';

class PantallaLoginSimple extends StatefulWidget {
  const PantallaLoginSimple({super.key});

  @override
  State<PantallaLoginSimple> createState() => _PantallaLoginSimpleState();
}

class _PantallaLoginSimpleState extends State<PantallaLoginSimple> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final TaxistaAuthService _authService = TaxistaAuthService();
  
  bool _estaCargando = false;
  bool _mostrarPassword = false;
  String? _codigoTaxiSeleccionado;
  
  // Lista de códigos de taxi disponibles
  final List<String> _codigosTaxiDisponibles = List.generate(99, (index) => 'M${(index + 1).toString().padLeft(2, '0')}');

  @override
  void initState() {
    super.initState();
    // Cargar código de taxi guardado si existe
    _cargarCodigoTaxiGuardado();
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _cargarCodigoTaxiGuardado() async {
    try {
      final codigoGuardado = await PreferencesService.obtenerCodigoTaxi();
      final telefonoGuardado = await PreferencesService.obtenerTelefonoTaxista();
      
      if (codigoGuardado != null && codigoGuardado.isNotEmpty) {
        setState(() {
          _codigoTaxiSeleccionado = codigoGuardado;
        });
        print('Código de taxi cargado: $codigoGuardado');
      }
      
      if (telefonoGuardado != null && telefonoGuardado.isNotEmpty) {
        // Limpiar el +34 si existe y guardar solo el número
        final numeroLimpio = telefonoGuardado.replaceAll('+34', '').trim();
        _telefonoController.text = numeroLimpio;
        print('Teléfono cargado: $numeroLimpio');
      }
    } catch (e) {
      print('Error cargando datos guardados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f6f3),
      body: SafeArea(
        child: Container(
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
                              color: Color(0xFF584130),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFFbda697),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          _buildFormularioLogin(),
                        ],
                      ),
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

  Widget _buildFormularioLogin() {
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
        
        // Dropdown mejorado
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFa28c7d)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _codigoTaxiSeleccionado,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFa28c7d)),
              hint: const Text(
                'Selecciona tu código',
                style: TextStyle(color: Color(0xFF584130)),
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                color: Color(0xFF584130),
                fontSize: 16,
              ),
              items: _codigosTaxiDisponibles.map((String codigo) {
                return DropdownMenuItem<String>(
                  value: codigo,
                  child: Row(
                    children: [
                      const Icon(Icons.local_taxi, color: Color(0xFFa28c7d), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        codigo,
                        style: const TextStyle(color: Color(0xFF584130)),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                print('Dropdown cambiado a: $newValue');
                setState(() {
                  _codigoTaxiSeleccionado = newValue;
                });
              },
            ),
          ),
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
                        hintText: '621033528',
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
              return 'Por favor ingresa tu contraseña';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),

        // Botón de login
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _estaCargando ? null : _iniciarSesion,
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
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Botón para ir a registro
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const PantallaAutenticacion(),
              ),
            );
          },
          child: const Text(
            '¿No tienes cuenta? Regístrate aquí',
            style: TextStyle(
              color: Color(0xFFa28c7d),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Botón para crear cuenta M99 rápidamente
        if (_codigoTaxiSeleccionado == 'M99')
          ElevatedButton(
            onPressed: _crearCuentaM99,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFbda697),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Crear cuenta M99 con datos por defecto',
              style: TextStyle(fontSize: 14),
            ),
          ),
      ],
    );
  }

  Future<void> _crearCuentaM99() async {
    setState(() {
      _estaCargando = true;
    });

    try {
      print('Creando cuenta M99 con datos por defecto');
      
      await _authService.registrarTaxista(
        'M99',
        'Taxista Demo',
        '+34657281635',
        'demo1234',
      );
      
      setState(() {
        _estaCargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta M99 creada exitosamente. Ahora puedes hacer login.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _estaCargando = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando cuenta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_codigoTaxiSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona tu código de taxi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _estaCargando = true;
    });

    try {
      print('Intentando login con código: $_codigoTaxiSeleccionado');
      
      final taxista = await _authService.autenticarTaxista(
        _codigoTaxiSeleccionado!,
        _passwordController.text,
      );
      
      if (taxista != null) {
        // Guardar la información localmente
        await PreferencesService.guardarCodigoTaxi(_codigoTaxiSeleccionado!);
        await PreferencesService.guardarTelefonoTaxista(_telefonoController.text.trim());
        
        // Guardar también el nombre para mostrar en futuras sesiones
        await PreferencesService.guardarNombreTaxista(taxista.nombre);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bienvenido ${taxista.nombre}'),
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
      } else {
        throw Exception('Credenciales incorrectas');
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
} 