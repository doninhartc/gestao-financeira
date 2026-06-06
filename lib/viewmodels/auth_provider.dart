import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import do Firebase Auth
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthNotifier extends Notifier<UserModel?> {
  // Banco de dados na memória APENAS para a Web
  static final List<UserModel> _webUsersDb = []; 

  @override
  UserModel? build() {
    return null;
  }

  // Método para logar automaticamente se marcou "Lembrar de mim"
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');
    
    if (email != null && password != null) {
      await login(email, password, rememberMe: false);
    }
  }

  // Atualizado com Firebase
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    try {
      // 1. Tenta o login no Firebase primeiro
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel? loggedUser;

      // 2. Busca ou sincroniza com o banco local
      if (kIsWeb) {
        loggedUser = UserModel(id: 1, name: userCredential.user?.displayName ?? 'Usuário', email: email, password: password);
      } else {
        loggedUser = await DatabaseService.instance.getUserByEmail(email);
        if (loggedUser == null) {
          loggedUser = UserModel(name: userCredential.user?.displayName ?? 'Usuário', email: email, password: password);
          await DatabaseService.instance.registerUser(loggedUser);
        }
      }

      state = loggedUser;
      
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', email);
        await prefs.setString('saved_password', password);
      }
      return true;
    } catch (e) {
      return false; // Retorna falso se o Firebase der erro
    }
  }

  // Atualizado com Firebase e Correção do ID
  Future<bool> register(String name, String email, String password) async {
    try {
      // 1. Registra no Firebase
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualiza o nome de exibição no Firebase
      await userCredential.user?.updateDisplayName(name);

      UserModel finalUser;

      // 2. Registra no banco local
      if (kIsWeb) {
        // Na Web, já criamos o modelo passando o ID direto para evitar erro de variável final
        finalUser = UserModel(
          id: _webUsersDb.length + 1, 
          name: name, 
          email: email, 
          password: password
        );
        _webUsersDb.add(finalUser);
      } else {
        // No celular, deixamos o SQLite gerar o ID automático
        finalUser = UserModel(
          name: name, 
          email: email, 
          password: password
        );
        await DatabaseService.instance.registerUser(finalUser);
      }

      state = finalUser;
      
      // Auto-login após registro
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      
      return true;
    } catch (e) {
      return false; // Retorna falso se o Firebase der erro
    }
  }

  // Atualizado com Firebase
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut(); // Desloga do Firebase
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});