import 'taxi_en_cola.dart';

class ColaTaxis {
  final String id;
  final String nombre;
  final String ubicacion;
  final List<TaxiEnCola> taxisEnCola;

  ColaTaxis({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.taxisEnCola,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion,
      'taxisEnCola': taxisEnCola.map((taxi) => taxi.toMap()).toList(),
    };
  }

  factory ColaTaxis.fromMap(Map<String, dynamic> map) {
    return ColaTaxis(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      ubicacion: map['ubicacion'] ?? '',
      taxisEnCola: List<TaxiEnCola>.from(
        map['taxisEnCola']?.map((x) => TaxiEnCola.fromMap(x)) ?? [],
      ),
    );
  }
}

class Parada {
  final String id;
  final String nombre;

  const Parada({
    required this.id,
    required this.nombre,
  });
}

// Paradas disponibles
class ParadasDisponibles {
  static const List<Parada> paradas = [
    Parada(id: 'hospital', nombre: 'Hospital Mollet'),
    Parada(id: 'avenida', nombre: 'Avenida Libertad'),
    Parada(id: 'estacion', nombre: 'Estación Mollet-San Fost'),
  ];

  static Parada getParadaById(String id) {
    return paradas.firstWhere((parada) => parada.id == id);
  }
} 