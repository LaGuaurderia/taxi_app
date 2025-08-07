class TaxistaVinculado {
  final String codigoTaxi;
  final String numeroTelefono;
  final DateTime fechaVinculacion;
  final bool activo;
  final DateTime? ultimaActividad;

  TaxistaVinculado({
    required this.codigoTaxi,
    required this.numeroTelefono,
    required this.fechaVinculacion,
    this.activo = true,
    this.ultimaActividad,
  });

  factory TaxistaVinculado.fromMap(Map<String, dynamic> map, String codigoTaxi) {
    return TaxistaVinculado(
      codigoTaxi: codigoTaxi,
      numeroTelefono: map['numeroTelefono'] ?? '',
      fechaVinculacion: map['fechaVinculacion'] != null 
          ? (map['fechaVinculacion'] as dynamic).toDate()
          : DateTime.now(),
      activo: map['activo'] ?? true,
      ultimaActividad: map['ultimaActividad'] != null 
          ? (map['ultimaActividad'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigoTaxi': codigoTaxi,
      'numeroTelefono': numeroTelefono,
      'fechaVinculacion': fechaVinculacion,
      'activo': activo,
      'ultimaActividad': ultimaActividad,
    };
  }

  @override
  String toString() {
    return 'TaxistaVinculado(codigoTaxi: $codigoTaxi, numeroTelefono: $numeroTelefono, fechaVinculacion: $fechaVinculacion, activo: $activo)';
  }
} 