import 'package:flutter/material.dart';

import '../models/regional.dart';
import '../services/auth_service.dart';
import 'atividades_extracurriculares_screen.dart';
import 'contratos_screen.dart';
import 'escolas_screen.dart';
import 'itinerarios_screen.dart';
import 'login_screen.dart';
import 'selecionar_contrato_screen.dart';
import 'selecionar_contrato_totalizador_screen.dart';
import 'totalizador_regional_screen.dart';

class RegionalHomeScreen extends StatelessWidget {
  final Regional regional;

  RegionalHomeScreen({super.key, required this.regional});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(regional.descricao),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com informações da regional
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      regional.descricao,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bem-vindo(a) ao sistema de gerenciamento da ${regional.descricao}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gerencie itinerários, atividades extracurriculares, contratos e relatórios',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Título da seção de navegação
            Text(
              'Gerenciamento',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Acesse as funcionalidades da regional',
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
                // Card Itinerários
                _buildNavigationCard(
                  context,
                  icon: Icons.route,
                  title: 'Itinerários',
                  subtitle: 'Gerenciar rotas de transporte escolar',
                  onTap: () => _navigateToItinerarios(context),
                ),
                // Card Escolas
                _buildNavigationCard(
                  context,
                  icon: Icons.school,
                  title: 'Escolas',
                  subtitle: 'Cadastrar e gerenciar unidades escolares',
                  onTap: () => _navigateToEscolas(context),
                ),
                // Card Atividades Extracurriculares
                _buildNavigationCard(
                  context,
                  icon: Icons.celebration,
                  title: 'Atividades Extras',
                  subtitle: 'Eventos e atividades especiais',
                  onTap: () => _navigateToAtividades(context),
                ),
                // Card Contratos
                _buildNavigationCard(
                  context,
                  icon: Icons.handshake,
                  title: 'Contratos',
                  subtitle: 'Gerenciar contratos de transporte',
                  onTap: () => _navigateToContratos(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Segunda linha do grid - Relatórios
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                // Card Relatórios
                _buildNavigationCard(
                  context,
                  icon: Icons.assessment,
                  title: 'Relatórios',
                  subtitle: 'Gerar relatórios PDF de pagamento',
                  onTap: () => _navigateToRelatorios(context),
                ),
                // Card Totalizador
                _buildNavigationCard(
                  context,
                  icon: Icons.summarize,
                  title: 'Totalizador',
                  subtitle: 'Gerar quadro totalizador financeiro',
                  onTap: () => _navigateToTotalizador(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Card Totalizador Regional (largura completa)
            _buildNavigationCard(
              context,
              icon: Icons.account_balance,
              title: 'Totalizador Regional',
              subtitle:
                  'Gerar quadro consolidado de todos os contratos da regional',
              onTap: () => _navigateToTotalizadorRegional(context),
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

  void _navigateToItinerarios(BuildContext context, {bool createNew = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ItinerariosScreen(regional: regional, createNew: createNew),
      ),
    );
  }

  void _navigateToEscolas(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EscolasScreen(regional: regional),
      ),
    );
  }

  void _navigateToAtividades(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AtividadesExtracurricularesScreen(regional: regional),
      ),
    );
  }

  void _navigateToContratos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContratosScreen(regional: regional),
      ),
    );
  }

  void _navigateToRelatorios(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelecionarContratoScreen(regional: regional),
      ),
    );
  }

  void _navigateToTotalizador(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SelecionarContratoTotalizadorScreen(regional: regional),
      ),
    );
  }

  void _navigateToTotalizadorRegional(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TotalizadorRegionalScreen(regional: regional),
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
