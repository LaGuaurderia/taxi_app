import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/pantalla_login_sede.dart';
import 'screens/pantalla_sede_web.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SedeWebApp());
}

class SedeWebApp extends StatelessWidget {
  const SedeWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Taxi - Central',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF8F6F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F6F3),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF584130)),
          titleTextStyle: TextStyle(
            color: Color(0xFF584130),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFA28C7D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const SedeWebWrapper(),
    );
  }
}

class SedeWebWrapper extends StatelessWidget {
  const SedeWebWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F6F3),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA28C7D)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando Central Radio Taxi...',
                    style: TextStyle(
                      color: Color(0xFF584130),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasData) {
          // Usuario autenticado - verificar si es sede
          final authService = AuthService();
          if (authService.esUsuarioSede()) {
            // Usuario de sede - redirigir a pantalla de sede web
            return const PantallaSedeWeb();
          } else {
            // Usuario no autorizado - mostrar error
            return const PantallaNoAutorizado();
          }
        } else {
          // Usuario no autenticado - mostrar login
          return const PantallaLoginSede();
        }
      },
    );
  }
}

class PantallaNoAutorizado extends StatelessWidget {
  const PantallaNoAutorizado({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F3),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 24),
              const Text(
                'Acceso No Autorizado',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF584130),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Solo el personal autorizado de la sede puede acceder a este sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF584130),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 