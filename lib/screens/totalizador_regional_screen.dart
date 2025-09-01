import 'package:flutter/material.dart';

import '../models/regional.dart';
import '../services/totalizador_service.dart';

class TotalizadorRegionalScreen extends StatefulWidget {
  final Regional regional;

  const TotalizadorRegionalScreen({super.key, required this.regional});

  @override
  State<TotalizadorRegionalScreen> createState() =>
      _TotalizadorRegionalScreenState();
}

class _TotalizadorRegionalScreenState extends State<TotalizadorRegionalScreen> {
  final TotalizadorService _service = TotalizadorService();
  final TextEditingController _processoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;
  bool _isLoading = false;

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

  @override
  void dispose() {
    _processoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Totalizador Regional - ${widget.regional.descricao}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card de informações
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gerar Totalizador Consolidado da Regional',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Regional: ${widget.regional.descricao}'),
                          const SizedBox(height: 4),
                          Text(
                            'Este relatório consolidará dados de todos os contratos da regional',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card de configurações
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurações do Relatório',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Seleção de mês/ano
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
                                    setState(() {
                                      _mesSelecionado = value!;
                                    });
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
                                    setState(() {
                                      _anoSelecionado = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Processo de origem
                          TextFormField(
                            controller: _processoController,
                            decoration: const InputDecoration(
                              labelText: 'Processo de Origem',
                              hintText: 'Ex: Processo nº 123/2024',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Observações
                          TextFormField(
                            controller: _observacoesController,
                            decoration: const InputDecoration(
                              labelText: 'Observações',
                              hintText:
                                  'Observações adicionais para o relatório',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botão de gerar
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _gerar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _isLoading ? 'Gerando...' : 'Gerar Totalizador Regional',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informações adicionais
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Informações sobre o Totalizador Regional',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Consolida dados de todos os contratos ativos da regional\n'
                            '• Inclui itinerários regulares, atividades extracurriculares e reposições\n'
                            '• Calcula valores totais e percentuais por modalidade de ensino\n'
                            '• Gera relatório detalhado por contrato e resumo geral',
                            style: TextStyle(color: Colors.blue[600]),
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

  Future<void> _gerar() async {
    setState(() => _isLoading = true);

    try {
      final inicio = DateTime(_anoSelecionado, _mesSelecionado, 1);
      final fim = DateTime(_anoSelecionado, _mesSelecionado + 1, 0);

      await _service.gerarRelatorioTotalizadorRegionalPDF(
        regional: widget.regional,
        dataInicio: inicio,
        dataFim: fim,
        processoOrigem: _processoController.text.trim(),
        observacoes: _observacoesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Totalizador regional gerado com sucesso!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar totalizador regional: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
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
