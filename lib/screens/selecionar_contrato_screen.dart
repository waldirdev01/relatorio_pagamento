import 'package:flutter/material.dart';

import '../models/contrato.dart';
import '../models/regional.dart';
import '../services/contrato_service.dart';
import 'relatorio_screen.dart';

class SelecionarContratoScreen extends StatefulWidget {
  final Regional regional;

  const SelecionarContratoScreen({super.key, required this.regional});

  @override
  State<SelecionarContratoScreen> createState() =>
      _SelecionarContratoScreenState();
}

class _SelecionarContratoScreenState extends State<SelecionarContratoScreen> {
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
      setState(() {
        _isLoading = false;
      });
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

  void _navegarParaRelatorio(Contrato contrato) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RelatorioScreen(regional: widget.regional, contrato: contrato),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Contrato'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contratos.isEmpty
          ? _buildEstadoVazio()
          : _buildListaContratos(),
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum contrato encontrado',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Cadastre um contrato antes de gerar relatórios',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  Widget _buildListaContratos() {
    return Padding(
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
                    'Selecionar Contrato para Relatório',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Regional: ${widget.regional.descricao}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha o contrato para gerar o relatório de pagamento.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de contratos
          Expanded(
            child: ListView.builder(
              itemCount: _contratos.length,
              itemBuilder: (context, index) {
                final contrato = _contratos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.description,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    title: Text(
                      contrato.nome,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor por Km: R\$ ${contrato.valorPorKm.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Criado em: ${_formatarData(contrato.dataCriacao)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _navegarParaRelatorio(contrato),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
