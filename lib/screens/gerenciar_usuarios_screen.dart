import 'package:flutter/material.dart';

import '../models/regional.dart';
import '../models/usuario.dart';
import '../services/regional_service.dart';
import '../services/usuario_service.dart';

class GerenciarUsuariosScreen extends StatefulWidget {
  const GerenciarUsuariosScreen({super.key});

  @override
  State<GerenciarUsuariosScreen> createState() =>
      _GerenciarUsuariosScreenState();
}

class _GerenciarUsuariosScreenState extends State<GerenciarUsuariosScreen>
    with SingleTickerProviderStateMixin {
  final _usuarioService = UsuarioService();
  final _regionalService = RegionalService();

  late TabController _tabController;
  List<Regional> _regionais = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarRegionais();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarRegionais() async {
    try {
      final regionais = await _regionalService.getRegionais().first;
      setState(() {
        _regionais = regionais;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar regionais: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_empty), text: 'Aguardando'),
            Tab(icon: Icon(Icons.check_circle), text: 'Aprovados'),
            Tab(icon: Icon(Icons.cancel), text: 'Rejeitados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsuariosAguardando(),
          _buildUsuariosAprovados(),
          _buildUsuariosRejeitados(),
        ],
      ),
    );
  }

  Widget _buildUsuariosAguardando() {
    return StreamBuilder<List<Usuario>>(
      stream: _usuarioService.getUsuariosAguardandoAprovacaoStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Print do erro para debug
          print('❌ [USUARIO] Erro no stream: ${snapshot.error}');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro: ${snapshot.error}'),
                const SizedBox(height: 16),
                const Text(
                  'Verifique o console para o link de criação do índice',
                ),
              ],
            ),
          );
        }

        final usuarios = snapshot.data ?? [];

        if (usuarios.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Nenhum usuário aguardando aprovação'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final usuario = usuarios[index];
            return _buildUsuarioCard(usuario, StatusAprovacao.aguardando);
          },
        );
      },
    );
  }

  Widget _buildUsuariosAprovados() {
    return StreamBuilder<List<Usuario>>(
      stream: _usuarioService.getUsuariosStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Print do erro para debug
          print('❌ [USUARIO] Erro no stream: ${snapshot.error}');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro: ${snapshot.error}'),
                const SizedBox(height: 16),
                const Text(
                  'Verifique o console para o link de criação do índice',
                ),
              ],
            ),
          );
        }

        final todosUsuarios = snapshot.data ?? [];
        final usuariosAprovados = todosUsuarios
            .where((u) => u.statusAprovacao == StatusAprovacao.aprovado)
            .toList();

        if (usuariosAprovados.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Nenhum usuário aprovado'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: usuariosAprovados.length,
          itemBuilder: (context, index) {
            final usuario = usuariosAprovados[index];
            return _buildUsuarioCard(usuario, StatusAprovacao.aprovado);
          },
        );
      },
    );
  }

  Widget _buildUsuariosRejeitados() {
    return StreamBuilder<List<Usuario>>(
      stream: _usuarioService.getUsuariosStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Print do erro para debug
          print('❌ [USUARIO] Erro no stream: ${snapshot.error}');

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erro: ${snapshot.error}'),
                const SizedBox(height: 16),
                const Text(
                  'Verifique o console para o link de criação do índice',
                ),
              ],
            ),
          );
        }

        final todosUsuarios = snapshot.data ?? [];
        final usuariosRejeitados = todosUsuarios
            .where((u) => u.statusAprovacao == StatusAprovacao.rejeitado)
            .toList();

        if (usuariosRejeitados.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Nenhum usuário rejeitado'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: usuariosRejeitados.length,
          itemBuilder: (context, index) {
            final usuario = usuariosRejeitados[index];
            return _buildUsuarioCard(usuario, StatusAprovacao.rejeitado);
          },
        );
      },
    );
  }

  Widget _buildUsuarioCard(Usuario usuario, StatusAprovacao statusAtual) {
    final regional = _regionais.firstWhere(
      (r) => r.id == usuario.regionalId,
      orElse: () => Regional(
        id: '',
        descricao: 'Regional não encontrada',
        dataCriacao: DateTime.now(),
        dataAtualizacao: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com nome e status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(usuario.statusAprovacao),
                  child: Text(
                    usuario.nome.isNotEmpty
                        ? usuario.nome[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nome,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        usuario.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(usuario.statusAprovacao),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        usuario.statusAprovacaoIcon,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        usuario.statusAprovacaoLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Informações do usuário
            _buildInfoRow('Matrícula', usuario.matricula),
            _buildInfoRow('Telefone', usuario.telefone),
            _buildInfoRow('Tipo', usuario.tipoUsuarioLabel),
            if (usuario.tipoUsuario != TipoUsuario.gcote)
              _buildInfoRow('Regional', regional.descricao)
            else
              _buildInfoRow('Regional', 'GCOTE - Acesso Global'),
            _buildInfoRow('Data de Cadastro', _formatDate(usuario.dataCriacao)),

            // Ações
            if (statusAtual == StatusAprovacao.aguardando) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aprovarUsuario(usuario),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aprovar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejeitarUsuario(usuario),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeitar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (statusAtual == StatusAprovacao.aprovado) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editarUsuario(usuario),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _alterarStatusUsuario(usuario, false),
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Desativar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StatusAprovacao status) {
    switch (status) {
      case StatusAprovacao.aguardando:
        return Colors.orange;
      case StatusAprovacao.aprovado:
        return Colors.green;
      case StatusAprovacao.rejeitado:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _aprovarUsuario(Usuario usuario) async {
    try {
      await _usuarioService.aprovarUsuario(usuario.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuário ${usuario.nome} aprovado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao aprovar usuário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejeitarUsuario(Usuario usuario) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Rejeição'),
        content: Text('Deseja realmente rejeitar o usuário "${usuario.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _usuarioService.rejeitarUsuario(usuario.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuário ${usuario.nome} rejeitado.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao rejeitar usuário: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editarUsuario(Usuario usuario) {
    // TODO: Implementar tela de edição de usuário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de edição será implementada em breve'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _alterarStatusUsuario(Usuario usuario, bool ativo) async {
    try {
      await _usuarioService.alterarStatusUsuario(usuario.id, ativo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Usuário ${ativo ? 'ativado' : 'desativado'} com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
