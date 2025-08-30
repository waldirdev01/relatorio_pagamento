import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/atividade_extracurricular.dart';
import '../models/contrato.dart';
import '../models/escola.dart';
import '../models/regional.dart';
import '../models/turno.dart';
import '../services/atividade_extracurricular_service.dart';
import '../services/contrato_service.dart';
import '../services/escola_service.dart';

class CadastroAtividadeExtracurricularScreen extends StatefulWidget {
  final Regional regional;
  final AtividadeExtracurricular? atividade;

  const CadastroAtividadeExtracurricularScreen({
    super.key,
    required this.regional,
    this.atividade,
  });

  @override
  State<CadastroAtividadeExtracurricularScreen> createState() =>
      _CadastroAtividadeExtracurricularScreenState();
}

class _CadastroAtividadeExtracurricularScreenState
    extends State<CadastroAtividadeExtracurricularScreen> {
  final _formKey = GlobalKey<FormState>();
  final _atividadeService = AtividadeExtracurricularService();
  final _escolaService = EscolaService();
  final _contratoService = ContratoService();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _descricaoController;
  late TextEditingController _trajetoController;
  late TextEditingController _codigoTcbController;
  late TextEditingController _motivoCancelamentoController;
  late TextEditingController _eiController;
  late TextEditingController _efController;
  late TextEditingController _emController;
  late TextEditingController _eeController;
  late TextEditingController _ejaController;
  late TextEditingController _numeroOnibusController;
  late TextEditingController _placasController;
  late TextEditingController _kmController;
  late TextEditingController _diasTrabalhadosController;
  late TextEditingController _motoristasController;
  late TextEditingController _monitorasController;
  late TextEditingController _observacoesController;

  // Estado
  TipoTurno? _turnoSelecionado;
  StatusAtividadeExtracurricular _statusSelecionado =
      StatusAtividadeExtracurricular.criada;
  DateTime? _dataSolicitacao;
  DateTime? _dataAtividade;
  List<Escola> _escolasDisponiveis = [];
  List<String> _escolasSelecionadasIds = [];

  // Contratos
  final List<Contrato> _contratosDisponiveis = [];
  Contrato? _contratoSelecionado;

  bool get _isEditing => widget.atividade != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadEscolas();
    _loadContratos();
    if (_isEditing) {
      _loadAtividadeData();
    }
  }

  void _initializeControllers() {
    _descricaoController = TextEditingController();
    _trajetoController = TextEditingController();
    _codigoTcbController = TextEditingController();
    _motivoCancelamentoController = TextEditingController();
    _eiController = TextEditingController();
    _efController = TextEditingController();
    _emController = TextEditingController();
    _eeController = TextEditingController();
    _ejaController = TextEditingController();
    _numeroOnibusController = TextEditingController();
    _placasController = TextEditingController();
    _kmController = TextEditingController();
    _diasTrabalhadosController = TextEditingController();
    _motoristasController = TextEditingController();
    _monitorasController = TextEditingController();
    _observacoesController = TextEditingController();
  }

  Future<void> _loadContratos() async {
    try {
      final contratos = await _contratoService.buscarContratosPorRegional(
        widget.regional.id,
      );
      setState(() {
        _contratosDisponiveis.addAll(contratos);
      });
    } catch (e) {
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

  Future<void> _loadEscolas() async {
    try {
      final escolas = await _escolaService.getEscolasPorRegionalFuture(
        widget.regional.id,
      );
      setState(() {
        _escolasDisponiveis = escolas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar escolas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadAtividadeData() {
    final atividade = widget.atividade!;
    _descricaoController.text = atividade.descricao;
    _turnoSelecionado = atividade.turno;

    // Buscar e selecionar o contrato
    if (atividade.contratoId.isNotEmpty) {
      _contratoSelecionado = _contratosDisponiveis
          .where((c) => c.id == atividade.contratoId)
          .firstOrNull;
    }
    _statusSelecionado = atividade.status;
    _escolasSelecionadasIds = List.from(atividade.escolaIds);
    _trajetoController.text = atividade.trajeto;
    _codigoTcbController.text = atividade.codigoTcb ?? '';
    _motivoCancelamentoController.text = atividade.motivoCancelamento ?? '';
    _dataSolicitacao = atividade.dataSolicitacao;
    _dataAtividade = atividade.dataAtividade;
    _eiController.text = atividade.ei?.toString() ?? '';
    _efController.text = atividade.ef?.toString() ?? '';
    _emController.text = atividade.em?.toString() ?? '';
    _eeController.text = atividade.ee?.toString() ?? '';
    _ejaController.text = atividade.eja?.toString() ?? '';
    _numeroOnibusController.text = atividade.numeroOnibus.toString();
    _placasController.text = atividade.placas;
    _kmController.text = atividade.km.toString();
    _diasTrabalhadosController.text = atividade.diasTrabalhados.toString();
    _motoristasController.text = atividade.motoristas;
    _monitorasController.text = atividade.monitoras;
    _observacoesController.text = atividade.observacoes ?? '';
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _trajetoController.dispose();
    _codigoTcbController.dispose();
    _motivoCancelamentoController.dispose();
    _eiController.dispose();
    _efController.dispose();
    _emController.dispose();
    _eeController.dispose();
    _ejaController.dispose();
    _numeroOnibusController.dispose();
    _placasController.dispose();
    _kmController.dispose();
    _diasTrabalhadosController.dispose();
    _motoristasController.dispose();
    _monitorasController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Widget _buildContratoDropdown() {
    return DropdownButtonFormField<Contrato>(
      initialValue: _contratoSelecionado,
      decoration: InputDecoration(
        labelText: 'Contrato *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.description),
        helperText: 'Selecione o contrato para esta atividade',
      ),
      validator: (value) {
        if (value == null) {
          return 'Contrato é obrigatório';
        }
        return null;
      },
      items: _contratosDisponiveis.map((Contrato contrato) {
        return DropdownMenuItem<Contrato>(
          value: contrato,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  contrato.nome,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'R\$ ${contrato.valorPorKm.toStringAsFixed(2)}/km',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (Contrato? newValue) {
        setState(() {
          _contratoSelecionado = newValue;
        });
      },
      isExpanded: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Atividade' : 'Nova Atividade'),
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
                    // Informações Básicas
                    _buildBasicInfoCard(),
                    const SizedBox(height: 16),

                    // Status e Controle
                    _buildStatusCard(),
                    const SizedBox(height: 16),

                    // Contadores de Alunos
                    _buildStudentCountCard(),
                    const SizedBox(height: 16),

                    // Informações de Transporte
                    _buildTransportCard(),
                    const SizedBox(height: 16),

                    // Pessoal
                    _buildPersonnelCard(),
                    const SizedBox(height: 16),

                    // Observações
                    _buildObservationsCard(),
                    const SizedBox(height: 32),

                    // Botões
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações Básicas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descricaoController,
              label: 'Descrição da Atividade *',
              hint: 'Ex: Atividade Cultural - Festa Junina',
              validator: (value) => _validateRequired(value, 'Descrição'),
            ),
            const SizedBox(height: 16),
            _buildContratoDropdown(),
            const SizedBox(height: 16),
            _buildTurnoDropdown(),
            const SizedBox(height: 16),
            _buildEscolasSelector(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _trajetoController,
              label: 'Trajeto *',
              hint: 'Descrição do trajeto da atividade',
              validator: (value) => _validateRequired(value, 'Trajeto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status e Controle',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusDropdown(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _codigoTcbController,
              label: 'Código TCB',
              hint: 'Código fornecido pela TCB',
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Data de Solicitação',
              selectedDate: _dataSolicitacao,
              onDateSelected: (date) => setState(() => _dataSolicitacao = date),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Data da Atividade',
              selectedDate: _dataAtividade,
              onDateSelected: (date) => setState(() => _dataAtividade = date),
            ),
            if (_statusSelecionado ==
                    StatusAtividadeExtracurricular.cancelada ||
                _statusSelecionado ==
                    StatusAtividadeExtracurricular.reprovada) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _motivoCancelamentoController,
                label: 'Motivo do Cancelamento/Reprovação *',
                hint: 'Descreva o motivo detalhadamente',
                maxLines: 3,
                validator: (value) => _validateRequired(value, 'Motivo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCountCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contadores de Alunos',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _eiController,
                    label: 'EI',
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _efController,
                    label: 'EF',
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _emController,
                    label: 'EM',
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _eeController,
                    label: 'EE',
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _ejaController,
                    label: 'EJA',
                    hint: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Container()), // Espaço vazio
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações de Transporte',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _numeroOnibusController,
                    label: 'Nº ÔNIBUS *',
                    hint: '1',
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateRequired(value, 'Nº ÔNIBUS'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _placasController,
                    label: 'Placas *',
                    hint: 'Ex: ABC-1234, DEF-5678',
                    validator: (value) => _validateRequired(value, 'Placas'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _kmController,
                    label: 'KM *',
                    hint: 'Ex: 15.5',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => _validateRequired(value, 'KM'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _diasTrabalhadosController,
                    label: 'DIAS TRAB. *',
                    hint: 'Ex: 1',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        _validateRequired(value, 'DIAS TRAB.'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pessoal',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _motoristasController,
              label: 'Motoristas *',
              hint: 'Nome dos motoristas',
              validator: (value) => _validateRequired(value, 'Motoristas'),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _monitorasController,
              label: 'Monitoras *',
              hint: 'Nome das monitoras',
              validator: (value) => _validateRequired(value, 'Monitoras'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observações',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _observacoesController,
              label: 'Observações Gerais',
              hint: 'Informações adicionais sobre a atividade',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _salvarAtividade,
            child: Text(_isEditing ? 'Atualizar' : 'Salvar'),
          ),
        ),
      ],
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
          keyboardType == const TextInputType.numberWithOptions(decimal: true)
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
    );
  }

  Widget _buildTurnoDropdown() {
    return DropdownButtonFormField<TipoTurno>(
      initialValue: _turnoSelecionado,
      decoration: InputDecoration(
        labelText: 'Turno *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: TipoTurno.values.map((turno) {
        return DropdownMenuItem(value: turno, child: Text(turno.descricao));
      }).toList(),
      onChanged: (value) => setState(() => _turnoSelecionado = value),
      validator: (value) => value == null ? 'Turno é obrigatório' : null,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<StatusAtividadeExtracurricular>(
      initialValue: _statusSelecionado,
      decoration: InputDecoration(
        labelText: 'Status *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: StatusAtividadeExtracurricular.values.map((status) {
        return DropdownMenuItem(value: status, child: Text(status.descricao));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _statusSelecionado = value;
            // Limpar motivo se mudou para status que não precisa
            if (value != StatusAtividadeExtracurricular.cancelada &&
                value != StatusAtividadeExtracurricular.reprovada) {
              _motivoCancelamentoController.clear();
            }
          });
        }
      },
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDate(onDateSelected),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : 'Selecionar data',
          style: TextStyle(
            color: selectedDate != null ? null : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(Function(DateTime?) onDateSelected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    onDateSelected(date);
  }

  Widget _buildEscolasSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Escolas *',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_escolasSelecionadasIds.isNotEmpty)
              Text(
                '${_escolasSelecionadasIds.length} selecionada(s)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              if (_escolasSelecionadasIds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Nenhuma escola selecionada',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ..._buildSelectedSchools(),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _showSchoolSelector,
                  icon: const Icon(Icons.add),
                  label: Text(
                    _escolasSelecionadasIds.isEmpty
                        ? 'Selecionar Escolas'
                        : 'Adicionar Mais Escolas',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_escolasSelecionadasIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Escolas é obrigatório',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSelectedSchools() {
    return _escolasSelecionadasIds.map((escolaId) {
      final escola = _escolasDisponiveis.firstWhere(
        (e) => e.id == escolaId,
        orElse: () => Escola(
          id: escolaId,
          nome: 'Escola não encontrada',
          classificacao: ClassificacaoEscola.urbana,
          regionalId: widget.regional.id,
          dataCriacao: DateTime.now(),
        ),
      );

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Chip(
          label: Text(
            '${escola.nome} (${escola.classificacao.descricao})',
            style: const TextStyle(fontSize: 12),
          ),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {
            setState(() {
              _escolasSelecionadasIds.remove(escolaId);
            });
          },
        ),
      );
    }).toList();
  }

  void _showSchoolSelector() {
    showDialog(
      context: context,
      builder: (context) => _SchoolSelectorDialog(
        escolasDisponiveis: _escolasDisponiveis,
        escolasSelecionadas: _escolasSelecionadasIds,
        onSelectionChanged: (selectedIds) {
          setState(() {
            _escolasSelecionadasIds = selectedIds;
          });
        },
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  Future<void> _salvarAtividade() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_escolasSelecionadasIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma escola'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ei = int.tryParse(_eiController.text.trim());
      final ef = int.tryParse(_efController.text.trim());
      final em = int.tryParse(_emController.text.trim());
      final ee = int.tryParse(_eeController.text.trim());
      final eja = int.tryParse(_ejaController.text.trim());
      final total = (ei ?? 0) + (ef ?? 0) + (em ?? 0) + (ee ?? 0) + (eja ?? 0);
      final numeroOnibus = int.parse(_numeroOnibusController.text.trim());
      final km = double.parse(_kmController.text.trim());
      final diasTrabalhados = int.parse(_diasTrabalhadosController.text.trim());
      final kmXNumeroOnibus = km * numeroOnibus;
      final kmXNumeroOnibusXDias = kmXNumeroOnibus * diasTrabalhados;

      final atividade = AtividadeExtracurricular(
        id: _isEditing ? widget.atividade!.id : '',
        regionalId: widget.regional.id,
        contratoId: _contratoSelecionado?.id ?? '',
        descricao: _descricaoController.text.trim(),
        turno: _turnoSelecionado!,
        escolaIds: _escolasSelecionadasIds,
        trajeto: _trajetoController.text.trim(),
        status: _statusSelecionado,
        codigoTcb: _codigoTcbController.text.trim().isEmpty
            ? null
            : _codigoTcbController.text.trim(),
        dataSolicitacao: _dataSolicitacao,
        dataAtividade: _dataAtividade,
        motivoCancelamento: _motivoCancelamentoController.text.trim().isEmpty
            ? null
            : _motivoCancelamentoController.text.trim(),
        ei: ei,
        ef: ef,
        em: em,
        ee: ee,
        eja: eja,
        total: total,
        numeroOnibus: numeroOnibus,
        placas: _placasController.text.trim(),
        km: km,
        kmXNumeroOnibus: kmXNumeroOnibus,
        diasTrabalhados: diasTrabalhados,
        kmXNumeroOnibusXDias: kmXNumeroOnibusXDias,
        motoristas: _motoristasController.text.trim(),
        monitoras: _monitorasController.text.trim(),
        dataCriacao: _isEditing
            ? widget.atividade!.dataCriacao
            : DateTime.now(),
        dataAtualizacao: _isEditing ? DateTime.now() : null,
        observacoes: _observacoesController.text.trim().isEmpty
            ? null
            : _observacoesController.text.trim(),
      );

      String? result;
      if (_isEditing) {
        final success = await _atividadeService.atualizarAtividade(atividade);
        result = success ? 'success' : null;
      } else {
        result = await _atividadeService.adicionarAtividade(atividade);
      }

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Atividade atualizada com sucesso!'
                    : 'Atividade criada com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? 'Erro ao atualizar atividade'
                    : 'Erro ao criar atividade',
              ),
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
        setState(() => _isLoading = false);
      }
    }
  }
}

class _SchoolSelectorDialog extends StatefulWidget {
  final List<Escola> escolasDisponiveis;
  final List<String> escolasSelecionadas;
  final Function(List<String>) onSelectionChanged;

  const _SchoolSelectorDialog({
    required this.escolasDisponiveis,
    required this.escolasSelecionadas,
    required this.onSelectionChanged,
  });

  @override
  State<_SchoolSelectorDialog> createState() => _SchoolSelectorDialogState();
}

class _SchoolSelectorDialogState extends State<_SchoolSelectorDialog> {
  late List<String> _tempSelectedIds;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = List.from(widget.escolasSelecionadas);
  }

  List<Escola> get _filteredSchools {
    if (_searchText.isEmpty) {
      return widget.escolasDisponiveis;
    }
    return widget.escolasDisponiveis
        .where(
          (escola) =>
              escola.nome.toLowerCase().contains(_searchText.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selecionar Escolas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar escola',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_tempSelectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_tempSelectedIds.length} escola(s) selecionada(s)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredSchools.isEmpty
                  ? const Center(child: Text('Nenhuma escola encontrada'))
                  : ListView.builder(
                      itemCount: _filteredSchools.length,
                      itemBuilder: (context, index) {
                        final escola = _filteredSchools[index];
                        final isSelected = _tempSelectedIds.contains(escola.id);

                        return CheckboxListTile(
                          title: Text(escola.nome),
                          subtitle: Text(
                            escola.classificacao.descricao,
                            style: TextStyle(
                              color:
                                  escola.classificacao ==
                                      ClassificacaoEscola.rural
                                  ? Colors.green[700]
                                  : Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _tempSelectedIds.add(escola.id);
                              } else {
                                _tempSelectedIds.remove(escola.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onSelectionChanged(_tempSelectedIds);
                      Navigator.pop(context);
                    },
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
