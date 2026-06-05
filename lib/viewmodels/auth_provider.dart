import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart'; // Import necessário
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthNotifier extends Notifier<UserModel?> {
  // Banco de dados na memória APENAS para a Web
  static final List<UserModel> _webUsersDb = []; 

  @override
  UserModel? build() {
    return null;
  }

  // NOVO: Método para logar automaticamente se marcou "Lembrar de mim"
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');
    
    if (email != null && password != null) {
      await login(email, password, rememberMe: false);
    }
  }

  // ATUALIZADO: Agora recebe o rememberMe
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    bool isSuccess = false;
    UserModel? loggedUser;

    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        loggedUser = _webUsersDb.firstWhere(
          (u) => u.email == email && u.password == password
        );
        isSuccess = true;
      } catch (e) {
        isSuccess = false;
      }
    } else {
      // Código real do SQLite para o celular
      loggedUser = await DatabaseService.instance.getUserByEmail(email);
      if (loggedUser != null && loggedUser.password == password) {
        isSuccess = true;
      }
    }

    // Se o login deu certo, atualiza o estado e salva os dados se necessário
    if (isSuccess && loggedUser != null) {
      state = loggedUser;
      
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);
      }
      return true;
    }

    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_webUsersDb.any((u) => u.email == email)) return false; 
      
      final newUser = UserModel(id: _webUsersDb.length + 1, name: name, email: email, password: password);
      _webUsersDb.add(newUser);
      state = newUser;
      
      // Auto-login após registro (opcional)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      
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

  // ATUALIZADO: Limpa a memória do aparelho ao sair
  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});