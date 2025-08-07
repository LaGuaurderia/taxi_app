import 'package:cloud_firestore/cloud_firestore.dart';

class TaxiEnCola {
  final String id;
  final String codigoTaxi;
  final DateTime timestamp;

  TaxiEnCola({
    required this.id,
    required this.codigoTaxi,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigoTaxi': codigoTaxi,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TaxiEnCola.fromMap(Map<String, dynamic> map) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is DateTime) return timestamp;
      if (timestamp is String) return DateTime.parse(timestamp);
      if (timestamp is Timestamp) return timestamp.toDate();
      return DateTime.now();
    }

    return TaxiEnCola(
      id: map['id']?.toString() ?? '',
      codigoTaxi: map['codigoTaxi']?.toString() ?? '',
      timestamp: parseTimestamp(map['timestamp']),
    );
  }
} 