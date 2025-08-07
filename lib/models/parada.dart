class Parada {
  final String id;
  final String nombre;
  final String ubicacion;
  final double latitud;
  final double longitud;
  final double radioMetros;

  const Parada({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.latitud,
    required this.longitud,
    this.radioMetros = 100.0, // Radio por defecto de 100 metros
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'latitud': latitud,
      'longitud': longitud,
      'radioMetros': radioMetros,
    };
  }

  factory Parada.fromMap(Map<String, dynamic> map) {
    return Parada(
      id: map['id'],
      nombre: map['nombre'],
      ubicacion: map['ubicacion'],
      latitud: map['latitud'].toDouble(),
      longitud: map['longitud'].toDouble(),
      radioMetros: map['radioMetros']?.toDouble() ?? 100.0,
    );
  }
} 