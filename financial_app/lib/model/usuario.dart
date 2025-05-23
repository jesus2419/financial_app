class Usuario {
  int? id;
  final String nombre;
  final String apellidoP;
  final String apellidoM;
  final String email;
  final String pass;

  Usuario({
    this.id,
    required this.nombre,
    required this.apellidoP,
    required this.apellidoM,
    required this.email,
    required this.pass,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido_p': apellidoP,
      'apellido_m': apellidoM,
      'email': email,
      'pass': pass,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nombre: map['nombre'],
      apellidoP: map['apellido_p'],
      apellidoM: map['apellido_m'],
      email: map['email'],
      pass: map['pass'],
    );
  }
}