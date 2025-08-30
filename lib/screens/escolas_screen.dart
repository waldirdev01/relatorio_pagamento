import 'package:flutter/material.dart';

import '../models/escola.dart';
import '../models/regional.dart';
import '../services/escola_service.dart';

class EscolasScreen extends StatefulWidget {
  final Regional regional;

  const EscolasScreen({super.key, required this.regional});

  @override
  State<EscolasScreen> createState() => _EscolasScreenState();
}

class _EscolasScreenState extends State<EscolasScreen> {
  final EscolaService _escolaService = EscolaService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escolas - ${widget.regional.descricao}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEscolaDialog(),
            tooltip: 'Nova Escola',
          ),
        ],
      ),
      body: StreamBuilder<List<Escola>>(
        stream: _escolaService.getEscolasPorRegional(widget.regional.id),
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
                    'Erro ao carregar escolas',
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

          final escolas = snapshot.data ?? [];

          if (escolas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma escola encontrada',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione a primeira escola para começar',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showEscolaDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nova Escola'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: escolas.length,
            itemBuilder: (context, index) {
              final escola = escolas[index];
              return _buildEscolaCard(escola);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEscolaDialog(),
        tooltip: 'Nova Escola',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEscolaCard(Escola escola) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: escola.classificacao == ClassificacaoEscola.rural
              ? Colors.green
              : Colors.blue,
          child: Icon(
            escola.classificacao == ClassificacaoEscola.rural
                ? Icons.agriculture
                : Icons.location_city,
            color: Colors.white,
          ),
        ),
        title: Text(
          escola.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          escola.classificacao.descricao,
          style: TextStyle(
            color: escola.classificacao == ClassificacaoEscola.rural
                ? Colors.green[700]
                : Colors.blue[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, escola),
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
      ),
    );
  }

  void _handleMenuAction(String action, Escola escola) {
    switch (action) {
      case 'edit':
        _showEscolaDialog(escola: escola);
        break;
      case 'delete':
        _showDeleteConfirmation(escola);
        break;
    }
  }

  void _showEscolaDialog({Escola? escola}) {
    showDialog(
      context: context,
      builder: (context) => _EscolaDialog(
        regional: widget.regional,
        escola: escola,
        escolaService: _escolaService,
      ),
    );
  }

  void _showDeleteConfirmation(Escola escola) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a escola "${escola.nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEscola(escola);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEscola(Escola escola) async {
    try {
      final success = await _escolaService.excluirEscola(escola.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Escola excluída com sucesso!'
                  : 'Erro ao excluir escola',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir escola: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EscolaDialog extends StatefulWidget {
  final Regional regional;
  final Escola? escola;
  final EscolaService escolaService;

  const _EscolaDialog({
    required this.regional,
    this.escola,
    required this.escolaService,
  });

  @override
  State<_EscolaDialog> createState() => _EscolaDialogState();
}

class _EscolaDialogState extends State<_EscolaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  ClassificacaoEscola _classificacaoSelecionada = ClassificacaoEscola.urbana;
  bool _isLoading = false;

  bool get _isEditing => widget.escola != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nomeController.text = widget.escola!.nome;
      _classificacaoSelecionada = widget.escola!.classificacao;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar Escola' : 'Nova Escola'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da Escola *',
                hintText: 'Ex: Escola Classe 01',
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
            DropdownButtonFormField<ClassificacaoEscola>(
              initialValue: _classificacaoSelecionada,
              decoration: const InputDecoration(
                labelText: 'Classificação *',
                border: OutlineInputBorder(),
              ),
              items: ClassificacaoEscola.values.map((classificacao) {
                return DropdownMenuItem(
                  value: classificacao,
                  child: Row(
                    children: [
                      Icon(
                        classificacao == ClassificacaoEscola.rural
                            ? Icons.agriculture
                            : Icons.location_city,
                        size: 20,
                        color: classificacao == ClassificacaoEscola.rural
                            ? Colors.green
                            : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(classificacao.descricao),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _classificacaoSelecionada = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveEscola,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );
  }

  Future<void> _saveEscola() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar se já existe escola com o mesmo nome
      final existeEscola = await widget.escolaService.existeEscolaNaRegional(
        nome: _nomeController.text.trim(),
        regionalId: widget.regional.id,
        excluirId: _isEditing ? widget.escola!.id : null,
      );

      if (existeEscola) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Já existe uma escola com este nome nesta regional.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (_isEditing) {
        final escolaAtualizada = widget.escola!.copyWith(
          nome: _nomeController.text.trim(),
          classificacao: _classificacaoSelecionada,
        );

        final success = await widget.escolaService.atualizarEscola(
          escolaAtualizada,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Escola atualizada com sucesso!'
                    : 'Erro ao atualizar escola',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) Navigator.pop(context);
        }
      } else {
        final novaEscola = Escola(
          id: '',
          nome: _nomeController.text.trim(),
          classificacao: _classificacaoSelecionada,
          regionalId: widget.regional.id,
          dataCriacao: DateTime.now(),
        );

        final id = await widget.escolaService.adicionarEscola(novaEscola);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                id != null
                    ? 'Escola adicionada com sucesso!'
                    : 'Erro ao adicionar escola',
              ),
              backgroundColor: id != null ? Colors.green : Colors.red,
            ),
          );
          if (id != null) Navigator.pop(context);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
