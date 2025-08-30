import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

class AguardandoAprovacaoScreen extends StatefulWidget {
  const AguardandoAprovacaoScreen({super.key});

  @override
  State<AguardandoAprovacaoScreen> createState() =>
      _AguardandoAprovacaoScreenState();
}

class _AguardandoAprovacaoScreenState extends State<AguardandoAprovacaoScreen> {
  final _authService = AuthService();

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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de aguardando
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_empty,
                    size: 60,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  'Aguardando Aprovação',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mensagem
                Text(
                  'Sua conta foi criada com sucesso!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card com informações
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Status da Conta',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.hourglass_empty,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Aguardando Aprovação',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sua conta está sendo analisada pela equipe GCOTE. '
                          'Você receberá uma notificação por e-mail assim que '
                          'sua conta for aprovada.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botões de ação
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _verificarStatus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Verificar Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _fazerLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sair'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Informações adicionais
                Card(
                  color: Colors.blue.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.help_outline, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          'Precisa de ajuda?',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entre em contato com a equipe GCOTE através do e-mail: '
                          'suporte@gcote.gov.br',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
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

  Future<void> _verificarStatus() async {
    try {
      final usuario = await _authService.getUsuarioAtual();

      if (usuario != null && mounted) {
        if (usuario.statusAprovacao == StatusAprovacao.aprovado) {
          // Usuário aprovado - redirecionar para tela principal
          _navegarParaTelaPrincipal();
        } else if (usuario.statusAprovacao == StatusAprovacao.rejeitado) {
          // Usuário rejeitado
          _mostrarDialogoRejeicao();
        } else {
          // Ainda aguardando
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sua conta ainda está aguardando aprovação.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            onPressed: () {
              Navigator.of(context).pop();
              _fazerLogout();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navegarParaTelaPrincipal() {
    // TODO: Implementar navegação baseada no tipo de usuário
    // Por enquanto, apenas mostrar mensagem
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conta aprovada! Redirecionando...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _fazerLogout() async {
    try {
      await _authService.fazerLogout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sair: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
