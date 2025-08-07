import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  // Probar conexión inicial
  Future<void> _testConnection() async {
    try {
      print('🔍 Iniciando prueba de conexión con Firestore...');
      
      // Verificar que Firebase está inicializado
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase no está inicializado');
      }
      
      print('✅ Firebase está inicializado');
      
      // Probar conexión básica
      await _firestore.collection('debug_test').limit(1).get();
      
      print('✅ Conexión con Firestore exitosa');
      
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      print('❌ Error de conexión: $e');
      setState(() {
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  // Añadir nueva entrada
  Future<void> _addEntry() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Intentando añadir entrada a Firestore...');
      
      // Verificar Firebase antes de escribir
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase no está inicializado');
      }
      
      print('✅ Firebase verificado, escribiendo datos...');
      
      // Usar DateTime.now() en lugar de FieldValue.serverTimestamp() para evitar errores
      final docRef = await _firestore.collection('debug_test').add({
        'timestamp': DateTime.now(),
        'message': 'Prueba desde dispositivo real',
        'device': 'Android Real',
      });
      
      print('✅ Documento creado con ID: ${docRef.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Entrada añadida correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error al añadir entrada: $e');
      setState(() {
        _errorMessage = 'Error al añadir entrada: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Eliminar entrada
  Future<void> _deleteEntry(String documentId) async {
    try {
      await _firestore.collection('debug_test').doc(documentId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text('🗑️ Entrada eliminada'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Diagnóstico completo de Firebase
  Future<void> _runFullDiagnostic() async {
    print('🔍 === DIAGNÓSTICO COMPLETO DE FIREBASE ===');
    
    try {
      // 1. Verificar Firebase Core
      print('1. Verificando Firebase Core...');
      if (Firebase.apps.isEmpty) {
        print('❌ Firebase no está inicializado');
        setState(() {
          _errorMessage = 'Firebase no está inicializado';
        });
        return;
      }
      print('✅ Firebase Core está inicializado');
      
      // 2. Verificar Firestore
      print('2. Verificando Firestore...');
      await _firestore.collection('debug_test').limit(1).get();
      print('✅ Firestore está conectado');
      
      // 3. Probar escritura
      print('3. Probando escritura...');
      final docRef = await _firestore.collection('debug_test').add({
        'timestamp': DateTime.now(),
        'message': 'Diagnóstico automático',
        'device': 'Android Real',
        'test': true,
      });
      print('✅ Escritura exitosa - ID: ${docRef.id}');
      
      // 4. Probar lectura
      print('4. Probando lectura...');
      final doc = await docRef.get();
      print('✅ Lectura exitosa - Datos: ${doc.data()}');
      
      // 5. Probar eliminación
      print('5. Probando eliminación...');
      await docRef.delete();
      print('✅ Eliminación exitosa');
      
      print('🎉 DIAGNÓSTICO COMPLETO: TODO FUNCIONA CORRECTAMENTE');
      
      setState(() {
        _errorMessage = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('🎉 Diagnóstico completo: Todo OK'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('❌ ERROR EN DIAGNÓSTICO: $e');
      setState(() {
        _errorMessage = 'Error en diagnóstico: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Limpiar todas las entradas
  Future<void> _clearAllEntries() async {
    try {
      final querySnapshot = await _firestore.collection('debug_test').get();
      final batch = _firestore.batch();
      
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.clear_all, color: Colors.white),
                SizedBox(width: 8),
                Text('🧹 Todas las entradas eliminadas'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al limpiar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Firestore Test',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _runFullDiagnostic,
            tooltip: 'Diagnóstico completo',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testConnection,
            tooltip: 'Probar conexión',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllEntries,
            tooltip: 'Limpiar todas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mensaje de error
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Botón de añadir entrada centrado
          Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF888888),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Añadiendo...'),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline),
                          SizedBox(width: 8),
                          Text(
                            'Añadir entrada',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // Lista en tiempo real
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('debug_test')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error al cargar datos:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                final documents = snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          color: Colors.grey,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay entradas',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Añade una entrada para comenzar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp?;
                    final message = data['message'] as String? ?? 'Sin mensaje';
                    final device = data['device'] as String? ?? 'Desconocido';

                    // Formatear hora
                    String timeString = 'Sin hora';
                    if (timestamp != null) {
                      final dateTime = timestamp.toDate();
                      timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF888888),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF666666),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          '🕓 $timeString',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dispositivo: $device',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${doc.id}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteEntry(doc.id),
                          tooltip: 'Eliminar entrada',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 