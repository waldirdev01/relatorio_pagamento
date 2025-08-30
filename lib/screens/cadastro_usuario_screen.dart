import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/regional.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/regional_service.dart';
import 'aguardando_aprovacao_screen.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _regionalService = RegionalService();

  final _nomeController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  TipoUsuario _tipoUsuarioSelecionado = TipoUsuario.administrativoUniae;
  Regional? _regionalSelecionada;
  List<Regional> _regionais = [];
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _carregarRegionais();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _carregarRegionais() async {
    try {
      final regionais = await _regionalService.getRegionais().first;
      setState(() {
        _regionais = regionais;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar regionais: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Usuário'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Criar Nova Conta',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha os dados abaixo para criar sua conta',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dados pessoais
              _buildSectionTitle('Dados Pessoais'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  if (value.trim().length < 3) {
                    return 'Nome deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  labelText: 'Matrícula *',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Matrícula é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Telefone é obrigatório';
                  }
                  if (value.length < 10) {
                    return 'Telefone deve ter pelo menos 10 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
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
              const SizedBox(height: 24),

              // Senha
              _buildSectionTitle('Segurança'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _senhaController,
                decoration: InputDecoration(
                  labelText: 'Senha *',
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
                  if (value.length < 6) {
                    return 'Senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmarSenhaController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Senha *',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirmação de senha é obrigatória';
                  }
                  if (value != _senhaController.text) {
                    return 'Senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tipo de usuário e regional
              _buildSectionTitle('Perfil e Regional'),
              const SizedBox(height: 16),

              DropdownButtonFormField<TipoUsuario>(
                initialValue: _tipoUsuarioSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Usuário *',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: TipoUsuario.gcote,
                    child: const Text('GCOTE'),
                  ),
                  DropdownMenuItem(
                    value: TipoUsuario.chefeUniae,
                    child: const Text('Chefe UNIAE'),
                  ),
                  DropdownMenuItem(
                    value: TipoUsuario.administrativoUniae,
                    child: const Text('Administrativo UNIAE'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipoUsuarioSelecionado = value!;
                    // Limpar regional selecionada se for GCOTE
                    if (value == TipoUsuario.gcote) {
                      _regionalSelecionada = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Só mostrar regional se não for GCOTE
              if (_tipoUsuarioSelecionado != TipoUsuario.gcote) ...[
                DropdownButtonFormField<Regional>(
                  initialValue: _regionalSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Regional *',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  items: _regionais.map((regional) {
                    return DropdownMenuItem(
                      value: regional,
                      child: Text(regional.descricao),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _regionalSelecionada = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Regional é obrigatória';
                    }
                    return null;
                  },
                ),
              ] else ...[
                // Mostrar informação para GCOTE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Usuários GCOTE não precisam selecionar uma regional específica.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Botão de cadastro
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _cadastrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Criar Conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Link para login
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Já tem uma conta? Faça login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usuario = await _authService.cadastrarUsuario(
        nome: _nomeController.text.trim(),
        matricula: _matriculaController.text.trim(),
        telefone: _telefoneController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        tipoUsuario: _tipoUsuarioSelecionado,
        regionalId: _tipoUsuarioSelecionado == TipoUsuario.gcote
            ? null
            : _regionalSelecionada?.id,
      );

      if (usuario != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AguardandoAprovacaoScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
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
}
