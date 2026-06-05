import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_provider.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final success = await ref.read(authProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (success) {
          Navigator.pop(context); // Volta para o Login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada com sucesso! Faça login.'), 
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('E-mail já está em uso.'), 
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro no banco de dados. Você está rodando na Web? O SQLite requer Android/iOS.'), 
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        print("ERRO DETALHADO: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // O Center + ConstrainedBox criam o mesmo cartão flutuante do Login
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
                        // Campo de Nome
                        _buildTwoToneInput(
                          controller: _nameController,
                          hintText: 'Full Name',
                          icon: Icons.badge,
                          validator: (value) => value == null || value.isEmpty ? 'Insira seu nome' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        // Campo de E-mail
                        _buildTwoToneInput(
                          controller: _emailController,
                          hintText: 'Email ID',
                          icon: Icons.email,
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
                        const SizedBox(height: 32),
                        
                        // --- BOTÃO DE CADASTRO ---
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text('CADASTRAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        const SizedBox(height: 16),
                        
                        // --- LINK PARA VOLTAR AO LOGIN ---
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Volta para a tela anterior (Login)
                            },
                            child: RichText(
                              text: TextSpan(
                                text: "Já tem uma conta? ",
                                style: const TextStyle(color: Colors.white70),
                                children: [
                                  TextSpan(
                                    text: 'Faça Login',
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

                // --- ÍCONE DE CADASTRO SOBREPOSTO ---
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
                      child: Icon(Icons.person_add_alt_1, size: 36, color: Theme.of(context).colorScheme.primary),
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