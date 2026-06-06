import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_provider.dart';
import 'register_view.dart';
import 'dashboard_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberMe = false; 

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // NOVO: Verifica se há dados salvos para login automático
  Future<void> _checkAutoLogin() async {
    bool success = await ref.read(authProvider.notifier).tryAutoLogin();
    if (success && mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const DashboardView()),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final success = await ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        rememberMe: _rememberMe, 
      );

      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
        
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-mail ou senha incorretos.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // --- CARTÃO PRINCIPAL ---
                Container(
                  margin: const EdgeInsets.only(top: 50), 
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo de E-mail
                        _buildTwoToneInput(
                          controller: _emailController,
                          hintText: 'Email ID',
                          icon: Icons.person,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Insira o e-mail';
                            if (!value.contains('@')) return 'E-mail inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Campo de Senha
                        _buildTwoToneInput(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Insira a senha';
                            if (value.length < 6) return 'Mínimo de 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // --- LINHA: REMEMBER ME & FORGOT PASSWORD ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: Theme.of(context).colorScheme.primary,
                                    onChanged: (value) {
                                      setState(() => _rememberMe = value!);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Remember me', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                            // NOVO: Funcionalidade do Forgot Password
                            TextButton(
                              onPressed: () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty || !email.contains('@')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Digite seu e-mail no campo acima primeiro para recuperar a senha.'), backgroundColor: Colors.orange),
                                  );
                                  return;
                                }
                                
                                bool sent = await ref.read(authProvider.notifier).resetPassword(email);
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(sent ? 'E-mail de recuperação enviado! Verifique sua caixa de entrada.' : 'Erro. Verifique se o e-mail está correto e cadastrado.'),
                                      backgroundColor: sent ? Colors.green : Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                              child: const Text('Forgot Password?', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // --- BOTÃO DE LOGIN ---
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        const SizedBox(height: 16),
                        
                        // --- LINK PARA CADASTRO ---
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterView()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Não tem uma conta? ",
                                style: const TextStyle(color: Colors.white70),
                                children: [
                                  TextSpan(
                                    text: 'Cadastre-se',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- ÍCONE DE PERFIL SOBREPOSTO ---
                Positioned(
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor, 
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(Icons.person_outline, size: 40, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA O INPUT EM DUAS TONALIDADES ---
  Widget _buildTwoToneInput({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.only(top: 14),
        prefixIcon: Container(
          width: 50,
          margin: const EdgeInsets.only(right: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF181818),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          child: Icon(icon, color: Colors.white70),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 1),
        ),
      ),
    );
  }
}