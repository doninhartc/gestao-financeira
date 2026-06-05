class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  // Converte o objeto em um Map para ser salvo no SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password, // Nota: Em cenários reais, armazene apenas o hash da senha
    };
  }

  // Reconstrói o objeto a partir de um Map vindo do banco de dados
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}
