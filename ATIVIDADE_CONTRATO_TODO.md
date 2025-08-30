# Pendências para Atividade Extracurricular

## ✅ Já feito:
- Import ContratoService e modelo Contrato
- Variáveis _contratosDisponiveis e _contratoSelecionado
- Chamada _loadContratos() no initState

## 🔄 Ainda falta:

### 1. Adicionar método _loadContratos():
```dart
Future<void> _loadContratos() async {
  try {
    final contratos = await _contratoService.buscarContratosPorRegional(
      widget.regional.id,
    );
    setState(() {
      _contratosDisponiveis = contratos;
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
```

### 2. Criar _buildContratoDropdown():
```dart
Widget _buildContratoDropdown() {
  return DropdownButtonFormField<Contrato>(
    value: _contratoSelecionado,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              contrato.nome,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'R\$ ${contrato.valorPorKm.toStringAsFixed(2)}/km',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
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
```

### 3. Adicionar dropdown no formulário (após turno)
### 4. Atualizar _loadAtividadeData para carregar contrato
### 5. Incluir contratoId na criação da AtividadeExtracurricular
### 6. Remover _contratoIdController do dispose()

**Status: Parcialmente implementado - necessário continuar implementação manual**
