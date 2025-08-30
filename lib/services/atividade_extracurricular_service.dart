import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/atividade_extracurricular.dart';

class AtividadeExtracurricularService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'atividades_extracurriculares';

  // Buscar todas as atividades de uma regional
  Stream<List<AtividadeExtracurricular>> getAtividadesPorRegional(
    String regionalId,
  ) {
    try {
      print('🔍 [ATIVIDADE] Consultando por regionalId: $regionalId');
      print(
        '📋 [ATIVIDADE] Query: collection($_collection).where(regionalId == $regionalId).orderBy(dataCriacao, descending: true)',
      );

      return _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .orderBy(
            'dataCriacao',
            descending: true,
          ) // ⚠️ Vai gerar erro com link para criar índice
          .snapshots()
          .map((snapshot) {
            print(
              '📊 [ATIVIDADE] Atividades encontradas: ${snapshot.docs.length}',
            );
            return snapshot.docs
                .map(
                  (doc) => AtividadeExtracurricular.fromFirestore(
                    doc.data(),
                    doc.id,
                  ),
                )
                .toList();
          });
    } catch (e) {
      print('');
      print(
        '🎯 ==================== ATIVIDADES - AQUI ESTÁ O LINK! ====================',
      );
      print('🔗 CLIQUE NESTE LINK PARA CRIAR O ÍNDICE DE ATIVIDADES:');
      print('$e');
      print(
        '======================================================================',
      );
      print('');
      // Fallback sem orderBy
      return _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .snapshots()
          .map((snapshot) {
            final atividades = snapshot.docs
                .map(
                  (doc) => AtividadeExtracurricular.fromFirestore(
                    doc.data(),
                    doc.id,
                  ),
                )
                .toList();
            atividades.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
            return atividades;
          });
    }
  }

  // Buscar atividades por regional (Future para formulários)
  Future<List<AtividadeExtracurricular>> getAtividadesPorRegionalFuture(
    String regionalId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      final atividades = snapshot.docs
          .map(
            (doc) => AtividadeExtracurricular.fromFirestore(doc.data(), doc.id),
          )
          .toList();

      // Ordenação no cliente
      atividades.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));

      return atividades;
    } catch (e) {
      print('Erro ao buscar atividades: $e');
      return [];
    }
  }

  // Buscar atividades por contrato
  Stream<List<AtividadeExtracurricular>> getAtividadesPorContrato(
    String contratoId,
  ) {
    try {
      print('🔍 [ATIVIDADE-CONTRATO] Consultando por contratoId: $contratoId');
      print(
        '📋 [ATIVIDADE-CONTRATO] Query: collection($_collection).where(contratoId == $contratoId).orderBy(dataCriacao, descending: true)',
      );

      return _firestore
          .collection(_collection)
          .where('contratoId', isEqualTo: contratoId)
          .orderBy(
            'dataCriacao',
            descending: true,
          ) // ⚠️ Vai gerar erro com link para criar índice
          .snapshots()
          .map((snapshot) {
            print(
              '📊 [ATIVIDADE-CONTRATO] Atividades encontradas: ${snapshot.docs.length}',
            );
            return snapshot.docs
                .map(
                  (doc) => AtividadeExtracurricular.fromFirestore(
                    doc.data(),
                    doc.id,
                  ),
                )
                .toList();
          });
    } catch (e) {
      print('');
      print(
        '🎯 ================ ATIVIDADES POR CONTRATO - AQUI ESTÁ O LINK! ================',
      );
      print(
        '🔗 CLIQUE NESTE LINK PARA CRIAR O ÍNDICE DE ATIVIDADES POR CONTRATO:',
      );
      print('$e');
      print(
        '==============================================================================',
      );
      print('');
      // Fallback sem orderBy
      return _firestore
          .collection(_collection)
          .where('contratoId', isEqualTo: contratoId)
          .snapshots()
          .map((snapshot) {
            final atividades = snapshot.docs
                .map(
                  (doc) => AtividadeExtracurricular.fromFirestore(
                    doc.data(),
                    doc.id,
                  ),
                )
                .toList();
            atividades.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
            return atividades;
          });
    }
  }

  // Buscar atividades por período
  Future<List<AtividadeExtracurricular>> getAtividadesPorPeriodo({
    required String regionalId,
    required int mes,
    required int ano,
  }) async {
    try {
      final inicioMes = DateTime(ano, mes, 1);
      final fimMes = DateTime(ano, mes + 1, 0, 23, 59, 59, 999);

      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      final atividades = snapshot.docs
          .map(
            (doc) => AtividadeExtracurricular.fromFirestore(doc.data(), doc.id),
          )
          .where((atividade) {
            // Priorizar dataAtividade, depois dataCriacao
            final dataParaFiltro =
                atividade.dataAtividade ?? atividade.dataCriacao;
            return dataParaFiltro.isAfter(
                  inicioMes.subtract(Duration(days: 1)),
                ) &&
                dataParaFiltro.isBefore(fimMes.add(Duration(days: 1)));
          })
          .toList();

      return atividades;
    } catch (e) {
      print('Erro ao buscar atividades por período: $e');
      return [];
    }
  }

  // Buscar uma atividade específica
  Future<AtividadeExtracurricular?> getAtividadeById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return AtividadeExtracurricular.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar atividade: $e');
      return null;
    }
  }

  // Adicionar nova atividade
  Future<String?> adicionarAtividade(AtividadeExtracurricular atividade) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(atividade.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erro ao adicionar atividade: $e');
      return null;
    }
  }

  // Atualizar atividade existente
  Future<bool> atualizarAtividade(AtividadeExtracurricular atividade) async {
    try {
      final atividadeAtualizada = atividade.copyWith(
        dataAtualizacao: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(atividade.id)
          .update(atividadeAtualizada.toFirestore());
      return true;
    } catch (e) {
      print('Erro ao atualizar atividade: $e');
      return false;
    }
  }

  // Excluir atividade
  Future<bool> excluirAtividade(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erro ao excluir atividade: $e');
      return false;
    }
  }

  // Verificar se já existe atividade com a mesma descrição na regional
  Future<bool> existeAtividadeNaRegional({
    required String descricao,
    required String regionalId,
    String? excluirId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('descricao', isEqualTo: descricao)
          .get();

      // Se estamos editando, excluir o próprio registro da verificação
      if (excluirId != null) {
        return snapshot.docs.any((doc) => doc.id != excluirId);
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar atividade existente: $e');
      return false;
    }
  }

  // Buscar estatísticas de atividades por regional
  Future<Map<String, dynamic>> getEstatisticasAtividades(
    String regionalId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      int totalAtividades = snapshot.docs.length;
      int totalAlunos = 0;
      double totalKm = 0.0;
      double totalKmXDias = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalAlunos += (data['total'] ?? 0) as int;
        totalKm += (data['km'] ?? 0.0) as double;
        totalKmXDias += (data['kmXNumeroOnibusXDias'] ?? 0.0) as double;
      }

      return {
        'totalAtividades': totalAtividades,
        'totalAlunos': totalAlunos,
        'totalKm': totalKm,
        'totalKmXDias': totalKmXDias,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas de atividades: $e');
      return {
        'totalAtividades': 0,
        'totalAlunos': 0,
        'totalKm': 0.0,
        'totalKmXDias': 0.0,
      };
    }
  }

  // Buscar atividades por contrato e período para relatório
  Future<List<AtividadeExtracurricular>> getAtividadesPorContratoPeriodo({
    required String contratoId,
    required int mes,
    required int ano,
  }) async {
    try {
      print('🔍 [ATIVIDADE] Buscando atividades por contrato: $contratoId');

      // Buscar todas as atividades do contrato (sem filtro de data no Firestore)
      final snapshot = await _firestore
          .collection(_collection)
          .where('contratoId', isEqualTo: contratoId)
          .get();

      final todasAtividades = snapshot.docs
          .map(
            (doc) => AtividadeExtracurricular.fromFirestore(doc.data(), doc.id),
          )
          .toList();

      // Filtrar pelo período em memória
      final dataInicio = DateTime(ano, mes, 1);
      final dataFim = DateTime(ano, mes + 1, 0);

      final atividadesFiltradas = todasAtividades.where((atividade) {
        final dataRef = atividade.dataAtividade ?? atividade.dataCriacao;
        return dataRef.isAfter(dataInicio.subtract(const Duration(days: 1))) &&
            dataRef.isBefore(dataFim.add(const Duration(days: 1)));
      }).toList();

      // Ordenar por data da atividade
      atividadesFiltradas.sort(
        (a, b) => (a.dataAtividade ?? a.dataCriacao).compareTo(
          b.dataAtividade ?? b.dataCriacao,
        ),
      );

      print(
        '📊 [ATIVIDADE] Total atividades do contrato: ${todasAtividades.length}',
      );
      print(
        '📊 [ATIVIDADE] Atividades filtradas por período $mes/$ano: ${atividadesFiltradas.length}',
      );
      return atividadesFiltradas;
    } catch (e) {
      print('❌ [ATIVIDADE] Erro ao buscar atividades por contrato/período: $e');
      throw Exception('Erro ao buscar atividades por contrato/período: $e');
    }
  }
}
