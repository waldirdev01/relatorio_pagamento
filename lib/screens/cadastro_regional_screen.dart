import 'package:flutter/material.dart';

import '../models/regional.dart';
import '../services/regional_service.dart';

class CadastroRegionalScreen extends StatefulWidget {
  final Regional? regional;

  const CadastroRegionalScreen({super.key, this.regional});

  @override
  State<CadastroRegionalScreen> createState() => _CadastroRegionalScreenState();
}

class _CadastroRegionalScreenState extends State<CadastroRegionalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _regionalService = RegionalService();
  bool _isLoading = false;

  bool get _isEditing => widget.regional != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _descricaoController.text = widget.regional!.descricao;
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(_isEditing ? 'Editar Regional' : 'Nova Regional'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        _isEditing ? Icons.edit_location : Icons.add_location,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isEditing ? 'Editar Regional' : 'Nova Regional',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditing
                            ? 'Atualize as informações da regional'
                            : 'Preencha os dados para criar uma nova regional',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Formulário
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informações da Regional',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Campo Descrição
                      TextFormField(
                        controller: _descricaoController,
                        decoration: InputDecoration(
                          labelText: 'Descrição *',
                          hintText: 'Ex: Regional Norte, Regional Sul',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'A descrição é obrigatória';
                          }
                          if (value.trim().length < 3) {
                            return 'A descrição deve ter pelo menos 3 caracteres';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: 24),

                      // Informações adicionais (se editando)
                      if (_isEditing) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informações do Sistema',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: ${widget.regional!.id}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                'Criada em: ${_formatDate(widget.regional!.dataCriacao)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (widget.regional!.dataAtualizacao != null)
                                Text(
                                  'Última atualização: ${_formatDate(widget.regional!.dataAtualizacao!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _salvarRegional,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(_isEditing ? 'Atualizar' : 'Salvar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvarRegional() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final descricao = _descricaoController.text.trim();

      // Verificar se já existe regional com a mesma descrição
      final existe = await _regionalService.existeRegionalComDescricao(
        descricao,
        excludeId: _isEditing ? widget.regional!.id : null,
      );

      if (existe) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Já existe uma regional com esta descrição'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (_isEditing) {
        // Atualizar regional existente
        final regionalAtualizada = widget.regional!.copyWith(
          descricao: descricao,
          dataAtualizacao: DateTime.now(),
        );
        await _regionalService.atualizarRegional(regionalAtualizada);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Regional atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        // Criar nova regional
        final novaRegional = Regional(
          id: '', // Será definido pelo Firestore
          descricao: descricao,
          dataCriacao: DateTime.now(),
        );
        await _regionalService.adicionarRegional(novaRegional);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Regional criada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar regional: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} às '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
