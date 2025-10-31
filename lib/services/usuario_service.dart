import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/usuario.dart';

class UsuarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'usuarios';

  // Listar todos os usuários
  Future<List<Usuario>> listarUsuarios() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('dataCriacao', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Usuario.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Erro ao listar usuários: $e');
      return [];
    }
  }

  // Stream de usuários
  Stream<List<Usuario>> getUsuariosStream() {
    print('🔍 [USUARIO] Consultando todos os usuários');
    print(
      '📋 [USUARIO] Query: collection(usuarios).orderBy(dataCriacao, descending: true)',
    );

    return _firestore
        .collection(_collection)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          print(
            '📊 [USUARIO] Total de usuários encontrados: ${snapshot.docs.length}',
          );
          return snapshot.docs.map((doc) {
            return Usuario.fromMap({'id': doc.id, ...doc.data()});
          }).toList();
        });
  }

  // Buscar usuários aguardando aprovação
  Future<List<Usuario>> getUsuariosAguardandoAprovacao() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('statusAprovacao', isEqualTo: StatusAprovacao.aguardando.name)
          .orderBy('dataCriacao', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Usuario.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Erro ao buscar usuários aguardando aprovação: $e');
      return [];
    }
  }

  // Stream de usuários aguardando aprovação
  Stream<List<Usuario>> getUsuariosAguardandoAprovacaoStream() {
    print('🔍 [USUARIO] Consultando usuários aguardando aprovação');
    print(
      '📋 [USUARIO] Query: collection(usuarios).where(statusAprovacao == aguardando).orderBy(dataCriacao, descending: true)',
    );

    return _firestore
        .collection(_collection)
        .where('statusAprovacao', isEqualTo: StatusAprovacao.aguardando.name)
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) {
          print(
            '📊 [USUARIO] Usuários aguardando encontrados: ${snapshot.docs.length}',
          );
          return snapshot.docs.map((doc) {
            return Usuario.fromMap({'id': doc.id, ...doc.data()});
          }).toList();
        });
  }

  // Buscar usuários por regional
  Future<List<Usuario>> getUsuariosPorRegional(String regionalId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('statusAprovacao', isEqualTo: StatusAprovacao.aprovado.name)
          .orderBy('nome')
          .get();

      return querySnapshot.docs.map((doc) {
        return Usuario.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Erro ao buscar usuários por regional: $e');
      return [];
    }
  }

  // Buscar usuário por ID
  Future<Usuario?> getUsuarioById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Usuario.fromMap({'id': doc.id, ...?doc.data()});
      }
      return null;
    } catch (e) {
      print('Erro ao buscar usuário: $e');
      return null;
    }
  }

  // Buscar usuário por email
  Future<Usuario?> getUsuarioPorEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return Usuario.fromMap({'id': doc.id, ...doc.data()});
    } catch (e) {
      print('Erro ao buscar usuário por email: $e');
      return null;
    }
  }

  // Atualizar usuário
  Future<void> atualizarUsuario(Usuario usuario) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(usuario.id)
          .update(usuario.toMap());
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      rethrow;
    }
  }

  // Aprovar usuário
  Future<void> aprovarUsuario(String usuarioId) async {
    try {
      await _firestore.collection(_collection).doc(usuarioId).update({
        'statusAprovacao': StatusAprovacao.aprovado.name,
        'dataAtualizacao': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Erro ao aprovar usuário: $e');
      rethrow;
    }
  }

  // Rejeitar usuário
  Future<void> rejeitarUsuario(String usuarioId) async {
    try {
      await _firestore.collection(_collection).doc(usuarioId).update({
        'statusAprovacao': StatusAprovacao.rejeitado.name,
        'dataAtualizacao': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Erro ao rejeitar usuário: $e');
      rethrow;
    }
  }

  // Ativar/Desativar usuário
  Future<void> alterarStatusUsuario(String usuarioId, bool ativo) async {
    try {
      await _firestore.collection(_collection).doc(usuarioId).update({
        'ativo': ativo,
        'dataAtualizacao': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Erro ao alterar status do usuário: $e');
      rethrow;
    }
  }

  // Buscar chefe da UNIAE por regional
  Future<Usuario?> getChefeUniaePorRegional(String regionalId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('tipoUsuario', isEqualTo: TipoUsuario.chefeUniae.name)
          .where('statusAprovacao', isEqualTo: StatusAprovacao.aprovado.name)
          .where('ativo', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return Usuario.fromMap({'id': doc.id, ...doc.data()});
    } catch (e) {
      print('Erro ao buscar chefe UNIAE por regional: $e');
      return null;
    }
  }

  // Excluir usuário
  Future<void> excluirUsuario(String usuarioId) async {
    try {
      await _firestore.collection(_collection).doc(usuarioId).delete();
    } catch (e) {
      print('Erro ao excluir usuário: $e');
      rethrow;
    }
  }

  // Verificar se email já existe
  Future<bool> emailExiste(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar email: $e');
      return false;
    }
  }

  // Verificar se matrícula já existe
  Future<bool> matriculaExiste(String matricula) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('matricula', isEqualTo: matricula)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar matrícula: $e');
      return false;
    }
  }
}
