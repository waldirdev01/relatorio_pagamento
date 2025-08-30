import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream do usuário atual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário atual
  User? get currentUser => _auth.currentUser;

  // Cadastrar usuário
  Future<Usuario?> cadastrarUsuario({
    required String nome,
    required String matricula,
    required String telefone,
    required String email,
    required String senha,
    required TipoUsuario tipoUsuario,
    String? regionalId,
  }) async {
    try {
      // Criar usuário no Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: senha);

      final User? user = userCredential.user;
      if (user == null) return null;

      // Criar documento do usuário no Firestore
      final agora = DateTime.now();
      final usuario = Usuario(
        id: user.uid,
        nome: nome,
        matricula: matricula,
        telefone: telefone,
        email: email,
        tipoUsuario: tipoUsuario,
        regionalId: regionalId,
        statusAprovacao: StatusAprovacao.aguardando,
        ativo: true,
        dataCriacao: agora,
        dataAtualizacao: agora,
      );

      await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .set(usuario.toMap());

      return usuario;
    } catch (e) {
      print('Erro ao cadastrar usuário: $e');
      rethrow;
    }
  }

  // Fazer login
  Future<Usuario?> fazerLogin(String email, String senha) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: senha);

      final User? user = userCredential.user;
      if (user == null) return null;

      // Buscar dados do usuário no Firestore
      return await getUsuarioPorId(user.uid);
    } catch (e) {
      print('Erro ao fazer login: $e');
      rethrow;
    }
  }

  // Fazer logout
  Future<void> fazerLogout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erro ao fazer logout: $e');
      rethrow;
    }
  }

  // Buscar usuário por ID
  Future<Usuario?> getUsuarioPorId(String id) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(id).get();
      if (!doc.exists) return null;

      return Usuario.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e) {
      print('Erro ao buscar usuário: $e');
      return null;
    }
  }

  // Buscar usuário atual
  Future<Usuario?> getUsuarioAtual() async {
    final user = currentUser;
    if (user == null) return null;
    return await getUsuarioPorId(user.uid);
  }

  // Verificar se usuário está aprovado
  Future<bool> isUsuarioAprovado() async {
    final usuario = await getUsuarioAtual();
    return usuario?.statusAprovacao == StatusAprovacao.aprovado;
  }

  // Verificar se usuário é GCOTE
  Future<bool> isUsuarioGcote() async {
    final usuario = await getUsuarioAtual();
    return usuario?.tipoUsuario == TipoUsuario.gcote;
  }

  // Verificar se usuário é Chefe UNIAE
  Future<bool> isUsuarioChefeUniae() async {
    final usuario = await getUsuarioAtual();
    return usuario?.tipoUsuario == TipoUsuario.chefeUniae;
  }

  // Verificar se usuário é Administrativo UNIAE
  Future<bool> isUsuarioAdministrativoUniae() async {
    final usuario = await getUsuarioAtual();
    return usuario?.tipoUsuario == TipoUsuario.administrativoUniae;
  }

  // Redefinir senha
  Future<void> redefinirSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Erro ao redefinir senha: $e');
      rethrow;
    }
  }

  // Atualizar perfil do usuário
  Future<void> atualizarPerfil({
    required String nome,
    required String matricula,
    required String telefone,
    required TipoUsuario tipoUsuario,
    String? regionalId,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não logado');

      final agora = DateTime.now();
      await _firestore.collection('usuarios').doc(user.uid).update({
        'nome': nome,
        'matricula': matricula,
        'telefone': telefone,
        'tipoUsuario': tipoUsuario.name,
        'regionalId': regionalId,
        'dataAtualizacao': agora.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  // Aprovar usuário (apenas GCOTE)
  Future<void> aprovarUsuario(String usuarioId) async {
    try {
      await _firestore.collection('usuarios').doc(usuarioId).update({
        'statusAprovacao': StatusAprovacao.aprovado.name,
        'dataAtualizacao': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Erro ao aprovar usuário: $e');
      rethrow;
    }
  }

  // Rejeitar usuário (apenas GCOTE)
  Future<void> rejeitarUsuario(String usuarioId) async {
    try {
      await _firestore.collection('usuarios').doc(usuarioId).update({
        'statusAprovacao': StatusAprovacao.rejeitado.name,
        'dataAtualizacao': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Erro ao rejeitar usuário: $e');
      rethrow;
    }
  }
}
