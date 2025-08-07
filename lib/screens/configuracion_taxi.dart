import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class ConfiguracionTaxi extends StatefulWidget {
  const ConfiguracionTaxi({super.key});

  @override
  State<ConfiguracionTaxi> createState() => _ConfiguracionTaxiState();
}

class _ConfiguracionTaxiState extends State<ConfiguracionTaxi> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _guardarCodigo() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await PreferencesService.guardarCodigoTaxi(_codigoController.text.trim());
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar el código: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      appBar: AppBar(
        title: Text(
          'Configurar Taxi',
          style: TextStyle(
            color: const Color(0xFF584130),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFF8F6F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF584130)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                // Icono y título
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_taxi,
                        size: 64,
                        color: const Color(0xFF584130),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Configura tu taxi',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF584130),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Introduce tu código de taxi',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFFBDA697),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Campo de código
                TextFormField(
                  controller: _codigoController,
                  decoration: InputDecoration(
                    labelText: 'Código de taxi',
                    hintText: 'Ej: M1, M2, M12...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.confirmation_number),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, introduce tu código de taxi';
                    }
                    if (value.trim().length < 2) {
                      return 'El código debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                ),
                
                const SizedBox(height: 24),
                
                // Información adicional
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E1DA),
                    borderRadius: BorderRadius.circular(12),
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
                        child: Text(
                          'Este código te identificará en las colas. Asegúrate de usar un código único.',
                          style: TextStyle(
                            color: const Color(0xFF584130),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Botón guardar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _guardarCodigo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA28C7D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.save, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Guardar y continuar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 