class Taxista {
  final String uid;
  final String idTaxi;
  final String email;
  final DateTime fechaRegistro;

  Taxista({
    required this.uid,
    required this.idTaxi,
    required this.email,
    required this.fechaRegistro,
  });

  factory Taxista.fromMap(Map<String, dynamic> map, String uid) {
    return Taxista(
      uid: uid,
      idTaxi: map['idTaxi'] ?? '',
      email: map['email'] ?? '',
      fechaRegistro: map['fechaRegistro'] != null 
          ? (map['fechaRegistro'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idTaxi': idTaxi,
      'email': email,
      'fechaRegistro': fechaRegistro,
    };
  }

  @override
  String toString() {
    return 'Taxista(uid: $uid, idTaxi: $idTaxi, email: $email, fechaRegistro: $fechaRegistro)';
  }
} 