import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/regional_service.dart';
import 'aguardando_aprovacao_screen.dart';
import 'main_home_screen.dart';
import 'regional_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _regionalService = RegionalService();

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Logo/Ícone
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  'Relatório de Pagamento',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sistema de Gestão de Transporte Escolar',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Formulário de login
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fazer Login',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'E-mail é obrigatório';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Senha
                          TextFormField(
                            controller: _senhaController,
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Senha é obrigatória';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Botão de login
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _fazerLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Link para redefinir senha
                          Center(
                            child: TextButton(
                              onPressed: _mostrarDialogoRedefinirSenha,
                              child: const Text('Esqueceu sua senha?'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Link para cadastro
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Não tem uma conta? '),
                        TextButton(
                          onPressed: _navegarParaCadastro,
                          child: const Text('Cadastre-se'),
                        ),
                      ],
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

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usuario = await _authService.fazerLogin(
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (usuario != null && mounted) {
        _navegarConformeStatus(usuario);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navegarConformeStatus(Usuario usuario) {
    switch (usuario.statusAprovacao) {
      case StatusAprovacao.aguardando:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AguardandoAprovacaoScreen(),
          ),
        );
        break;
      case StatusAprovacao.aprovado:
        _navegarParaTelaPrincipal(usuario);
        break;
      case StatusAprovacao.rejeitado:
        _mostrarDialogoRejeicao();
        break;
    }
  }

  void _navegarParaTelaPrincipal(Usuario usuario) async {
    switch (usuario.tipoUsuario) {
      case TipoUsuario.gcote:
        // GCOTE vai para homepage principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainHomeScreen()),
        );
        break;
      case TipoUsuario.chefeUniae:
      case TipoUsuario.administrativoUniae:
        // Chefe e Administrativo vão para homepage da regional específica
        if (usuario.regionalId != null) {
          try {
            final regional = await _regionalService.getRegionalById(
              usuario.regionalId!,
            );
            if (regional != null && mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => RegionalHomeScreen(regional: regional),
                ),
              );
            } else {
              // Fallback se não encontrar a regional
              _navegarParaHomepagePrincipal();
            }
          } catch (e) {
            // Fallback em caso de erro
            _navegarParaHomepagePrincipal();
          }
        } else {
          // Fallback se não tiver regionalId
          _navegarParaHomepagePrincipal();
        }
        break;
    }
  }

  void _navegarParaHomepagePrincipal() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainHomeScreen()),
    );
  }

  void _mostrarDialogoRejeicao() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Conta Rejeitada'),
          ],
        ),
        content: const Text(
          'Sua conta foi rejeitada pela equipe GCOTE. '
          'Entre em contato para mais informações.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _authService.fazerLogout();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoRedefinirSenha() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite seu e-mail para receber o link de redefinição:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _authService.redefinirSenha(emailController.text.trim());
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-mail de redefinição enviado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao enviar e-mail: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _navegarParaCadastro() {
    Navigator.of(context).pushNamed('/cadastro');
  }
}
