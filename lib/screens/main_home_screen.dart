import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'gerenciar_usuarios_screen.dart';
import 'login_screen.dart';
import 'regionais_screen.dart';

class MainHomeScreen extends StatelessWidget {
  MainHomeScreen({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('Sistema de Relatórios'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _fazerLogout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com informações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dashboard,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Painel Principal',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gerencie todos os aspectos do sistema de relatórios',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Título da seção de navegação
            Text(
              'Sistema de Gestão',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Acesse as funcionalidades do sistema',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),

            const SizedBox(height: 16),

            // Grid de cards de navegação
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                // Card Gerenciar Regionais
                _buildNavigationCard(
                  context,
                  icon: Icons.location_on,
                  title: 'Gerenciar Regionais',
                  subtitle: 'Administrar regionais e status de relatórios',
                  onTap: () => _navigateToRegionais(context),
                ),
                // Card Gerenciar Usuários
                _buildNavigationCard(
                  context,
                  icon: Icons.people,
                  title: 'Gerenciar Usuários',
                  subtitle: 'Administrar usuários do sistema',
                  onTap: () => _navigateToGerenciarUsuarios(context),
                ),
                // Card Configurações
                _buildNavigationCard(
                  context,
                  icon: Icons.settings,
                  title: 'Configurações',
                  subtitle: 'Configurações gerais do sistema',
                  onTap: () => _showNotImplemented(context),
                ),
                // Card Relatórios Globais
                _buildNavigationCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Relatórios Globais',
                  subtitle: 'Visão geral dos relatórios',
                  onTap: () => _showNotImplemented(context),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRegionais(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const RegionaisScreen()));
  }

  void _navigateToGerenciarUsuarios(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GerenciarUsuariosScreen()),
    );
  }

  void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _fazerLogout(BuildContext context) async {
    try {
      await _authService.fazerLogout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
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
