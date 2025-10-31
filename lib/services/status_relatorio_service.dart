import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/status_relatorio_regional.dart';

class StatusRelatorioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Colecao de status dos relatorios regionais
  CollectionReference get _statusCollection =>
      _firestore.collection('status_relatorios_regionais');

  /// Obter status de uma regional para um mes/ano especifico
  Future<StatusRelatorioRegional?> getStatusPorRegionalMesAno({
    required String regionalId,
    required int mes,
    required int ano,
  }) async {
    try {
      final query = await _statusCollection
          .where('regionalId', isEqualTo: regionalId)
          .where('mes', isEqualTo: mes)
          .where('ano', isEqualTo: ano)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return StatusRelatorioRegional.fromMap(data);
      }
      return null;
    } catch (e) {
      // Usar um sistema de logging adequado no lugar de print
      throw Exception('Erro ao buscar status: $e');
    }
  }

  /// Alterar status de uma regional para um mes/ano especifico
  Future<void> alterarStatus({
    required String regionalId,
    required int mes,
    required int ano,
    required StatusRelatorio novoStatus,
    required String usuarioId,
  }) async {
    try {
      final agora = DateTime.now();

      // Verificar se ja existe um status para esta regional/mes/ano
      final statusExistente = await getStatusPorRegionalMesAno(
        regionalId: regionalId,
        mes: mes,
        ano: ano,
      );

      if (statusExistente != null) {
        // Atualizar status existente
        await _statusCollection.doc(statusExistente.id).update({
          'status': novoStatus.name,
          'usuarioId': usuarioId,
          'dataAlteracao': agora.millisecondsSinceEpoch,
          'horaAlteracao': agora.millisecondsSinceEpoch,
        });
      } else {
        // Criar novo status
        final novoStatusDoc = StatusRelatorioRegional(
          id: '', // Sera definido pelo Firestore
          regionalId: regionalId,
          mes: mes,
          ano: ano,
          status: novoStatus,
          usuarioId: usuarioId,
          dataAlteracao: agora,
          horaAlteracao: agora,
        );

        await _statusCollection.add(novoStatusDoc.toMap());
      }
    } catch (e) {
      throw Exception('Erro ao alterar status: $e');
    }
  }

  /// Obter historico de status de uma regional
  Stream<List<StatusRelatorioRegional>> getHistoricoStatus({
    required String regionalId,
    int? mes,
    int? ano,
  }) {
    try {
      Query query = _statusCollection
          .where('regionalId', isEqualTo: regionalId)
          .orderBy('dataAlteracao', descending: true);

      if (mes != null) {
        query = query.where('mes', isEqualTo: mes);
      }
      if (ano != null) {
        query = query.where('ano', isEqualTo: ano);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return StatusRelatorioRegional.fromMap(data);
        }).toList();
      });
    } catch (e) {
      throw Exception('Erro ao buscar historico: $e');
    }
  }

  /// Obter todos os status para um mes/ano especifico
  Stream<List<StatusRelatorioRegional>> getStatusPorMesAno({
    required int mes,
    required int ano,
  }) {
    try {
      return _statusCollection
          .where('mes', isEqualTo: mes)
          .where('ano', isEqualTo: ano)
          .orderBy('dataAlteracao', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return StatusRelatorioRegional.fromMap(data);
            }).toList();
          });
    } catch (e) {
      throw Exception('Erro ao buscar status por mes/ano: $e');
    }
  }

  /// Excluir status de uma regional
  Future<void> excluirStatus(String statusId) async {
    try {
      await _statusCollection.doc(statusId).delete();
    } catch (e) {
      throw Exception('Erro ao excluir status: $e');
    }
  }

  /// Excluir todos os status de uma regional
  Future<void> excluirStatusPorRegional(String regionalId) async {
    try {
      final query = await _statusCollection
          .where('regionalId', isEqualTo: regionalId)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao excluir status da regional: $e');
    }
  }
}
