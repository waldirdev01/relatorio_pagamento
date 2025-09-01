import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/contrato.dart';
import '../models/regional.dart';
import '../models/reposicao_aula.dart';
import '../services/atividade_extracurricular_service.dart';
import '../services/itinerario_service.dart';
import '../services/relatorio_service.dart';
import '../services/reposicao_aula_service.dart';
import '../utils/currency_formatter.dart';

class RelatorioScreen extends StatefulWidget {
  final Regional regional;
  final Contrato contrato;

  const RelatorioScreen({
    super.key,
    required this.regional,
    required this.contrato,
  });

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  final RelatorioService _relatorioService = RelatorioService();
  final ItinerarioService _itinerarioService = ItinerarioService();
  final ReposicaoAulaService _reposicaoService = ReposicaoAulaService();
  final AtividadeExtracurricularService _atividadeService =
      AtividadeExtracurricularService();

  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;
  bool _isLoading = false;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório - ${widget.contrato.nome}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gerar Relatório de Pagamento',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Regional: ${widget.regional.descricao}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contrato: ${widget.contrato.nome}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Valor por Km: ${CurrencyFormatter.formatWithUnit(widget.contrato.valorPorKm, 'km')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Seleção de mês e ano
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecionar Mês/Ano do Relatório',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            'Mês',
                            _meses[_mesSelecionado - 1],
                            _meses,
                            (value) {
                              setState(() {
                                _mesSelecionado = _meses.indexOf(value) + 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            'Ano',
                            _anoSelecionado.toString(),
                            List.generate(
                              10,
                              (index) =>
                                  (DateTime.now().year - 5 + index).toString(),
                            ),
                            (value) {
                              setState(() {
                                _anoSelecionado = int.parse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botões de ação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ações',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _gerarRelatorio,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(_isLoading ? 'Gerando...' : 'Gerar PDF'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Informações do relatório
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações do Relatório',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• O relatório incluirá todos os itinerários vinculados ao contrato',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '• Atividades extracurriculares serão exibidas após os itinerários',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '• Será gerado para o mês e ano selecionados',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '• Reposições de aula serão exibidas na mesma linha do itinerário',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '• Atividades extracurriculares contam como atividades diferenciadas',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '• Para gerenciar reposições, use a tela de itinerários com filtro por mês',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '• Totais serão calculados automaticamente',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '• Formato: A4 paisagem com tabela completa',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(
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
              items: items.map((String item) {
                return DropdownMenuItem<String>(value: item, child: Text(item));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _gerarRelatorio() async {
    setState(() => _isLoading = true);

    try {
      // Calcular primeiro e último dia do mês selecionado
      final dataInicio = DateTime(_anoSelecionado, _mesSelecionado, 1);
      final dataFim = DateTime(_anoSelecionado, _mesSelecionado + 1, 0);

      // Buscar dados por contrato
      final itinerarios = await _itinerarioService.getItinerariosPorContrato(
        widget.contrato.id,
      );

      // Buscar atividades extracurriculares do contrato no período selecionado
      final atividadesExtracurriculares = await _atividadeService
          .getAtividadesPorContratoPeriodo(
            contratoId: widget.contrato.id,
            mes: _mesSelecionado,
            ano: _anoSelecionado,
          );

      // Buscar todas as reposições do contrato no período selecionado
      final todasReposicoesDoPeriodo = await _reposicaoService
          .getReposicoesPorContratoPeriodo(
            contratoId: widget.contrato.id,
            mes: _mesSelecionado,
            ano: _anoSelecionado,
          );

      // Agrupar reposições por itinerário
      final reposicoesPorItinerario = <String, List<ReposicaoAula>>{};

      // Inicializar com listas vazias para todos os itinerários
      for (final itinerario in itinerarios) {
        reposicoesPorItinerario[itinerario.id] = [];
      }

      // Distribuir reposições pelos itinerários correspondentes
      for (final reposicao in todasReposicoesDoPeriodo) {
        if (reposicoesPorItinerario.containsKey(reposicao.itinerarioId)) {
          reposicoesPorItinerario[reposicao.itinerarioId]!.add(reposicao);
        }
      }

      // Gerar PDF
      final pdfBytes = await _relatorioService.gerarRelatorioPDF(
        regional: widget.regional,
        contrato: widget.contrato,
        itinerarios: itinerarios,
        atividadesExtracurriculares: atividadesExtracurriculares,
        reposicoesPorItinerario: reposicoesPorItinerario,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      // Mostrar preview com opções de imprimir e salvar
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name:
            '${widget.contrato.nome} ${_meses[_mesSelecionado - 1]} $_anoSelecionado.pdf',
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
