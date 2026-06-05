import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthNotifier extends Notifier<UserModel?> {
  // Banco de dados na memória APENAS para a Web
  static final List<UserModel> _webUsersDb = []; 

  @override
  UserModel? build() {
    return null;
  }

  Future<bool> login(String email, String password) async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Tenta encontrar o usuário na lista em memória
      try {
        final user = _webUsersDb.firstWhere(
          (u) => u.email == email && u.password == password
        );
        state = user;
        return true;
      } catch (e) {
        return false; // Usuário não encontrado ou senha errada
      }
    }

    // Código real do SQLite para o celular
    final user = await DatabaseService.instance.getUserByEmail(email);
    if (user != null && user.password == password) {
      state = user;
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Verifica se o e-mail já existe na memória
      if (_webUsersDb.any((u) => u.email == email)) return false; 
      
      final newUser = UserModel(id: _webUsersDb.length + 1, name: name, email: email, password: password);
      _webUsersDb.add(newUser);
      state = newUser;
      return true;
    }

    // Código real do SQLite para o celular
    final existingUser = await DatabaseService.instance.getUserByEmail(email);
    if (existingUser != null) return false;

    final newUser = UserModel(name: name, email: email, password: password);
    await DatabaseService.instance.registerUser(newUser);
    
    state = newUser;
    return true;
  }

  void logout() {
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});