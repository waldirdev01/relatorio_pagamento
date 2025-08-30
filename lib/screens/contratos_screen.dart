import 'package:flutter/material.dart';

import '../models/contrato.dart';
import '../models/regional.dart';
import '../services/contrato_service.dart';
import 'cadastro_contrato_screen.dart';

class ContratosScreen extends StatefulWidget {
  final Regional regional;

  const ContratosScreen({super.key, required this.regional});

  @override
  State<ContratosScreen> createState() => _ContratosScreenState();
}

class _ContratosScreenState extends State<ContratosScreen> {
  final ContratoService _contratoService = ContratoService();

  @override
  Widget build(BuildContext context) {
    print(
      '🏗️ [CONTRATOS-SCREEN] Construindo tela para regional: ${widget.regional.id}',
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Contratos - ${widget.regional.descricao}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _novoContrato(),
            tooltip: 'Novo Contrato',
          ),
        ],
      ),
      body: StreamBuilder<List<Contrato>>(
        stream: _contratoService.listarContratosPorRegional(widget.regional.id),
        builder: (context, snapshot) {
          print('📊 [CONTRATOS-SCREEN] Estado: ${snapshot.connectionState}');
          print('📊 [CONTRATOS-SCREEN] Tem erro: ${snapshot.hasError}');
          print('📊 [CONTRATOS-SCREEN] Erro: ${snapshot.error}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ [CONTRATOS-SCREEN] Aguardando dados...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print(
              '❌ [CONTRATOS-SCREEN] Erro no StreamBuilder: ${snapshot.error}',
            );
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
                    'Erro ao carregar contratos',
                    style: Theme.of(context).textTheme.headlineSmall,
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

          final contratos = snapshot.data ?? [];
          print(
            '📋 [CONTRATOS-SCREEN] Contratos recebidos: ${contratos.length}',
          );

          if (contratos.isEmpty) {
            print(
              '📭 [CONTRATOS-SCREEN] Nenhum contrato encontrado - mostrando tela vazia',
            );
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum contrato encontrado',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clique no botão abaixo para criar seu primeiro contrato',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _novoContrato(),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Primeiro Contrato'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contratos.length,
              itemBuilder: (context, index) {
                final contrato = contratos[index];
                return _buildContratoCard(contrato);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _novoContrato(),
        tooltip: 'Novo Contrato',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContratoCard(Contrato contrato) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editarContrato(contrato),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contrato.nome,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${contrato.valorPorKm.toStringAsFixed(2)}/km',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'editar':
                          _editarContrato(contrato);
                          break;
                        case 'excluir':
                          _confirmarExclusao(contrato);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Editar'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'excluir',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Excluir'),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Criado em: ${_formatarData(contrato.dataCriacao)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (contrato.dataAtualizacao != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.update,
                      size: 16,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Atualizado em: ${_formatarData(contrato.dataAtualizacao!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  Future<void> _novoContrato() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroContratoScreen(regional: widget.regional),
      ),
    );

    if (resultado == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrato adicionado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editarContrato(Contrato contrato) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroContratoScreen(
          regional: widget.regional,
          contrato: contrato,
        ),
      ),
    );

    if (resultado == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrato atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmarExclusao(Contrato contrato) async {
    // Verificar se contrato está em uso
    try {
      final emUso = await _contratoService.contratoEstaEmUso(contrato.id);

      if (emUso) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Não é possível excluir'),
              content: const Text(
                'Este contrato possui itinerários ou atividades vinculadas. '
                'Para excluí-lo, primeiro remova todos os vínculos.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendi'),
                ),
              ],
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar contrato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Confirmar exclusão
    if (mounted) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o contrato "${contrato.nome}"?\n\n'
            'Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Excluir'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        try {
          await _contratoService.excluirContrato(contrato.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contrato excluído com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao excluir contrato: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }
}
