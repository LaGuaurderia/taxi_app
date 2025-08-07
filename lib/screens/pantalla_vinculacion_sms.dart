import 'package:flutter/material.dart';
import '../services/sms_vinculacion_service.dart';
import '../services/preferences_service.dart';
import 'pantalla_seleccion_parada.dart';

class PantallaVinculacionSMS extends StatefulWidget {
  const PantallaVinculacionSMS({super.key});

  @override
  State<PantallaVinculacionSMS> createState() => _PantallaVinculacionSMSState();
}

class _PantallaVinculacionSMSState extends State<PantallaVinculacionSMS> {
  final _formKey = GlobalKey<FormState>();
  final _codigoTaxiController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _codigoVerificacionController = TextEditingController();
  
  final SmsVinculacionService _smsService = SmsVinculacionService();
  
  bool _estaCargando = false;
  bool _codigoEnviado = false;
  bool _vinculacionCompletada = false;
  String? _codigoTaxiSeleccionado;
  String? _telefonoVerificado;
  
  // Lista de códigos de taxi disponibles
  final List<String> _codigosTaxiDisponibles = List.generate(99, (index) => 'M${(index + 1).toString().padLeft(2, '0')}');

  @override
  void initState() {
    super.initState();
    // Pre-llenar con el número de teléfono del usuario (sin +34)
    _telefonoController.text = '621 03 35 28';
  }

  @override
  void dispose() {
    _codigoTaxiController.dispose();
    _telefonoController.dispose();
    _codigoVerificacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f6f3),
      appBar: AppBar(
        title: const Text(
          'Vinculación SMS',
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
                            Icons.sms,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Vinculación por SMS',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF584130),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vincular código de taxi con tu teléfono',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFbda697),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        if (!_vinculacionCompletada) ...[
                          // Paso 1: Selección de código de taxi
                          if (!_codigoEnviado) ...[
                            _buildSeleccionCodigoTaxi(),
                          ] else ...[
                            // Paso 2: Verificación de código
                            _buildVerificacionCodigo(),
                          ],
                        ] else ...[
                          // Paso 3: Vinculación completada
                          _buildVinculacionCompletada(),
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

  Widget _buildSeleccionCodigoTaxi() {
    return Column(
      children: [
        const Text(
          'Selecciona tu código de taxi',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF584130),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _codigoTaxiSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Código de Taxi',
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
            // Limpiar espacios y caracteres especiales
            final numeroLimpio = value.replaceAll(RegExp(r'[^\d]'), '');
            if (numeroLimpio.length < 9) {
              return 'El número debe tener al menos 9 dígitos';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _estaCargando ? null : _enviarCodigoVinculacion,
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
                    'Enviar código de vinculación',
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

  Widget _buildVerificacionCodigo() {
    return Column(
      children: [
        const Text(
          'Código de verificación',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF584130),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Se ha enviado un SMS al +34 ${_telefonoController.text}',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFbda697),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _codigoVerificacionController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Código de 6 dígitos',
            prefixIcon: Icon(Icons.security, color: Color(0xFFa28c7d)),
            hintText: '123456',
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
                onPressed: _estaCargando ? null : _reenviarCodigoVinculacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                onPressed: _estaCargando ? null : _verificarCodigoVinculacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFa28c7d),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  Widget _buildVinculacionCompletada() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          '¡Vinculación completada!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF584130),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Tu código $_codigoTaxiSeleccionado ha sido vinculado exitosamente con tu teléfono $_telefonoVerificado',
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

  Future<void> _enviarCodigoVinculacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaCargando = true;
    });

    try {
      // Limpiar el número de teléfono y formatearlo correctamente
      final numeroLimpio = _telefonoController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
      final numeroTelefono = '+34$numeroLimpio';
      
      print('📱 Enviando SMS a: $numeroTelefono');
      
      await _smsService.enviarSmsVinculacion(_codigoTaxiSeleccionado!, numeroTelefono);
      
      setState(() {
        _codigoEnviado = true;
        _estaCargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código de vinculación enviado al teléfono'),
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

  Future<void> _verificarCodigoVinculacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _estaCargando = true;
    });

    try {
      // Limpiar el número de teléfono y formatearlo correctamente
      final numeroLimpio = _telefonoController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
      final numeroTelefono = '+34$numeroLimpio';
      final codigoVerificacion = _codigoVerificacionController.text.trim();
      
      await _smsService.verificarCodigoVinculacion(
        _codigoTaxiSeleccionado!,
        numeroTelefono,
        codigoVerificacion,
      );
      
      setState(() {
        _vinculacionCompletada = true;
        _telefonoVerificado = numeroTelefono;
        _estaCargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vinculación completada exitosamente'),
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

  Future<void> _reenviarCodigoVinculacion() async {
    setState(() {
      _estaCargando = true;
    });

    try {
      // Limpiar el número de teléfono y formatearlo correctamente
      final numeroLimpio = _telefonoController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
      final numeroTelefono = '+34$numeroLimpio';
      
      await _smsService.enviarSmsVinculacion(_codigoTaxiSeleccionado!, numeroTelefono);
      
      setState(() {
        _estaCargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código reenviado'),
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
      await PreferencesService.guardarTelefonoTaxista(_telefonoVerificado!);

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