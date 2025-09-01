import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/contrato.dart';
import '../models/regional.dart';
import '../services/contrato_service.dart';
import '../utils/currency_formatter.dart';

class CadastroContratoScreen extends StatefulWidget {
  final Regional regional;
  final Contrato? contrato; // null para novo, preenchido para edição

  const CadastroContratoScreen({
    super.key,
    required this.regional,
    this.contrato,
  });

  @override
  State<CadastroContratoScreen> createState() => _CadastroContratoScreenState();
}

class _CadastroContratoScreenState extends State<CadastroContratoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContratoService _contratoService = ContratoService();

  late final TextEditingController _nomeController;
  late final TextEditingController _valorPorKmController;

  bool _salvando = false;
  bool get _isEdicao => widget.contrato != null;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.contrato?.nome ?? '');
    _valorPorKmController = TextEditingController(
      text: widget.contrato != null
          ? CurrencyFormatter.formatWithoutSymbol(widget.contrato!.valorPorKm)
          : '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorPorKmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Contrato' : 'Novo Contrato'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_salvando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _salvarContrato,
              child: Text(
                'SALVAR',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações Básicas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Regional (apenas exibição)
                    TextFormField(
                      initialValue: widget.regional.descricao,
                      decoration: const InputDecoration(
                        labelText: 'Regional',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),

                    const SizedBox(height: 16),

                    // Nome do contrato
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Contrato',
                        hintText: 'Ex: Contrato 001/2025',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        if (value.trim().length < 3) {
                          return 'Nome deve ter pelo menos 3 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Valor por quilômetro
                    TextFormField(
                      controller: _valorPorKmController,
                      decoration: const InputDecoration(
                        labelText: 'Valor por Quilômetro (R\$)',
                        hintText: 'Ex: 5,50',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                        suffixText: 'R\$/km',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }

                        if (!CurrencyFormatter.isValid(value.trim())) {
                          return 'Valor inválido';
                        }

                        final valorDouble = CurrencyFormatter.parse(
                          value.trim(),
                        );
                        if (valorDouble <= 0) {
                          return 'Valor deve ser maior que zero';
                        }

                        if (valorDouble > 999.99) {
                          return 'Valor muito alto (máximo: R\$ 999,99)';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _salvando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvarContrato,
                    child: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdicao ? 'Atualizar' : 'Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvarContrato() async {
    if (!_formKey.currentState!.validate() || _salvando) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final valorPorKm = CurrencyFormatter.parse(
        _valorPorKmController.text.trim(),
      );

      final contrato = _isEdicao
          ? widget.contrato!.copyWith(
              nome: _nomeController.text.trim(),
              valorPorKm: valorPorKm,
              dataAtualizacao: DateTime.now(),
            )
          : Contrato.novo(
              nome: _nomeController.text.trim(),
              valorPorKm: valorPorKm,
              regionalId: widget.regional.id,
            );

      if (_isEdicao) {
        await _contratoService.atualizarContrato(contrato);
      } else {
        await _contratoService.adicionarContrato(contrato);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao ${_isEdicao ? 'atualizar' : 'salvar'} contrato: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }
}
