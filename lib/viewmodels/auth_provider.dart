import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AuthNotifier extends Notifier<UserModel?> {
  static final List<UserModel> _webUsersDb = []; 

  @override
  UserModel? build() {
    return null;
  }

  // CORRIGIDO: Agora retorna um 'bool' para a tela saber se deve mudar para o Dashboard
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');
    
    if (email != null && password != null) {
      return await login(email, password, rememberMe: false);
    }
    return false;
  }

  // NOVO: Função de Esqueci a Senha do Firebase
  Future<bool> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true; // E-mail enviado com sucesso
    } catch (e) {
      return false; // Erro (ex: e-mail não cadastrado)
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel? loggedUser;

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
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await userCredential.user?.updateDisplayName(name);

      UserModel finalUser;

      if (kIsWeb) {
        finalUser = UserModel(
          id: _webUsersDb.length + 1, 
          name: name, 
          email: email, 
          password: password
        );
        _webUsersDb.add(finalUser);
      } else {
        finalUser = UserModel(
          name: name, 
          email: email, 
          password: password
        );
        await DatabaseService.instance.registerUser(finalUser);
      }

      state = finalUser;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      
      return true;
    } catch (e) {
      return false; 
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut(); 
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});