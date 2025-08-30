import 'package:flutter/material.dart';

import '../models/contrato.dart';
import '../models/regional.dart';
import '../services/totalizador_service.dart';

class TotalizadorScreen extends StatefulWidget {
  final Regional regional;
  final Contrato contrato;

  const TotalizadorScreen({
    super.key,
    required this.regional,
    required this.contrato,
  });

  @override
  State<TotalizadorScreen> createState() => _TotalizadorScreenState();
}

class _TotalizadorScreenState extends State<TotalizadorScreen> {
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
        title: Text('Totalizador - ${widget.contrato.nome}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gerar Quadro Totalizador',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Regional: ${widget.regional.descricao}'),
                    Text('Contrato: ${widget.contrato.nome}'),
                    Text(
                      'Valor por Km: R\$ ${widget.contrato.valorPorKm.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        'Mês',
                        _meses[_mesSelecionado - 1],
                        _meses,
                        (val) {
                          setState(
                            () => _mesSelecionado = _meses.indexOf(val) + 1,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _dropdown(
                        'Ano',
                        _anoSelecionado.toString(),
                        List.generate(
                          10,
                          (i) => (DateTime.now().year - 5 + i).toString(),
                        ),
                        (val) {
                          setState(() => _anoSelecionado = int.parse(val));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Número do Processo de Origem',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _processoController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: 00080-00196260/2025-40',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Observações',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _observacoesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Digite observações adicionais (opcional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _gerar,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isLoading ? 'Gerando...' : 'Gerar PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
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

  Future<void> _gerar() async {
    setState(() => _isLoading = true);
    try {
      final inicio = DateTime(_anoSelecionado, _mesSelecionado, 1);
      final fim = DateTime(_anoSelecionado, _mesSelecionado + 1, 0);
      await _service.gerarRelatorioTotalizadorPDF(
        regional: widget.regional,
        contrato: widget.contrato,
        dataInicio: inicio,
        dataFim: fim,
        processoOrigem: _processoController.text.trim(),
        observacoes: _observacoesController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar totalizador: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
