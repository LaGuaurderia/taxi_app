import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialAccion {
  final String id;
  final String idTaxi;
  final String parada;
  final String accion;
  final DateTime? timestamp;

  HistorialAccion({
    required this.id,
    required this.idTaxi,
    required this.parada,
    required this.accion,
    this.timestamp,
  });

  factory HistorialAccion.fromMap(Map<String, dynamic> map, String id) {
    return HistorialAccion(
      id: id,
      idTaxi: map['idTaxi'] ?? '',
      parada: map['parada'] ?? '',
      accion: map['accion'] ?? '',
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idTaxi': idTaxi,
      'parada': parada,
      'accion': accion,
      'timestamp': timestamp ?? DateTime.now(),
    };
  }

  @override
  String toString() {
    return 'HistorialAccion(id: $id, idTaxi: $idTaxi, parada: $parada, accion: $accion, timestamp: $timestamp)';
  }
} 