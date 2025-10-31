import 'package:flutter/material.dart';

import '../models/atividade_extracurricular.dart';
import '../models/escola.dart';
import '../models/regional.dart';
import '../models/turno.dart';
import '../services/atividade_extracurricular_service.dart';
import '../services/auth_service.dart';
import '../services/escola_service.dart';
import '../services/usuario_service.dart';
import '../utils/app_logger.dart';
import 'cadastro_atividade_extracurricular_screen.dart';

class AtividadesExtracurricularesScreen extends StatefulWidget {
  final Regional regional;
  final bool createNew;

  const AtividadesExtracurricularesScreen({
    super.key,
    required this.regional,
    this.createNew = false,
  });

  @override
  State<AtividadesExtracurricularesScreen> createState() =>
      _AtividadesExtracurricularesScreenState();
}

class _AtividadesExtracurricularesScreenState
    extends State<AtividadesExtracurricularesScreen> {
  final _atividadeService = AtividadeExtracurricularService();
  final _escolaService = EscolaService();
  final _authService = AuthService();
  final _usuarioService = UsuarioService();
  bool _isSelectionMode = false;
  final Set<String> _selectedAtividades = {};

  // Filtros de período
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  // Cache para usuários para evitar consultas repetidas
  final Map<String, String> _usuarioCache = {};
  final List<String> _meses = [
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

  @override
  void initState() {
    super.initState();
    if (widget.createNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToCadastro();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Atividades Extracurriculares - ${widget.regional.descricao}',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Seletor de mês/ano para filtrar atividades
          _buildMonthYearSelector(),

          // Lista de atividades
          Expanded(
            child: StreamBuilder<List<AtividadeExtracurricular>>(
              stream: _atividadeService.getAtividadesPorRegional(
                widget.regional.id,
              ),
              builder: (context, snapshot) {
                AppLogger.debug(
                  'Estado: ${snapshot.connectionState}',
                  tag: 'ATIVIDADES-SCREEN',
                );
                AppLogger.debug(
                  'Tem erro: ${snapshot.hasError}',
                  tag: 'ATIVIDADES-SCREEN',
                );
                if (snapshot.hasError) {
                  AppLogger.error(
                    'ATIVIDADES EXTRACURRICULARES - LINK AQUI! CLIQUE NESTE LINK PARA CRIAR O ÍNDICE DE ATIVIDADES: ${snapshot.error}',
                    tag: 'ATIVIDADES-SCREEN',
                    error: snapshot.error,
                  );
                }

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
                          'Erro ao carregar atividades',
                          style: Theme.of(context).textTheme.titleLarge,
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

                final todasAtividades = snapshot.data ?? [];
                final atividadesFiltradas = _filtrarAtividadesPorPeriodo(
                  todasAtividades,
                );

                if (atividadesFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          todasAtividades.isEmpty
                              ? 'Nenhuma atividade encontrada'
                              : 'Nenhuma atividade em ${_meses[_mesSelecionado - 1]}/$_anoSelecionado',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          todasAtividades.isEmpty
                              ? 'Adicione a primeira atividade para começar'
                              : 'Altere o período ou adicione novas atividades',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _navigateToCadastro,
                          icon: const Icon(Icons.add),
                          label: const Text('Nova Atividade'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: atividadesFiltradas.length,
                  itemBuilder: (context, index) {
                    final atividade = atividadesFiltradas[index];
                    return _buildAtividadeCard(atividade);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCadastro,
        tooltip: 'Nova Atividade',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildNormalActions() {
    return [
      IconButton(
        icon: const Icon(Icons.checklist),
        onPressed: _toggleSelectionMode,
        tooltip: 'Seleção Múltipla',
      ),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: _navigateToCadastro,
        tooltip: 'Nova Atividade',
      ),
    ];
  }

  List<Widget> _buildSelectionActions() {
    return [
      if (_selectedAtividades.isNotEmpty) ...[
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _updateStatusMultiple,
          tooltip: 'Atualizar Status',
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _duplicateAtividades,
          tooltip: 'Duplicar',
        ),
      ],
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: _cancelSelection,
        tooltip: 'Cancelar',
      ),
    ];
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedAtividades.clear();
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedAtividades.clear();
    });
  }

  void _toggleAtividadeSelection(String atividadeId) {
    setState(() {
      if (_selectedAtividades.contains(atividadeId)) {
        _selectedAtividades.remove(atividadeId);
      } else {
        _selectedAtividades.add(atividadeId);
      }
    });
  }

  Widget _buildMonthYearSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrar Atividades por Período',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: _mesSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Mês',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(_meses[index]),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _mesSelecionado = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _anoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Ano',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(5, (index) {
                    final ano = DateTime.now().year - 2 + index;
                    return DropdownMenuItem(
                      value: ano,
                      child: Text(ano.toString()),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _anoSelecionado = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Filtra atividades pelo período selecionado (mês/ano)
  List<AtividadeExtracurricular> _filtrarAtividadesPorPeriodo(
    List<AtividadeExtracurricular> atividades,
  ) {
    final inicioMes = DateTime(_anoSelecionado, _mesSelecionado, 1);
    final fimMes = DateTime(
      _anoSelecionado,
      _mesSelecionado + 1,
      0,
      23,
      59,
      59,
      999,
    );

    return atividades.where((atividade) {
      // Priorizar a data da atividade (quando foi programada)
      if (atividade.dataAtividade != null) {
        return atividade.dataAtividade!.isAfter(
              inicioMes.subtract(Duration(days: 1)),
            ) &&
            atividade.dataAtividade!.isBefore(fimMes.add(Duration(days: 1)));
      }

      // Se não tem data da atividade, usar data de criação como fallback
      final dataCriacao = atividade.dataCriacao;
      return dataCriacao.isAfter(inicioMes.subtract(Duration(days: 1))) &&
          dataCriacao.isBefore(fimMes.add(Duration(days: 1)));
    }).toList();
  }

  Widget _buildAtividadeCard(AtividadeExtracurricular atividade) {
    final isSelected = _selectedAtividades.contains(atividade.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? Colors.purple.withValues(alpha: 0.1) : null,
      child: ExpansionTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleAtividadeSelection(atividade.id),
              )
            : CircleAvatar(
                backgroundColor: _getStatusColor(atividade.status),
                child: Text(
                  atividade.descricao.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        title: Text(
          atividade.descricao,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<String>>(
              future: _escolaService.getNomesEscolas(atividade.escolaIds),
              builder: (context, snapshot) {
                final escolasNomes = snapshot.data ?? [];
                final escolasText = escolasNomes.isEmpty
                    ? 'Nenhuma escola'
                    : escolasNomes.join(', ');
                return Text(
                  '$escolasText - ${atividade.turno.descricao}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(atividade.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(
                    atividade.status,
                  ).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                atividade.status.descricao,
                style: TextStyle(
                  color: _getStatusColor(atividade.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: _isSelectionMode
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, value, atividade),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.update, size: 20),
                        SizedBox(width: 8),
                        Text('Atualizar Status'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20),
                        SizedBox(width: 8),
                        Text('Duplicar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Trajeto', atividade.trajeto),
                if (atividade.codigoTcb != null)
                  _buildInfoRow('Código TCB', atividade.codigoTcb!),
                if (atividade.dataSolicitacao != null)
                  _buildInfoRow(
                    'Data Solicitação',
                    _formatDate(atividade.dataSolicitacao!),
                  ),
                if (atividade.dataAtividade != null)
                  _buildInfoRow(
                    'Data da Atividade',
                    _formatDate(atividade.dataAtividade!),
                  ),
                if (atividade.motivoCancelamento != null)
                  _buildInfoRow('Motivo', atividade.motivoCancelamento!),
                if (atividade.ei != null)
                  _buildInfoRow('Alunos EI', atividade.ei.toString()),
                if (atividade.ef != null)
                  _buildInfoRow('Alunos EF', atividade.ef.toString()),
                if (atividade.em != null)
                  _buildInfoRow('Alunos EM', atividade.em.toString()),
                if (atividade.ee != null)
                  _buildInfoRow('Alunos EE', atividade.ee.toString()),
                if (atividade.eja != null)
                  _buildInfoRow('Alunos EJA', atividade.eja.toString()),
                _buildInfoRow('Total Alunos', atividade.total.toString()),
                _buildInfoRow('Nº Ônibus', atividade.numeroOnibus.toString()),
                _buildInfoRow('Placas', atividade.placas),
                _buildInfoRow('KM', '${atividade.km} km'),
                _buildInfoRow('KM X Nº ÔNIBUS', '${atividade.kmXNumeroOnibus}'),
                _buildInfoRow(
                  'Dias Trabalhados',
                  atividade.diasTrabalhados.toString(),
                ),
                _buildInfoRow(
                  'KM X Nº ÔNIBUS X DIAS',
                  '${atividade.kmXNumeroOnibusXDias}',
                ),
                _buildInfoRow('Motoristas', atividade.motoristas),
                _buildInfoRow('Monitoras', atividade.monitoras),

                // Informações do usuário (criação e edição)
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _obterInfoCriacaoAtividade(atividade),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 14,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                snapshot.data!,
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                FutureBuilder<String>(
                  future: _obterInfoEdicaoAtividade(atividade),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.orange[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                snapshot.data!,
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),

                // Seção de escolas
                FutureBuilder<List<Escola>>(
                  future: _escolaService.getEscolasByIds(atividade.escolaIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final escolas = snapshot.data ?? [];

                    if (escolas.isEmpty) {
                      return Card(
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.school,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nenhuma escola cadastrada',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Card(
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  color: Colors.purple[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Escolas (${escolas.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: escolas.map((escola) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        escola.classificacao ==
                                            ClassificacaoEscola.rural
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          escola.classificacao ==
                                              ClassificacaoEscola.rural
                                          ? Colors.green
                                          : Colors.blue,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        escola.classificacao ==
                                                ClassificacaoEscola.rural
                                            ? Icons.agriculture
                                            : Icons.location_city,
                                        size: 14,
                                        color:
                                            escola.classificacao ==
                                                ClassificacaoEscola.rural
                                            ? Colors.green[700]
                                            : Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        escola.nome,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              escola.classificacao ==
                                                  ClassificacaoEscola.rural
                                              ? Colors.green[700]
                                              : Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StatusAtividadeExtracurricular status) {
    switch (status) {
      case StatusAtividadeExtracurricular.criada:
        return Colors.grey;
      case StatusAtividadeExtracurricular.enviadaParaTcb:
        return Colors.orange;
      case StatusAtividadeExtracurricular.aprovadaPelaTcb:
        return Colors.blue;
      case StatusAtividadeExtracurricular.realizada:
        return Colors.green;
      case StatusAtividadeExtracurricular.cancelada:
        return Colors.red;
      case StatusAtividadeExtracurricular.reprovada:
        return Colors.deepOrange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    AtividadeExtracurricular atividade,
  ) {
    switch (action) {
      case 'edit':
        _editAtividade(atividade);
        break;
      case 'status':
        _updateStatus(atividade);
        break;
      case 'duplicate':
        _duplicateAtividade(atividade);
        break;
      case 'delete':
        _deleteAtividade(atividade);
        break;
    }
  }

  void _navigateToCadastro([AtividadeExtracurricular? atividade]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroAtividadeExtracurricularScreen(
          regional: widget.regional,
          atividade: atividade,
        ),
      ),
    );

    // Refresh the list if something was saved
    if (result == true) {
      // The stream will automatically update
    }
  }

  void _editAtividade(AtividadeExtracurricular atividade) {
    _navigateToCadastro(atividade);
  }

  void _updateStatus(AtividadeExtracurricular atividade) {
    showDialog(
      context: context,
      builder: (context) => _StatusUpdateDialog(
        atividade: atividade,
        onStatusUpdated: () {
          // A stream vai atualizar automaticamente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _updateStatusMultiple() {
    if (_selectedAtividades.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => _MultiStatusUpdateDialog(
        atividadeIds: _selectedAtividades.toList(),
        onStatusUpdated: () {
          setState(() {
            _isSelectionMode = false;
            _selectedAtividades.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status das atividades atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _duplicateAtividade(AtividadeExtracurricular atividade) {
    // TODO: Implementar duplicação de atividade
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicação será implementada em breve')),
    );
  }

  void _duplicateAtividades() {
    // TODO: Implementar duplicação em lote
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicação em lote será implementada em breve'),
      ),
    );
  }

  void _deleteAtividade(AtividadeExtracurricular atividade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a atividade "${atividade.descricao}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _atividadeService.excluirAtividade(
                atividade.id,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Atividade excluída com sucesso'
                          : 'Erro ao excluir atividade',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Obtém informações do usuário que criou/editou a atividade
  Future<String> _obterInfoCriacaoAtividade(
    AtividadeExtracurricular atividade,
  ) async {
    try {
      if (atividade.usuarioCriacaoId == null) return '';

      // Verificar cache primeiro
      String nomeUsuario = _usuarioCache[atividade.usuarioCriacaoId!] ?? '';

      // Se não estiver no cache, buscar no banco
      if (nomeUsuario.isEmpty) {
        final usuario = await _usuarioService.getUsuarioById(
          atividade.usuarioCriacaoId!,
        );
        nomeUsuario = usuario?.nome ?? 'Usuário desconhecido';

        // Adicionar ao cache
        _usuarioCache[atividade.usuarioCriacaoId!] = nomeUsuario;
      }

      return 'Criado por $nomeUsuario em ${_formatarData(atividade.dataCriacao)}';
    } catch (e) {
      return '';
    }
  }

  /// Obtém informações do usuário que editou a atividade
  Future<String> _obterInfoEdicaoAtividade(
    AtividadeExtracurricular atividade,
  ) async {
    try {
      if (atividade.usuarioAtualizacaoId == null ||
          atividade.dataAtualizacao == null) {
        return '';
      }

      // Verificar cache primeiro
      String nomeUsuario = _usuarioCache[atividade.usuarioAtualizacaoId!] ?? '';

      // Se não estiver no cache, buscar no banco
      if (nomeUsuario.isEmpty) {
        final usuario = await _usuarioService.getUsuarioById(
          atividade.usuarioAtualizacaoId!,
        );
        nomeUsuario = usuario?.nome ?? 'Usuário desconhecido';

        // Adicionar ao cache
        _usuarioCache[atividade.usuarioAtualizacaoId!] = nomeUsuario;
      }

      return 'Editado por $nomeUsuario em ${_formatarData(atividade.dataAtualizacao!)}';
    } catch (e) {
      return '';
    }
  }

  /// Formatar data no padrão brasileiro
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

// Dialog para atualizar status de uma atividade
class _StatusUpdateDialog extends StatefulWidget {
  final AtividadeExtracurricular atividade;
  final VoidCallback onStatusUpdated;

  const _StatusUpdateDialog({
    required this.atividade,
    required this.onStatusUpdated,
  });

  @override
  State<_StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<_StatusUpdateDialog> {
  final _atividadeService = AtividadeExtracurricularService();
  final _authService = AuthService();
  late StatusAtividadeExtracurricular _novoStatus;
  final _codigoTcbController = TextEditingController();
  final _motivoController = TextEditingController();
  DateTime? _dataSolicitacao;
  DateTime? _dataAtividade;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _novoStatus = widget.atividade.status;
    _codigoTcbController.text = widget.atividade.codigoTcb ?? '';
    _motivoController.text = widget.atividade.motivoCancelamento ?? '';
    _dataSolicitacao = widget.atividade.dataSolicitacao;
    _dataAtividade = widget.atividade.dataAtividade;
  }

  @override
  void dispose() {
    _codigoTcbController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Atualizar Status - ${widget.atividade.descricao}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<StatusAtividadeExtracurricular>(
              initialValue: _novoStatus,
              decoration: const InputDecoration(
                labelText: 'Novo Status',
                border: OutlineInputBorder(),
              ),
              items: StatusAtividadeExtracurricular.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.descricao),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _novoStatus = value;
                    // Limpar motivo se mudou para status que não precisa
                    if (value != StatusAtividadeExtracurricular.cancelada &&
                        value != StatusAtividadeExtracurricular.reprovada) {
                      _motivoController.clear();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codigoTcbController,
              decoration: const InputDecoration(
                labelText: 'Código TCB',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              'Data de Solicitação',
              _dataSolicitacao,
              (date) => setState(() => _dataSolicitacao = date),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              'Data da Atividade',
              _dataAtividade,
              (date) => setState(() => _dataAtividade = date),
            ),
            if (_novoStatus == StatusAtividadeExtracurricular.cancelada ||
                _novoStatus == StatusAtividadeExtracurricular.reprovada) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStatus,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Atualizar'),
        ),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected,
  ) {
    return InkWell(
      onTap: () => _selectDate(onDateSelected),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : 'Selecionar data',
          style: TextStyle(
            color: selectedDate != null ? null : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(Function(DateTime?) onDateSelected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    onDateSelected(date);
  }

  Future<void> _updateStatus() async {
    // Validar motivo se necessário
    if ((_novoStatus == StatusAtividadeExtracurricular.cancelada ||
            _novoStatus == StatusAtividadeExtracurricular.reprovada) &&
        _motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Motivo é obrigatório para cancelamento/reprovação'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final atividadeAtualizada = widget.atividade.copyWith(
        status: _novoStatus,
        codigoTcb: _codigoTcbController.text.trim().isEmpty
            ? null
            : _codigoTcbController.text.trim(),
        dataSolicitacao: _dataSolicitacao,
        dataAtividade: _dataAtividade,
        motivoCancelamento: _motivoController.text.trim().isEmpty
            ? null
            : _motivoController.text.trim(),
      );

      // Obter usuário atual para registrar quem está editando
      final usuarioAtual = await _authService.getUsuarioAtual();
      final usuarioId = usuarioAtual?.id;

      final success = await _atividadeService.atualizarAtividade(
        atividadeAtualizada,
        usuarioId,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          widget.onStatusUpdated();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Dialog para atualizar status de múltiplas atividades
class _MultiStatusUpdateDialog extends StatefulWidget {
  final List<String> atividadeIds;
  final VoidCallback onStatusUpdated;

  const _MultiStatusUpdateDialog({
    required this.atividadeIds,
    required this.onStatusUpdated,
  });

  @override
  State<_MultiStatusUpdateDialog> createState() =>
      _MultiStatusUpdateDialogState();
}

class _MultiStatusUpdateDialogState extends State<_MultiStatusUpdateDialog> {
  final _atividadeService = AtividadeExtracurricularService();
  final _authService = AuthService();
  StatusAtividadeExtracurricular _novoStatus =
      StatusAtividadeExtracurricular.criada;
  final _motivoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Atualizar Status (${widget.atividadeIds.length} atividades)',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<StatusAtividadeExtracurricular>(
            initialValue: _novoStatus,
            decoration: const InputDecoration(
              labelText: 'Novo Status',
              border: OutlineInputBorder(),
            ),
            items: StatusAtividadeExtracurricular.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.descricao),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _novoStatus = value;
                  // Limpar motivo se mudou para status que não precisa
                  if (value != StatusAtividadeExtracurricular.cancelada &&
                      value != StatusAtividadeExtracurricular.reprovada) {
                    _motivoController.clear();
                  }
                });
              }
            },
          ),
          if (_novoStatus == StatusAtividadeExtracurricular.cancelada ||
              _novoStatus == StatusAtividadeExtracurricular.reprovada) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateMultipleStatus,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Atualizar Todas'),
        ),
      ],
    );
  }

  Future<void> _updateMultipleStatus() async {
    // Validar motivo se necessário
    if ((_novoStatus == StatusAtividadeExtracurricular.cancelada ||
            _novoStatus == StatusAtividadeExtracurricular.reprovada) &&
        _motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Motivo é obrigatório para cancelamento/reprovação'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int successCount = 0;

      // Obter usuário atual para registrar quem está editando
      final usuarioAtual = await _authService.getUsuarioAtual();
      final usuarioId = usuarioAtual?.id;

      for (String atividadeId in widget.atividadeIds) {
        final atividade = await _atividadeService.getAtividadeById(atividadeId);
        if (atividade != null) {
          final atividadeAtualizada = atividade.copyWith(
            status: _novoStatus,
            motivoCancelamento: _motivoController.text.trim().isEmpty
                ? null
                : _motivoController.text.trim(),
          );

          final success = await _atividadeService.atualizarAtividade(
            atividadeAtualizada,
            usuarioId,
          );

          if (success) successCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onStatusUpdated();

        if (successCount == widget.atividadeIds.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$successCount atividades atualizadas com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$successCount de ${widget.atividadeIds.length} atividades atualizadas',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
