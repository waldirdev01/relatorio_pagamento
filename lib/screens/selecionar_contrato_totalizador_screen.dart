import 'package:flutter/material.dart';

import '../models/contrato.dart';
import '../models/regional.dart';
import '../services/contrato_service.dart';
import '../utils/currency_formatter.dart';
import 'totalizador_screen.dart';

class SelecionarContratoTotalizadorScreen extends StatefulWidget {
  final Regional regional;

  const SelecionarContratoTotalizadorScreen({
    super.key,
    required this.regional,
  });

  @override
  State<SelecionarContratoTotalizadorScreen> createState() =>
      _SelecionarContratoTotalizadorScreenState();
}

class _SelecionarContratoTotalizadorScreenState
    extends State<SelecionarContratoTotalizadorScreen> {
  final ContratoService _contratoService = ContratoService();
  List<Contrato> _contratos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContratos();
  }

  Future<void> _loadContratos() async {
    try {
      final contratos = await _contratoService.buscarContratosPorRegional(
        widget.regional.id,
      );
      setState(() {
        _contratos = contratos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar contratos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navegar(Contrato contrato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TotalizadorScreen(regional: widget.regional, contrato: contrato),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Contrato - Totalizador'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _contratos.isEmpty
                  ? const Center(child: Text('Nenhum contrato encontrado.'))
                  : ListView.builder(
                      itemCount: _contratos.length,
                      itemBuilder: (context, index) {
                        final contrato = _contratos[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              child: Icon(
                                Icons.summarize,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            title: Text(
                              contrato.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Valor por Km: ${CurrencyFormatter.formatWithUnit(contrato.valorPorKm, 'km')}',
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _navegar(contrato),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
