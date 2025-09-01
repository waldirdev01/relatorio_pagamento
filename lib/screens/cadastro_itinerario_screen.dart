import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/contrato.dart';
import '../models/escola.dart';
import '../models/itinerario.dart';
import '../models/regional.dart';
import '../models/turno.dart';
import '../services/contrato_service.dart';
import '../services/escola_service.dart';
import '../services/itinerario_service.dart';
import '../utils/currency_formatter.dart';

class CadastroItinerarioScreen extends StatefulWidget {
  final Regional regional;
  final Itinerario? itinerario;

  const CadastroItinerarioScreen({
    super.key,
    required this.regional,
    this.itinerario,
  });

  @override
  State<CadastroItinerarioScreen> createState() =>
      _CadastroItinerarioScreenState();
}

class _CadastroItinerarioScreenState extends State<CadastroItinerarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itinerarioService = ItinerarioService();
  final _escolaService = EscolaService();
  final _contratoService = ContratoService();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _itinerarioController;
  late TextEditingController _trajetoController;
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

  // Estado
  TipoTurno? _turnoSelecionado;
  List<Escola> _escolasDisponiveis = [];
  List<String> _escolasSelecionadasIds = [];

  // Contratos
  List<Contrato> _contratosDisponiveis = [];
  Contrato? _contratoSelecionado;

  bool get _isEditing => widget.itinerario != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadEscolas();
    _loadContratos();
    if (_isEditing) {
      _loadItinerarioData();
    }
  }

  void _initializeControllers() {
    _itinerarioController = TextEditingController();
    _trajetoController = TextEditingController();
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
  }

  Future<void> _loadContratos() async {
    try {
      final contratos = await _contratoService.buscarContratosPorRegional(
        widget.regional.id,
      );
      setState(() {
        _contratosDisponiveis = contratos;
        // Após carregar os contratos, selecionar o contrato se estivermos editando
        if (_isEditing && widget.itinerario?.contratoId != null) {
          _contratoSelecionado = _contratosDisponiveis
              .where((c) => c.id == widget.itinerario!.contratoId)
              .firstOrNull;
        }
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

  void _loadItinerarioData() {
    final itinerario = widget.itinerario!;
    _itinerarioController.text = itinerario.itinerario;
    _turnoSelecionado = itinerario.turno;
    _escolasSelecionadasIds = List.from(itinerario.escolaIds);
    _trajetoController.text = itinerario.trajeto;
    _eiController.text = itinerario.ei?.toString() ?? '';
    _efController.text = itinerario.ef?.toString() ?? '';
    _emController.text = itinerario.em?.toString() ?? '';
    _eeController.text = itinerario.ee?.toString() ?? '';
    _ejaController.text = itinerario.eja?.toString() ?? '';
    _numeroOnibusController.text = itinerario.numeroOnibus.toString();
    _placasController.text = itinerario.placas;
    _kmController.text = itinerario.km.toString();
    _diasTrabalhadosController.text = itinerario.diasTrabalhados.toString();
    _motoristasController.text = itinerario.motoristas;
    _monitorasController.text = itinerario.monitoras;

    // A seleção do contrato agora é feita no método _loadContratos()
    // após os contratos serem carregados
  }

  @override
  void dispose() {
    _itinerarioController.dispose();
    _trajetoController.dispose();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Itinerário' : 'Novo Itinerário'),
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
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações Básicas',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _itinerarioController,
                              label: 'Itinerário *',
                              hint: 'Ex: Rota 001',
                              validator: (value) =>
                                  _validateRequired(value, 'Itinerário'),
                            ),
                            const SizedBox(height: 16),
                            _buildTurnoDropdown(),
                            const SizedBox(height: 16),
                            _buildContratoDropdown(),
                            const SizedBox(height: 16),
                            _buildEscolasSelector(),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _trajetoController,
                              label: 'Trajeto *',
                              hint: 'Descrição do trajeto',
                              validator: (value) =>
                                  _validateRequired(value, 'Trajeto'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contadores de Alunos
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contadores de Alunos',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                    ),
                    const SizedBox(height: 16),

                    // Informações de Transporte
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações de Transporte',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                                    validator: (value) =>
                                        _validateRequired(value, 'Nº ÔNIBUS'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _placasController,
                                    label: 'Placas *',
                                    hint: 'Ex: ABC-1234, DEF-5678, GHI-9012',
                                    validator: (value) =>
                                        _validateRequired(value, 'Placas'),
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
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (value) =>
                                        _validateRequired(value, 'KM'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _diasTrabalhadosController,
                                    label: 'DIAS TRAB. *',
                                    hint: 'Ex: 20',
                                    keyboardType: TextInputType.number,
                                    validator: (value) =>
                                        _validateDiasTrabalhados(value),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pessoal
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pessoal',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _motoristasController,
                              label: 'Motoristas *',
                              hint: 'Nome dos motoristas',
                              validator: (value) =>
                                  _validateRequired(value, 'Motoristas'),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _monitorasController,
                              label: 'Monitoras *',
                              hint: 'Nome das monitoras',
                              validator: (value) =>
                                  _validateRequired(value, 'Monitoras'),
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
                            onPressed: _isLoading ? null : _salvarItinerario,
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

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
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

  String? _validateEscolas() {
    if (_escolasSelecionadasIds.isEmpty) {
      return 'Pelo menos uma escola deve ser selecionada';
    }
    return null;
  }

  String? _validateDiasTrabalhados(String? value) {
    if (value == null || value.isEmpty) {
      return 'Dias trabalhados é obrigatório';
    }

    final dias = int.tryParse(value);
    if (dias == null) {
      return 'Digite um número válido';
    }

    if (dias <= 0) {
      return 'Deve ser maior que zero';
    }

    if (dias > 30) {
      return 'Não pode ter mais de 30 dias trabalhados';
    }

    return null;
  }

  Future<bool> _confirmarDiasTrabalhados(int dias) async {
    if (dias <= 24) return true;

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('⚠️ Muitos dias trabalhados'),
              content: Text(
                'Você inseriu $dias dias trabalhados. '
                'O normal são até 22 dias úteis no mês.\n\n'
                'Tem certeza que deseja continuar?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildTurnoDropdown() {
    return DropdownButtonFormField<TipoTurno>(
      initialValue: _turnoSelecionado,
      decoration: InputDecoration(
        labelText: 'Turno *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value == null) {
          return 'Turno é obrigatório';
        }
        return null;
      },
      items: TipoTurno.values.map((TipoTurno turno) {
        return DropdownMenuItem<TipoTurno>(
          value: turno,
          child: Text(turno.descricaoCompleta),
        );
      }).toList(),
      onChanged: (TipoTurno? newValue) {
        setState(() {
          _turnoSelecionado = newValue;
        });
      },
    );
  }

  Widget _buildContratoDropdown() {
    return DropdownButtonFormField<Contrato>(
      initialValue: _contratoSelecionado,
      decoration: InputDecoration(
        labelText: 'Contrato *',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.description),
        helperText: 'Selecione o contrato para este itinerário',
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
                CurrencyFormatter.formatWithUnit(contrato.valorPorKm, 'km'),
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

  Future<void> _salvarItinerario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar escolas selecionadas
    final escolasError = _validateEscolas();
    if (escolasError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(escolasError), backgroundColor: Colors.red),
      );
      return;
    }

    // Validar dias trabalhados (confirmação se >24)
    final diasTrabalhados = int.parse(_diasTrabalhadosController.text);
    final confirmarDias = await _confirmarDiasTrabalhados(diasTrabalhados);
    if (!confirmarDias) {
      return; // Usuário cancelou
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar se já existe itinerário com a mesma descrição
      final existeSimilar = await _itinerarioService
          .existeItinerarioComDescricao(
            widget.regional.id,
            _itinerarioController.text.trim(),
            excludeId: _isEditing ? widget.itinerario!.id : null,
          );

      if (existeSimilar) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Já existe um itinerário com esta descrição nesta regional.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final itinerario = Itinerario(
        id: _isEditing ? widget.itinerario!.id : '',
        regionalId: widget.regional.id,
        contratoId: _contratoSelecionado?.id,
        itinerario: _itinerarioController.text.trim(),
        turno: _turnoSelecionado!,
        escolaIds: List.from(_escolasSelecionadasIds),
        trajeto: _trajetoController.text.trim(),
        ei: int.tryParse(_eiController.text) ?? 0,
        ef: int.tryParse(_efController.text) ?? 0,
        em: int.tryParse(_emController.text) ?? 0,
        ee: int.tryParse(_eeController.text) ?? 0,
        eja: int.tryParse(_ejaController.text) ?? 0,
        total: 0, // Será calculado
        numeroOnibus: int.parse(_numeroOnibusController.text),
        placas: _placasController.text.trim().toUpperCase(),
        km: double.parse(_kmController.text),
        kmXNumeroOnibus: 0, // Será calculado
        diasTrabalhados: int.parse(_diasTrabalhadosController.text),
        kmXNumeroOnibusXDias: 0, // Será calculado
        motoristas: _motoristasController.text.trim(),
        monitoras: _monitorasController.text.trim(),
        dataCriacao: _isEditing
            ? widget.itinerario!.dataCriacao
            : DateTime.now(),
      ).calcularTotais();

      if (_isEditing) {
        await _itinerarioService.atualizarItinerario(itinerario);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Itinerário atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        await _itinerarioService.adicionarItinerario(itinerario);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Itinerário adicionado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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
