import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/status_relatorio_regional.dart';

class StatusRelatorioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'status_relatorios_regionais';

  Future<void> adicionarStatus(StatusRelatorioRegional status) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(status.id)
          .set(status.toMap());
    } catch (e) {
      print('Erro ao adicionar status: $e');
      rethrow;
    }
  }

  Future<void> atualizarStatus(StatusRelatorioRegional status) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(status.id)
          .update(status.toMap());
    } catch (e) {
      print('Erro ao atualizar status: $e');
      rethrow;
    }
  }

  Future<void> excluirStatus(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Erro ao excluir status: $e');
      rethrow;
    }
  }

  Future<StatusRelatorioRegional?> getStatusPorRegionalMesAno({
    required String regionalId,
    required int mes,
    required int ano,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('mes', isEqualTo: mes)
          .where('ano', isEqualTo: ano)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return StatusRelatorioRegional.fromMap({'id': doc.id, ...doc.data()});
    } catch (e) {
      print('Erro ao buscar status: $e');
      return null;
    }
  }

  Future<List<StatusRelatorioRegional>> getStatusPorMesAno({
    required int mes,
    required int ano,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('mes', isEqualTo: mes)
          .where('ano', isEqualTo: ano)
          .orderBy('regionalId')
          .get();

      return querySnapshot.docs.map((doc) {
        return StatusRelatorioRegional.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Erro ao buscar status por mês/ano: $e');
      return [];
    }
  }

  Future<List<StatusRelatorioRegional>> getStatusPorRegional(
    String regionalId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .orderBy('ano', descending: true)
          .orderBy('mes', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return StatusRelatorioRegional.fromMap({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (e) {
      print('Erro ao buscar status por regional: $e');
      return [];
    }
  }

  Stream<List<StatusRelatorioRegional>> getStatusPorMesAnoStream({
    required int mes,
    required int ano,
  }) {
    return _firestore
        .collection(_collection)
        .where('mes', isEqualTo: mes)
        .where('ano', isEqualTo: ano)
        .orderBy('regionalId')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return StatusRelatorioRegional.fromMap({
              'id': doc.id,
              ...doc.data(),
            });
          }).toList();
        });
  }

  Future<void> alterarStatus({
    required String regionalId,
    required int mes,
    required int ano,
    required StatusRelatorio novoStatus,
    required String usuarioId,
  }) async {
    try {
      final agora = DateTime.now();
      final id = '${regionalId}_${ano}_${mes.toString().padLeft(2, '0')}';

      final status = StatusRelatorioRegional(
        id: id,
        regionalId: regionalId,
        mes: mes,
        ano: ano,
        status: novoStatus,
        usuarioId: usuarioId,
        dataAlteracao: agora,
        horaAlteracao: agora,
      );

      // Verificar se já existe
      final existente = await getStatusPorRegionalMesAno(
        regionalId: regionalId,
        mes: mes,
        ano: ano,
      );

      if (existente != null) {
        await atualizarStatus(status);
      } else {
        await adicionarStatus(status);
      }
    } catch (e) {
      print('Erro ao alterar status: $e');
      rethrow;
    }
  }
}
