class SolicitudCambio {
  final String id;
  final String taxiSolicitante; // Código del taxi que solicita el cambio
  final String taxiSolicitado; // Código del taxi con quien quiere cambiar
  final String paradaId;
  final DateTime timestamp;
  final String estado; // 'pendiente', 'aceptada', 'rechazada', 'expirada'
  final String? mensaje; // Mensaje opcional del solicitante

  SolicitudCambio({
    required this.id,
    required this.taxiSolicitante,
    required this.taxiSolicitado,
    required this.paradaId,
    required this.timestamp,
    required this.estado,
    this.mensaje,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taxiSolicitante': taxiSolicitante,
      'taxiSolicitado': taxiSolicitado,
      'paradaId': paradaId,
      'timestamp': timestamp.toIso8601String(),
      'estado': estado,
      'mensaje': mensaje,
    };
  }

  factory SolicitudCambio.fromMap(Map<String, dynamic> map) {
    return SolicitudCambio(
      id: map['id'],
      taxiSolicitante: map['taxiSolicitante'],
      taxiSolicitado: map['taxiSolicitado'],
      paradaId: map['paradaId'],
      timestamp: DateTime.parse(map['timestamp']),
      estado: map['estado'],
      mensaje: map['mensaje'],
    );
  }

  SolicitudCambio copyWith({
    String? id,
    String? taxiSolicitante,
    String? taxiSolicitado,
    String? paradaId,
    DateTime? timestamp,
    String? estado,
    String? mensaje,
  }) {
    return SolicitudCambio(
      id: id ?? this.id,
      taxiSolicitante: taxiSolicitante ?? this.taxiSolicitante,
      taxiSolicitado: taxiSolicitado ?? this.taxiSolicitado,
      paradaId: paradaId ?? this.paradaId,
      timestamp: timestamp ?? this.timestamp,
      estado: estado ?? this.estado,
      mensaje: mensaje ?? this.mensaje,
    );
  }
} 