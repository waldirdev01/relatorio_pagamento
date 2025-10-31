import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/itinerario.dart';
import '../models/regional.dart';
import '../models/reposicao_aula.dart';
import '../models/turno.dart';
import '../services/auth_service.dart';
import '../services/escola_service.dart';
import '../services/reposicao_aula_service.dart';

class CadastroReposicaoScreen extends StatefulWidget {
  final Regional regional;
  final Itinerario itinerario;
  final ReposicaoAula? reposicao;

  const CadastroReposicaoScreen({
    super.key,
    required this.regional,
    required this.itinerario,
    this.reposicao,
  });

  @override
  State<CadastroReposicaoScreen> createState() =>
      _CadastroReposicaoScreenState();
}

class _CadastroReposicaoScreenState extends State<CadastroReposicaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reposicaoService = ReposicaoAulaService();
  final _escolaService = EscolaService();
  final _authService = AuthService();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _kmController;
  late TextEditingController _numeroOnibusController;
  late TextEditingController _diasTrabalhadosController;
  late TextEditingController _observacoesController;

  // Datas
  DateTime? _dataSolicitacao;
  DateTime? _dataReposicao;

  bool get _isEditing => widget.reposicao != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (_isEditing) {
      _loadReposicaoData();
    }
  }

  void _initializeControllers() {
    // Pré-preencher com valores do itinerário
    _kmController = TextEditingController(
      text: widget.itinerario.km.toString(),
    );
    _numeroOnibusController = TextEditingController(
      text: widget.itinerario.numeroOnibus.toString(),
    );
    _diasTrabalhadosController = TextEditingController();
    _observacoesController = TextEditingController();
  }

  void _loadReposicaoData() {
    final reposicao = widget.reposicao!;
    _kmController.text = reposicao.km.toString();
    _numeroOnibusController.text = reposicao.numeroOnibus.toString();
    _diasTrabalhadosController.text = reposicao.diasTrabalhados.toString();
    _observacoesController.text = reposicao.observacoes ?? '';
    _dataSolicitacao = reposicao.dataSolicitacao;
    _dataReposicao = reposicao.dataReposicao;
  }

  @override
  void dispose() {
    _kmController.dispose();
    _numeroOnibusController.dispose();
    _diasTrabalhadosController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Reposição' : 'Nova Reposição de Aula'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Informações do itinerário
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Itinerário de Referência',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(widget.itinerario.itinerario),
                            FutureBuilder<List<String>>(
                              future: _escolaService.getNomesEscolas(
                                widget.itinerario.escolaIds,
                              ),
                              builder: (context, snapshot) {
                                final escolasNomes = snapshot.data ?? [];
                                final escolasText = escolasNomes.isEmpty
                                    ? 'Nenhuma escola'
                                    : escolasNomes.join(', ');
                                return Text(
                                  '$escolasText - ${widget.itinerario.turno.descricao}',
                                );
                              },
                            ),
                            Text('Trajeto: ${widget.itinerario.trajeto}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campos da reposição
                    Text(
                      'Dados da Reposição',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _kmController,
                      label: 'KM *',
                      hint: 'Ex: 15.5',
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => _validateRequired(value, 'KM'),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _numeroOnibusController,
                      label: 'Nº ÔNIBUS *',
                      hint: 'Ex: 1',
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _validateRequired(value, 'Nº ÔNIBUS'),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _diasTrabalhadosController,
                      label: 'DIAS TRAB. *',
                      hint: 'Ex: 2',
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          _validateRequired(value, 'DIAS TRAB.'),
                    ),
                    const SizedBox(height: 16),

                    // Campos de data
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Data de Solicitação',
                            value: _dataSolicitacao,
                            onTap: () => _selectDataSolicitacao(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: 'Data da Reposição',
                            value: _dataReposicao,
                            onTap: () => _selectDataReposicao(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _observacoesController,
                      label: 'Observações',
                      hint: 'Motivo da reposição, etc.',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Cálculos automáticos
                    Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cálculos Automáticos',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildCalculoRow(
                              'KM X Nº ÔNIBUS',
                              _calcularKmXNumeroOnibus(),
                            ),
                            _buildCalculoRow(
                              'KM X Nº ÔNIBUS X DIAS TRAB.',
                              _calcularKmXNumeroOnibusXDias(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _salvarReposicao,
                            child: Text(_isEditing ? 'Atualizar' : 'Salvar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      inputFormatters:
          keyboardType == TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
    );
  }

  Widget _buildCalculoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _calcularKmXNumeroOnibus() {
    final km = double.tryParse(_kmController.text) ?? 0;
    final numeroOnibus = int.tryParse(_numeroOnibusController.text) ?? 0;
    return (km * numeroOnibus).toStringAsFixed(2);
  }

  String _calcularKmXNumeroOnibusXDias() {
    final km = double.tryParse(_kmController.text) ?? 0;
    final numeroOnibus = int.tryParse(_numeroOnibusController.text) ?? 0;
    final dias = int.tryParse(_diasTrabalhadosController.text) ?? 0;
    return (km * numeroOnibus * dias).toStringAsFixed(2);
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
              : 'Selecionar data',
          style: value != null
              ? null
              : TextStyle(color: Theme.of(context).hintColor),
        ),
      ),
    );
  }

  Future<void> _selectDataSolicitacao() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSolicitacao ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dataSolicitacao) {
      setState(() {
        _dataSolicitacao = picked;
      });
    }
  }

  Future<void> _selectDataReposicao() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataReposicao ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dataReposicao) {
      setState(() {
        _dataReposicao = picked;
      });
    }
  }

  Future<void> _salvarReposicao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final km = double.parse(_kmController.text);
      final numeroOnibus = int.parse(_numeroOnibusController.text);
      final diasTrabalhados = int.parse(_diasTrabalhadosController.text);

      // Verificar se já existe reposição similar
      final existeSimilar = await _reposicaoService.existeReposicaoSimilar(
        itinerarioId: widget.itinerario.id,
        km: km,
        numeroOnibus: numeroOnibus,
        diasTrabalhados: diasTrabalhados,
        excluirId: _isEditing ? widget.reposicao!.id : null,
      );

      if (existeSimilar) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Já existe uma reposição com os mesmos dados para este itinerário.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final reposicao = ReposicaoAula.calcularValores(
        id: _isEditing ? widget.reposicao!.id : '',
        itinerarioId: widget.itinerario.id,
        regionalId: widget.regional.id,
        km: km,
        numeroOnibus: numeroOnibus,
        diasTrabalhados: diasTrabalhados,
        dataCriacao: _isEditing
            ? widget.reposicao!.dataCriacao
            : DateTime.now(),
        observacoes: _observacoesController.text.trim().isNotEmpty
            ? _observacoesController.text.trim()
            : null,
        dataSolicitacao: _dataSolicitacao,
        dataReposicao: _dataReposicao,
      );

      if (_isEditing) {
        // Obter usuário atual para registrar quem está editando
        final usuarioAtual = await _authService.getUsuarioAtual();
        final usuarioId = usuarioAtual?.id;

        final sucesso = await _reposicaoService.atualizarReposicao(
          reposicao,
          usuarioId,
        );
        if (sucesso && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reposição atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao atualizar reposição.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Obter usuário atual para registrar quem está criando
        final usuarioAtual = await _authService.getUsuarioAtual();
        final usuarioId = usuarioAtual?.id;

        final id = await _reposicaoService.adicionarReposicao(
          reposicao,
          usuarioId,
        );
        if (id != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reposição adicionada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao adicionar reposição.'),
              backgroundColor: Colors.red,
            ),
          );
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
