import 'package:flutter/material.dart';

import '../services/estatisticas_globais_service.dart';
import '../utils/currency_formatter.dart';

class RelatoriosGlobaisScreen extends StatefulWidget {
  const RelatoriosGlobaisScreen({super.key});

  @override
  State<RelatoriosGlobaisScreen> createState() =>
      _RelatoriosGlobaisScreenState();
}

class _RelatoriosGlobaisScreenState extends State<RelatoriosGlobaisScreen> {
  final EstatisticasGlobaisService _estatisticasService =
      EstatisticasGlobaisService();

  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  bool _isLoading = false;
  Map<String, dynamic>? _dadosEstatisticas;

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
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final estatisticas = await _estatisticasService
          .calcularEstatisticasGlobais(
            mes: _mesSelecionado,
            ano: _anoSelecionado,
          );

      setState(() {
        _dadosEstatisticas = estatisticas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar estatísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: const Text('Relatórios Globais'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Estatísticas da Secretaria de Educação',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visão geral dos dados de transporte escolar',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Filtros
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtros',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _mesSelecionado,
                            decoration: const InputDecoration(
                              labelText: 'Mês',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(12, (index) {
                              return DropdownMenuItem<int>(
                                value: index + 1,
                                child: Text(_meses[index]),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _mesSelecionado = value;
                                });
                                _carregarEstatisticas();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _anoSelecionado,
                            decoration: const InputDecoration(
                              labelText: 'Ano',
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(5, (index) {
                              final ano = DateTime.now().year - 2 + index;
                              return DropdownMenuItem<int>(
                                value: ano,
                                child: Text(ano.toString()),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _anoSelecionado = value;
                                });
                                _carregarEstatisticas();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Estatísticas
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_dadosEstatisticas != null)
              _buildEstatisticas()
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('Nenhum dado encontrado'),
                ),
              ),

            const SizedBox(height: 24),

            // Botão de gerar relatório
            if (_dadosEstatisticas != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _gerarRelatorio,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Gerar Relatório PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstatisticas() {
    final estatisticasPorRegional =
        _dadosEstatisticas!['estatisticasPorRegional']
            as Map<String, Map<String, dynamic>>;
    final totalGeral =
        _dadosEstatisticas!['totalGeral'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estatísticas por Regional - ${_meses[_mesSelecionado - 1]} $_anoSelecionado',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Lista de regionais
        ...estatisticasPorRegional.entries.map((entry) {
          final regional = entry.value['regional'];
          final estatisticas =
              entry.value['estatisticas'] as Map<String, dynamic>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho da regional
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          regional.descricao,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Grid de estatísticas da regional
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCardRegional(
                        'Alunos',
                        estatisticas['totalAlunos'].toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatCardRegional(
                        'EI',
                        estatisticas['totalEnsinoInfantil'].toString(),
                        Icons.child_care,
                        Colors.green,
                      ),
                      _buildStatCardRegional(
                        'EM',
                        estatisticas['totalEnsinoMedio'].toString(),
                        Icons.school,
                        Colors.orange,
                      ),
                      _buildStatCardRegional(
                        'EE',
                        estatisticas['totalEducacaoEspecial'].toString(),
                        Icons.accessibility,
                        Colors.purple,
                      ),
                      _buildStatCardRegional(
                        'Ônibus',
                        estatisticas['totalOnibus'].toString(),
                        Icons.directions_bus,
                        Colors.red,
                      ),
                      _buildStatCardRegional(
                        'Itinerários',
                        estatisticas['totalItinerarios'].toString(),
                        Icons.route,
                        Colors.teal,
                      ),
                      _buildStatCardRegional(
                        'Atividades',
                        estatisticas['totalAtividadesExtracurriculares']
                            .toString(),
                        Icons.sports_soccer,
                        Colors.indigo,
                      ),
                      _buildStatCardRegional(
                        'Reposições',
                        estatisticas['totalReposicoesAula'].toString(),
                        Icons.event_available,
                        Colors.brown,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Quilometragem e valor da regional
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                size: 20,
                                color: Colors.deepOrange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Quilometragem: ${estatisticas['quilometragemTotal'].toStringAsFixed(2)} km',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 20,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Valor Total: ${CurrencyFormatter.format(estatisticas['valorTotalNota'] ?? 0.0)}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green[700],
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Total Geral
        Card(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.summarize,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'TOTAL GERAL',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Grid do total geral
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCardTotal(
                      'Total de Alunos',
                      totalGeral['totalAlunos'].toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildStatCardTotal(
                      'Ensino Infantil',
                      totalGeral['totalEnsinoInfantil'].toString(),
                      Icons.child_care,
                      Colors.green,
                    ),
                    _buildStatCardTotal(
                      'Ensino Médio',
                      totalGeral['totalEnsinoMedio'].toString(),
                      Icons.school,
                      Colors.orange,
                    ),
                    _buildStatCardTotal(
                      'Educação Especial',
                      totalGeral['totalEducacaoEspecial'].toString(),
                      Icons.accessibility,
                      Colors.purple,
                    ),
                    _buildStatCardTotal(
                      'Total de Ônibus',
                      totalGeral['totalOnibus'].toString(),
                      Icons.directions_bus,
                      Colors.red,
                    ),
                    _buildStatCardTotal(
                      'Total de Itinerários',
                      totalGeral['totalItinerarios'].toString(),
                      Icons.route,
                      Colors.teal,
                    ),
                    _buildStatCardTotal(
                      'Atividades Extracurriculares',
                      totalGeral['totalAtividadesExtracurriculares'].toString(),
                      Icons.sports_soccer,
                      Colors.indigo,
                    ),
                    _buildStatCardTotal(
                      'Reposições de Aula',
                      totalGeral['totalReposicoesAula'].toString(),
                      Icons.event_available,
                      Colors.brown,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Quilometragem e valor total
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              size: 32,
                              color: Colors.deepOrange,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quilometragem Total',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${totalGeral['quilometragemTotal'].toStringAsFixed(2)} km',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 32,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valor Total',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(
                                      totalGeral['valorTotalNota'] ?? 0.0,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardRegional(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardTotal(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _gerarRelatorio() async {
    if (_dadosEstatisticas == null) return;

    try {
      await _estatisticasService.gerarRelatorioEstatisticasPDF(
        dados: _dadosEstatisticas!,
        mes: _mesSelecionado,
        ano: _anoSelecionado,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatório gerado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar relatório: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
