import 'package:flutter/material.dart';

import '../models/regional.dart';
import '../models/status_relatorio_regional.dart';
import '../services/auth_service.dart';
import '../services/regional_service.dart';
import '../services/status_relatorio_service.dart';
import '../services/usuario_service.dart';
import 'cadastro_regional_screen.dart';
import 'regional_home_screen.dart';

class RegionaisScreen extends StatefulWidget {
  const RegionaisScreen({super.key});

  @override
  State<RegionaisScreen> createState() => _RegionaisScreenState();
}

class _RegionaisScreenState extends State<RegionaisScreen> {
  final RegionalService _regionalService = RegionalService();
  final StatusRelatorioService _statusService = StatusRelatorioService();
  final UsuarioService _usuarioService = UsuarioService();
  final AuthService _authService = AuthService();

  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;
  int _refreshKey = 0; // Chave para forçar atualização

  // Cache para usuários para evitar consultas repetidas
  final Map<String, String> _usuarioCache = {};

  final _meses = const [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  /// Força atualização imediata da interface
  void _forcarAtualizacao() {
    if (mounted) {
      setState(() {
        _refreshKey++;
        _usuarioCache.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('Regionais'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header com informações
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Gerenciar Regionais',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Controle de status dos processos mensais',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                // Seletor de mês/ano
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            'Mês',
                            _meses[_mesSelecionado - 1],
                            _meses,
                            (val) {
                              setState(() {
                                _mesSelecionado = _meses.indexOf(val) + 1;
                              });
                              // Forçar atualização imediata
                              _forcarAtualizacao();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            'Ano',
                            _anoSelecionado.toString(),
                            List.generate(
                              10,
                              (i) => (DateTime.now().year - 5 + i).toString(),
                            ),
                            (val) {
                              setState(() {
                                _anoSelecionado = int.parse(val);
                              });
                              // Forçar atualização imediata
                              _forcarAtualizacao();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de regionais
          Expanded(
            child: StreamBuilder<List<Regional>>(
              stream: _regionalService.getRegionais(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar regionais',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final regionais = snapshot.data ?? [];

                if (regionais.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma regional cadastrada',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clique no botão + para adicionar a primeira regional',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: regionais.length,
                  itemBuilder: (context, index) {
                    final regional = regionais[index];
                    return _buildRegionalCard(context, regional);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCadastro(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova Regional'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildRegionalCard(BuildContext context, Regional regional) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: FutureBuilder<StatusRelatorioRegional?>(
        key: ValueKey(
          '${regional.id}_${_mesSelecionado}_${_anoSelecionado}_$_refreshKey',
        ),
        future: _statusService.getStatusPorRegionalMesAno(
          regionalId: regional.id,
          mes: _mesSelecionado,
          ano: _anoSelecionado,
        ),
        builder: (context, statusSnapshot) {
          final status = statusSnapshot.data;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              regional.descricao,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Criada em: ${_formatDate(regional.dataCriacao)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                // Status do relatório
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status?.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status?.statusIcon ?? '⏳',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status?.statusLabel ?? 'Aguardando',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Informações de quem alterou o status
                if (status != null) ...[
                  const SizedBox(height: 4),
                  FutureBuilder<String>(
                    key: ValueKey(
                      '${status.id}_${status.dataAlteracao.millisecondsSinceEpoch}_$_refreshKey',
                    ),
                    future: _obterInfoAlteracao(status),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                snapshot.data!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
            trailing: SizedBox(
              width: 80, // Largura fixa para evitar overflow
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão para alterar status
                  IconButton(
                    onPressed: () =>
                        _showStatusDialog(context, regional, status),
                    icon: const Icon(Icons.edit),
                    tooltip: 'Alterar Status',
                    padding: const EdgeInsets.all(4), // Reduzir padding
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  // Menu de opções
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(context, value, regional),
                    padding: const EdgeInsets.all(4), // Reduzir padding
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Excluir',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            onTap: () => _navigateToRegionalHome(context, regional),
          );
        },
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Regional regional,
  ) {
    switch (action) {
      case 'edit':
        _navigateToCadastro(context, regional: regional);
        break;
      case 'delete':
        _showDeleteDialog(context, regional);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, Regional regional) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir a regional "${regional.descricao}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteRegional(context, regional);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRegional(BuildContext context, Regional regional) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    try {
      await _regionalService.excluirRegional(regional.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Regional "${regional.descricao}" excluída com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir regional: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToCadastro(BuildContext context, {Regional? regional}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CadastroRegionalScreen(regional: regional),
      ),
    );
  }

  void _navigateToRegionalHome(BuildContext context, Regional regional) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RegionalHomeScreen(regional: regional),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<String> _obterInfoAlteracao(StatusRelatorioRegional status) async {
    try {
      // Se o usuárioId é 'usuario_temporario', não mostrar informações
      if (status.usuarioId == 'usuario_temporario') {
        return '';
      }

      // Verificar cache primeiro
      String nomeUsuario = _usuarioCache[status.usuarioId] ?? '';

      // Se não estiver no cache, buscar no banco
      if (nomeUsuario.isEmpty) {
        final usuario = await _usuarioService.getUsuarioById(status.usuarioId);
        nomeUsuario = usuario?.nome ?? 'Usuário desconhecido';

        // Adicionar ao cache
        _usuarioCache[status.usuarioId] = nomeUsuario;
      }

      final dataFormatada = _formatDate(status.dataAlteracao);
      final horaFormatada = _formatTime(status.horaAlteracao);

      return 'Alterado por $nomeUsuario em $dataFormatada às $horaFormatada';
    } catch (e) {
      return '';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map(
                    (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(StatusRelatorio? status) {
    switch (status) {
      case StatusRelatorio.aguardando:
        return Colors.grey;
      case StatusRelatorio.recebido:
        return Colors.blue;
      case StatusRelatorio.emAnalise:
        return Colors.orange;
      case StatusRelatorio.aprovado:
        return Colors.green;
      case StatusRelatorio.devolvido:
        return Colors.red;
      case null:
        return Colors.grey;
    }
  }

  void _showStatusDialog(
    BuildContext context,
    Regional regional,
    StatusRelatorioRegional? currentStatus,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alterar Status - ${regional.descricao}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: StatusRelatorio.values.map((status) {
            return ListTile(
              leading: Text(
                status == StatusRelatorio.aguardando
                    ? '⏳'
                    : status == StatusRelatorio.recebido
                    ? '📨'
                    : status == StatusRelatorio.emAnalise
                    ? '🔍'
                    : status == StatusRelatorio.aprovado
                    ? '✅'
                    : '❌',
                style: const TextStyle(fontSize: 20),
              ),
              title: Text(_getStatusLabel(status)),
              trailing: currentStatus?.status == status
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                Navigator.of(context).pop();
                await _alterarStatus(context, regional, status);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(StatusRelatorio status) {
    switch (status) {
      case StatusRelatorio.aguardando:
        return 'Aguardando';
      case StatusRelatorio.recebido:
        return 'Recebido';
      case StatusRelatorio.emAnalise:
        return 'Em Análise';
      case StatusRelatorio.aprovado:
        return 'Aprovado';
      case StatusRelatorio.devolvido:
        return 'Devolvido';
    }
  }

  Future<void> _alterarStatus(
    BuildContext context,
    Regional regional,
    StatusRelatorio novoStatus,
  ) async {
    try {
      // Obter usuário atual logado
      final usuarioAtual = await _authService.getUsuarioAtual();
      final usuarioId = usuarioAtual?.id ?? 'usuario_temporario';

      await _statusService.alterarStatus(
        regionalId: regional.id,
        mes: _mesSelecionado,
        ano: _anoSelecionado,
        novoStatus: novoStatus,
        usuarioId: usuarioId,
      );

      // Aguardar um pouco para garantir que a escrita no banco foi concluída
      await Future.delayed(const Duration(milliseconds: 300));

      // Forçar atualização da tela imediatamente
      _forcarAtualizacao();

      // Mostrar mensagem de sucesso
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status alterado para "${_getStatusLabel(novoStatus)}"',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Mostrar erro imediatamente
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
