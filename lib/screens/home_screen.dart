import 'package:flutter/material.dart';
import 'pantalla_login_simple.dart';
import 'pantalla_seleccion_parada.dart';
import '../services/preferences_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final codigoTaxi = await PreferencesService.obtenerCodigoTaxi();
      final telefono = await PreferencesService.obtenerTelefonoTaxista();
      
      setState(() {
        _isAuthenticated = codigoTaxi != null && codigoTaxi.isNotEmpty && telefono != null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_taxi,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Taxi Mollet del Vallès',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_isAuthenticated) {
      return const PantallaSeleccionParada();
    } else {
      return const PantallaLoginSimple();
    }
  }
} 