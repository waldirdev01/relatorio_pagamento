import 'package:flutter/material.dart';

import '../models/escola.dart';
import '../models/itinerario.dart';
import '../models/regional.dart';
import '../models/reposicao_aula.dart';
import '../models/turno.dart';
import '../services/auth_service.dart';
import '../services/escola_service.dart';
import '../services/itinerario_service.dart';
import '../services/reposicao_aula_service.dart';
import '../services/usuario_service.dart';
import 'cadastro_itinerario_screen.dart';
import 'cadastro_reposicao_screen.dart';
import 'selecionar_contrato_screen.dart';

class ItinerariosScreen extends StatefulWidget {
  final Regional regional;
  final bool createNew;

  const ItinerariosScreen({
    super.key,
    required this.regional,
    this.createNew = false,
  });

  @override
  State<ItinerariosScreen> createState() => _ItinerariosScreenState();
}

class _ItinerariosScreenState extends State<ItinerariosScreen> {
  final ItinerarioService _itinerarioService = ItinerarioService();
  final ReposicaoAulaService _reposicaoService = ReposicaoAulaService();
  final EscolaService _escolaService = EscolaService();
  final AuthService _authService = AuthService();
  final UsuarioService _usuarioService = UsuarioService();

  // Modo de seleção múltipla
  bool _isSelectionMode = false;
  final Set<String> _selectedItinerarios = {};

  // Filtro de mês/ano para reposições
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
          _isSelectionMode
              ? '${_selectedItinerarios.length} selecionado(s)'
              : 'Itinerários - ${widget.regional.descricao}',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _isSelectionMode
            ? _buildSelectionActions()
            : _buildNormalActions(),
      ),
      body: Column(
        children: [
          // Seletor de mês/ano para filtrar reposições
          _buildMonthYearSelector(),

          // Lista de itinerários
          Expanded(
            child: StreamBuilder<List<Itinerario>>(
              stream: _itinerarioService.getItinerariosPorRegional(
                widget.regional.id,
              ),
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
                          'Erro ao carregar itinerários',
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

                final itinerarios = snapshot.data ?? [];

                if (itinerarios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.route_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum itinerário encontrado',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicione o primeiro itinerário para começar',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _navigateToCadastro,
                          icon: const Icon(Icons.add),
                          label: const Text('Novo Itinerário'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: itinerarios.length,
                  itemBuilder: (context, index) {
                    final itinerario = itinerarios[index];
                    return _buildItinerarioCard(itinerario);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCadastro,
        tooltip: 'Novo Itinerário',
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildNormalActions() {
    return [
      IconButton(
        icon: const Icon(Icons.picture_as_pdf),
        onPressed: _navigateToRelatorio,
        tooltip: 'Gerar Relatório',
      ),
      IconButton(
        icon: const Icon(Icons.checklist),
        onPressed: _toggleSelectionMode,
        tooltip: 'Seleção Múltipla',
      ),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: _navigateToCadastro,
        tooltip: 'Novo Itinerário',
      ),
    ];
  }

  List<Widget> _buildSelectionActions() {
    return [
      if (_selectedItinerarios.isNotEmpty) ...[
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: _updateDiasTrabalhados,
          tooltip: 'Atualizar Dias',
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _duplicateItinerarios,
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
        _selectedItinerarios.clear();
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedItinerarios.clear();
    });
  }

  void _toggleItinerarioSelection(String itinerarioId) {
    setState(() {
      if (_selectedItinerarios.contains(itinerarioId)) {
        _selectedItinerarios.remove(itinerarioId);
      } else {
        _selectedItinerarios.add(itinerarioId);
      }
    });
  }

  Widget _buildMonthYearSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrar Reposições por Período',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
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

  /// Filtra reposições pelo período selecionado (mês/ano)
  List<ReposicaoAula> _filtrarReposicoesPorPeriodo(
    List<ReposicaoAula> reposicoes,
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

    return reposicoes.where((reposicao) {
      // Priorizar a data da reposição (quando foi executada)
      if (reposicao.dataReposicao != null) {
        return reposicao.dataReposicao!.isAfter(
              inicioMes.subtract(Duration(days: 1)),
            ) &&
            reposicao.dataReposicao!.isBefore(fimMes.add(Duration(days: 1)));
      }

      // Se não tem data da reposição, usar data de criação como fallback
      // (para reposições que ainda não foram executadas)
      final dataCriacao = reposicao.dataCriacao;
      return dataCriacao.isAfter(inicioMes.subtract(Duration(days: 1))) &&
          dataCriacao.isBefore(fimMes.add(Duration(days: 1)));
    }).toList();
  }

  Widget _buildItinerarioCard(Itinerario itinerario) {
    final isSelected = _selectedItinerarios.contains(itinerario.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
      child: ExpansionTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleItinerarioSelection(itinerario.id),
              )
            : CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  itinerario.itinerario.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        title: Text(
          itinerario.itinerario,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<String>>(
              future: _escolaService.getNomesEscolas(itinerario.escolaIds),
              builder: (context, snapshot) {
                final escolasNomes = snapshot.data ?? [];
                final escolasText = escolasNomes.isEmpty
                    ? 'Nenhuma escola'
                    : escolasNomes.join(', ');
                return Text(
                  '$escolasText - ${itinerario.turno.descricao}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            StreamBuilder<List<ReposicaoAula>>(
              stream: _reposicaoService.getReposicoesPorItinerario(
                itinerario.id,
              ),
              builder: (context, snapshot) {
                final todasReposicoes = snapshot.data ?? [];
                final reposicoesFiltradas = _filtrarReposicoesPorPeriodo(
                  todasReposicoes,
                );

                if (reposicoesFiltradas.isNotEmpty) {
                  return Text(
                    '${reposicoesFiltradas.length} reposição(ões) em ${_meses[_mesSelecionado - 1]}/$_anoSelecionado',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return Text(
                  'Nenhuma reposição em ${_meses[_mesSelecionado - 1]}/$_anoSelecionado',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                );
              },
            ),
          ],
        ),
        trailing: _isSelectionMode
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, value, itinerario),
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
                    value: 'reposicao',
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 20),
                        SizedBox(width: 8),
                        Text('Nova Reposição'),
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
                _buildInfoRow('Trajeto', itinerario.trajeto),
                if (itinerario.ei != null)
                  _buildInfoRow('Alunos EI', itinerario.ei.toString()),
                if (itinerario.ef != null)
                  _buildInfoRow('Alunos EF', itinerario.ef.toString()),
                if (itinerario.em != null)
                  _buildInfoRow('Alunos EM', itinerario.em.toString()),
                if (itinerario.ee != null)
                  _buildInfoRow('Alunos EE', itinerario.ee.toString()),
                if (itinerario.eja != null)
                  _buildInfoRow('Alunos EJA', itinerario.eja.toString()),
                _buildInfoRow('Total Alunos', itinerario.total.toString()),
                _buildInfoRow('Nº Ônibus', itinerario.numeroOnibus.toString()),
                _buildInfoRow('Placas', itinerario.placas),
                _buildInfoRow('KM', '${itinerario.km} km'),
                _buildInfoRow(
                  'KM X Nº ÔNIBUS',
                  '${itinerario.kmXNumeroOnibus}',
                ),
                _buildInfoRow(
                  'Dias Trabalhados',
                  itinerario.diasTrabalhados.toString(),
                ),
                _buildInfoRow(
                  'KM X Nº ÔNIBUS X DIAS',
                  '${itinerario.kmXNumeroOnibusXDias}',
                ),
                _buildInfoRow('Motoristas', itinerario.motoristas),
                _buildInfoRow('Monitoras', itinerario.monitoras),

                // Informações do usuário (criação e edição)
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _obterInfoCriacaoItinerario(itinerario),
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
                  future: _obterInfoEdicaoItinerario(itinerario),
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
                  future: _escolaService.getEscolasByIds(itinerario.escolaIds),
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

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Escolas do Itinerário (${escolas.length})',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...escolas.map(
                          (escola) => Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        escola.classificacao ==
                                            ClassificacaoEscola.rural
                                        ? Colors.green
                                        : Colors.blue,
                                    child: Icon(
                                      escola.classificacao ==
                                              ClassificacaoEscola.rural
                                          ? Icons.agriculture
                                          : Icons.location_city,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          escola.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          escola.classificacao.descricao,
                                          style: TextStyle(
                                            color:
                                                escola.classificacao ==
                                                    ClassificacaoEscola.rural
                                                ? Colors.green[700]
                                                : Colors.blue[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Lista de reposições
                StreamBuilder<List<ReposicaoAula>>(
                  stream: _reposicaoService.getReposicoesPorItinerario(
                    itinerario.id,
                  ),
                  builder: (context, snapshot) {
                    final todasReposicoes = snapshot.data ?? [];
                    final reposicoesFiltradas = _filtrarReposicoesPorPeriodo(
                      todasReposicoes,
                    );

                    if (reposicoesFiltradas.isEmpty) {
                      return Card(
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Nenhuma reposição encontrada para ${_meses[_mesSelecionado - 1]}/$_anoSelecionado',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reposições de Aula - ${_meses[_mesSelecionado - 1]}/$_anoSelecionado',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...reposicoesFiltradas.map(
                          (reposicao) => _buildReposicaoCard(reposicao),
                        ),
                      ],
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
      padding: const EdgeInsets.symmetric(vertical: 2),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildReposicaoCard(ReposicaoAula reposicao) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reposição',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleReposicaoMenuAction(context, value, reposicao),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildInfoRow('KM', '${reposicao.km}'),
            _buildInfoRow('Nº ÔNIBUS', reposicao.numeroOnibus.toString()),
            _buildInfoRow('DIAS TRAB.', reposicao.diasTrabalhados.toString()),
            _buildInfoRow('KM X Nº ÔNIBUS', '${reposicao.kmXNumeroOnibus}'),
            _buildInfoRow(
              'KM X Nº ÔNIBUS X DIAS',
              '${reposicao.kmXNumeroOnibusXDias}',
            ),
            if (reposicao.dataSolicitacao != null)
              _buildInfoRow(
                'Data Solicitação',
                '${reposicao.dataSolicitacao!.day.toString().padLeft(2, '0')}/${reposicao.dataSolicitacao!.month.toString().padLeft(2, '0')}/${reposicao.dataSolicitacao!.year}',
              ),
            if (reposicao.dataReposicao != null)
              _buildInfoRow(
                'Data Reposição',
                '${reposicao.dataReposicao!.day.toString().padLeft(2, '0')}/${reposicao.dataReposicao!.month.toString().padLeft(2, '0')}/${reposicao.dataReposicao!.year}',
              ),
            if (reposicao.observacoes != null)
              _buildInfoRow('Observações', reposicao.observacoes!),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Itinerario itinerario,
  ) {
    switch (action) {
      case 'edit':
        _navigateToEdit(itinerario);
        break;
      case 'reposicao':
        _navigateToNovaReposicao(itinerario);
        break;
      case 'duplicate':
        _duplicateSingleItinerario(itinerario);
        break;
      case 'delete':
        _confirmarExclusao(itinerario);
        break;
    }
  }

  void _handleReposicaoMenuAction(
    BuildContext context,
    String action,
    ReposicaoAula reposicao,
  ) {
    switch (action) {
      case 'edit':
        _navigateToEditReposicao(reposicao);
        break;
      case 'delete':
        _confirmarExclusaoReposicao(reposicao);
        break;
    }
  }

  void _navigateToCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CadastroItinerarioScreen(regional: widget.regional),
      ),
    );
  }

  void _navigateToRelatorio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelecionarContratoScreen(regional: widget.regional),
      ),
    );
  }

  void _navigateToEdit(Itinerario itinerario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroItinerarioScreen(
          regional: widget.regional,
          itinerario: itinerario,
        ),
      ),
    );
  }

  void _navigateToNovaReposicao(Itinerario itinerario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroReposicaoScreen(
          regional: widget.regional,
          itinerario: itinerario,
        ),
      ),
    );
  }

  void _navigateToEditReposicao(ReposicaoAula reposicao) async {
    final itinerario = await _itinerarioService.getItinerarioById(
      reposicao.itinerarioId,
    );
    if (itinerario != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CadastroReposicaoScreen(
            regional: widget.regional,
            itinerario: itinerario,
            reposicao: reposicao,
          ),
        ),
      );
    }
  }

  void _confirmarExclusao(Itinerario itinerario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o itinerário "${itinerario.itinerario}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _excluirItinerario(itinerario);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _confirmarExclusaoReposicao(ReposicaoAula reposicao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir esta reposição de aula?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _excluirReposicao(reposicao);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirItinerario(Itinerario itinerario) async {
    try {
      await _itinerarioService.excluirItinerario(itinerario.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Itinerário excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir itinerário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateDiasTrabalhados() async {
    if (_selectedItinerarios.isEmpty) return;

    final result = await showDialog<int>(
      context: context,
      builder: (context) =>
          _DiasTrabalhadosDialog(itinerariosCount: _selectedItinerarios.length),
    );

    if (result != null && result > 0) {
      await _atualizarDiasTrabalhadosEmLote(result);
    }
  }

  void _duplicateItinerarios() async {
    if (_selectedItinerarios.isEmpty) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _DuplicacaoDialog(itinerariosCount: _selectedItinerarios.length),
    );

    if (result != null) {
      await _duplicarItinerariosEmLote(result);
    }
  }

  void _duplicateSingleItinerario(Itinerario itinerario) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _DuplicacaoDialog(itinerariosCount: 1, itinerario: itinerario),
    );

    if (result != null) {
      await _duplicarItinerarioIndividual(itinerario, result);
    }
  }

  Future<void> _atualizarDiasTrabalhadosEmLote(int novosDias) async {
    try {
      // Obter usuário atual
      final usuarioAtual = await _authService.getUsuarioAtual();
      final usuarioId = usuarioAtual?.id;

      for (String itinerarioId in _selectedItinerarios) {
        final itinerario = await _itinerarioService.getItinerarioById(
          itinerarioId,
        );
        if (itinerario != null) {
          final itinerarioAtualizado = itinerario
              .copyWith(
                diasTrabalhados: novosDias,
                dataAtualizacao: DateTime.now(),
              )
              .calcularTotais();

          await _itinerarioService.atualizarItinerario(
            itinerarioAtualizado,
            usuarioId,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedItinerarios.length} itinerário(s) atualizado(s) com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _cancelSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar itinerários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _duplicarItinerariosEmLote(Map<String, dynamic> dados) async {
    try {
      for (String itinerarioId in _selectedItinerarios) {
        final itinerario = await _itinerarioService.getItinerarioById(
          itinerarioId,
        );
        if (itinerario != null) {
          await _duplicarItinerarioIndividual(itinerario, dados);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedItinerarios.length} itinerário(s) duplicado(s) com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _cancelSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao duplicar itinerários: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _duplicarItinerarioIndividual(
    Itinerario itinerario,
    Map<String, dynamic> dados,
  ) async {
    // Obter usuário atual
    final usuarioAtual = await _authService.getUsuarioAtual();
    final usuarioId = usuarioAtual?.id;

    final novoItinerario = itinerario
        .copyWith(
          id: '', // Novo ID será gerado
          itinerario: dados['novoNome'],
          km: dados['novoKm'],
          diasTrabalhados: dados['novosDias'],
          dataCriacao: DateTime.now(),
          dataAtualizacao: null,
          isCopia: true, // Marcar como cópia
          itinerarioOriginalId: itinerario.id, // Referenciar o original
        )
        .calcularTotais();

    await _itinerarioService.adicionarItinerario(novoItinerario, usuarioId);
  }

  Future<void> _excluirReposicao(ReposicaoAula reposicao) async {
    try {
      final sucesso = await _reposicaoService.excluirReposicao(reposicao.id);
      if (sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reposição excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao excluir reposição.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir reposição: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Obtém informações do usuário que criou/editou o itinerário
  Future<String> _obterInfoCriacaoItinerario(Itinerario itinerario) async {
    try {
      if (itinerario.usuarioCriacaoId == null) return '';

      // Verificar cache primeiro
      String nomeUsuario = _usuarioCache[itinerario.usuarioCriacaoId!] ?? '';

      // Se não estiver no cache, buscar no banco
      if (nomeUsuario.isEmpty) {
        final usuario = await _usuarioService.getUsuarioById(
          itinerario.usuarioCriacaoId!,
        );
        nomeUsuario = usuario?.nome ?? 'Usuário desconhecido';

        // Adicionar ao cache
        _usuarioCache[itinerario.usuarioCriacaoId!] = nomeUsuario;
      }

      return 'Criado por $nomeUsuario em ${_formatarData(itinerario.dataCriacao)}';
    } catch (e) {
      return '';
    }
  }

  /// Obtém informações do usuário que editou o itinerário
  Future<String> _obterInfoEdicaoItinerario(Itinerario itinerario) async {
    try {
      if (itinerario.usuarioAtualizacaoId == null ||
          itinerario.dataAtualizacao == null) {
        return '';
      }

      // Verificar cache primeiro
      String nomeUsuario =
          _usuarioCache[itinerario.usuarioAtualizacaoId!] ?? '';

      // Se não estiver no cache, buscar no banco
      if (nomeUsuario.isEmpty) {
        final usuario = await _usuarioService.getUsuarioById(
          itinerario.usuarioAtualizacaoId!,
        );
        nomeUsuario = usuario?.nome ?? 'Usuário desconhecido';

        // Adicionar ao cache
        _usuarioCache[itinerario.usuarioAtualizacaoId!] = nomeUsuario;
      }

      return 'Editado por $nomeUsuario em ${_formatarData(itinerario.dataAtualizacao!)}';
    } catch (e) {
      return '';
    }
  }

  /// Obtém informações do usuário que criou/editou a reposição
  Future<String> _obterInfoCriacaoReposicao(ReposicaoAula reposicao) async {
    try {
      if (reposicao.usuarioCriacaoId == null) return '';

      // Verificar cache primeiro
      String nomeUsuario = _usuarioCache[reposicao.usuarioCriacaoId!] ?? '';

      // Se não estiver no cache, buscar no banco
      if (nomeUsuario.isEmpty) {
        final usuario = await _usuarioService.getUsuarioById(
          reposicao.usuarioCriacaoId!,
        );
        nomeUsuario = usuario?.nome ?? 'Usuário desconhecido';

        // Adicionar ao cache
        _usuarioCache[reposicao.usuarioCriacaoId!] = nomeUsuario;
      }

      return 'Criado por $nomeUsuario em ${_formatarData(reposicao.dataCriacao)}';
    } catch (e) {
      return '';
    }
  }

  /// Obtém informações do usuário que editou a reposição
  Future<String> _obterInfoEdicaoReposicao(ReposicaoAula reposicao) async {
    try {
      if (reposicao.usuarioAtualizacaoId == null ||
          reposicao.dataAtualizacao == null) {
        return '';
      }

      // Verificar cache primeiro
      String nomeUsuario = _usuarioCache[reposicao.usuarioAtualizacaoId!] ?? '';

      // Se não estiver no cache, buscar no banco
      if (nomeUsuario.isEmpty) {
        final usuario = await _usuarioService.getUsuarioById(
          reposicao.usuarioAtualizacaoId!,
        );
        nomeUsuario = usuario?.nome ?? 'Usuário desconhecido';

        // Adicionar ao cache
        _usuarioCache[reposicao.usuarioAtualizacaoId!] = nomeUsuario;
      }

      return 'Editado por $nomeUsuario em ${_formatarData(reposicao.dataAtualizacao!)}';
    } catch (e) {
      return '';
    }
  }

  /// Formatar data no padrão brasileiro
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}

// Dialog para atualização de dias trabalhados
class _DiasTrabalhadosDialog extends StatefulWidget {
  final int itinerariosCount;

  const _DiasTrabalhadosDialog({required this.itinerariosCount});

  @override
  State<_DiasTrabalhadosDialog> createState() => _DiasTrabalhadosDialogState();
}

class _DiasTrabalhadosDialogState extends State<_DiasTrabalhadosDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atualizar Dias Trabalhados'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Atualizar ${widget.itinerariosCount} itinerário(s) selecionado(s)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Novos Dias Trabalhados',
                hintText: 'Ex: 22',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Dias trabalhados é obrigatório';
                }
                final dias = int.tryParse(value);
                if (dias == null || dias <= 0) {
                  return 'Digite um número válido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final dias = int.parse(_controller.text);
              Navigator.pop(context, dias);
            }
          },
          child: const Text('Atualizar'),
        ),
      ],
    );
  }
}

// Dialog para duplicação de itinerários
class _DuplicacaoDialog extends StatefulWidget {
  final int itinerariosCount;
  final Itinerario? itinerario;

  const _DuplicacaoDialog({required this.itinerariosCount, this.itinerario});

  @override
  State<_DuplicacaoDialog> createState() => _DuplicacaoDialogState();
}

class _DuplicacaoDialogState extends State<_DuplicacaoDialog> {
  final _nomeController = TextEditingController();
  final _kmController = TextEditingController();
  final _diasController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.itinerario != null) {
      _nomeController.text = '${widget.itinerario!.itinerario} (Cópia)';
      _kmController.text = widget.itinerario!.km.toString();
      _diasController.text = widget.itinerario!.diasTrabalhados.toString();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _kmController.dispose();
    _diasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duplicar Itinerário(s)'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.itinerariosCount == 1
                    ? 'Duplicar itinerário selecionado'
                    : 'Duplicar ${widget.itinerariosCount} itinerário(s) selecionado(s)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Novo Itinerário',
                  hintText: 'Ex: Rota Centro (Cópia)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmController,
                decoration: const InputDecoration(
                  labelText: 'Novo KM',
                  hintText: 'Ex: 18.5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'KM é obrigatório';
                  }
                  final km = double.tryParse(value);
                  if (km == null || km <= 0) {
                    return 'Digite um valor válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _diasController,
                decoration: const InputDecoration(
                  labelText: 'Dias Trabalhados',
                  hintText: 'Ex: 20',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Dias trabalhados é obrigatório';
                  }
                  final dias = int.tryParse(value);
                  if (dias == null || dias <= 0) {
                    return 'Digite um número válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final dados = {
                'novoNome': _nomeController.text.trim(),
                'novoKm': double.parse(_kmController.text),
                'novosDias': int.parse(_diasController.text),
              };
              Navigator.pop(context, dados);
            }
          },
          child: const Text('Duplicar'),
        ),
      ],
    );
  }
}
