class TaxistaRegistro {
  final String codigoTaxi;
  final String nombre;
  final String numeroTelefono;
  final String passwordHash;
  final DateTime fechaRegistro;
  final bool activo;
  final DateTime? ultimaActividad;

  TaxistaRegistro({
    required this.codigoTaxi,
    required this.nombre,
    required this.numeroTelefono,
    required this.passwordHash,
    required this.fechaRegistro,
    this.activo = true,
    this.ultimaActividad,
  });

  factory TaxistaRegistro.fromMap(Map<String, dynamic> map, String codigoTaxi) {
    return TaxistaRegistro(
      codigoTaxi: codigoTaxi,
      nombre: map['nombre'] ?? '',
      numeroTelefono: map['numeroTelefono'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      fechaRegistro: map['fechaRegistro'] != null 
          ? (map['fechaRegistro'] as dynamic).toDate()
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
      'nombre': nombre,
      'numeroTelefono': numeroTelefono,
      'passwordHash': passwordHash,
      'fechaRegistro': fechaRegistro,
      'activo': activo,
      'ultimaActividad': ultimaActividad,
    };
  }

  @override
  String toString() {
    return 'TaxistaRegistro(codigoTaxi: $codigoTaxi, nombre: $nombre, numeroTelefono: $numeroTelefono, fechaRegistro: $fechaRegistro, activo: $activo)';
  }
} 