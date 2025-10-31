import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/atividade_extracurricular.dart';
import '../utils/app_logger.dart';

class AtividadeExtracurricularService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'atividades_extracurriculares';

  // Buscar todas as atividades de uma regional
  Stream<List<AtividadeExtracurricular>> getAtividadesPorRegional(
    String regionalId,
  ) {
    try {
      AppLogger.debug(
        'Consultando por regionalId: $regionalId',
        tag: 'ATIVIDADE',
      );
      AppLogger.debug(
        'Query: collection($_collection).where(regionalId == $regionalId).orderBy(dataCriacao, descending: true)',
        tag: 'ATIVIDADE',
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
            AppLogger.debug(
              'Atividades encontradas: ${snapshot.docs.length}',
              tag: 'ATIVIDADE',
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
      AppLogger.error(
        'ATIVIDADES - AQUI ESTÁ O LINK! CLIQUE NESTE LINK PARA CRIAR O ÍNDICE DE ATIVIDADES: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
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
            // Ordenar localmente
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
      AppLogger.error(
        'Erro ao buscar atividades: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
      return [];
    }
  }

  // Buscar atividades por contrato
  Stream<List<AtividadeExtracurricular>> getAtividadesPorContrato(
    String contratoId,
  ) {
    try {
      AppLogger.debug(
        'Consultando por contratoId: $contratoId',
        tag: 'ATIVIDADE-CONTRATO',
      );
      AppLogger.debug(
        'Query: collection($_collection).where(contratoId == $contratoId).orderBy(dataCriacao, descending: true)',
        tag: 'ATIVIDADE-CONTRATO',
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
            AppLogger.debug(
              'Atividades encontradas: ${snapshot.docs.length}',
              tag: 'ATIVIDADE-CONTRATO',
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
      AppLogger.error(
        'ATIVIDADES POR CONTRATO - AQUI ESTÁ O LINK! CLIQUE NESTE LINK PARA CRIAR O ÍNDICE DE ATIVIDADES POR CONTRATO: $e',
        tag: 'ATIVIDADE-CONTRATO',
        error: e,
      );
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
      AppLogger.error(
        'Erro ao buscar atividades por período: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
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
      AppLogger.error(
        'Erro ao buscar atividade: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
      return null;
    }
  }

  // Adicionar nova atividade
  Future<String?> adicionarAtividade(
    AtividadeExtracurricular atividade,
    String? usuarioId,
  ) async {
    try {
      // Adicionar ID do usuário que está criando
      final atividadeComUsuario = atividade.copyWith(
        usuarioCriacaoId: usuarioId,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(atividadeComUsuario.toFirestore());
      return docRef.id;
    } catch (e) {
      AppLogger.error(
        'Erro ao adicionar atividade: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
      return null;
    }
  }

  // Atualizar atividade existente
  Future<bool> atualizarAtividade(
    AtividadeExtracurricular atividade,
    String? usuarioId,
  ) async {
    try {
      final atividadeAtualizada = atividade.copyWith(
        dataAtualizacao: DateTime.now(),
        usuarioAtualizacaoId: usuarioId,
      );

      await _firestore
          .collection(_collection)
          .doc(atividade.id)
          .update(atividadeAtualizada.toFirestore());

      return true;
    } catch (e) {
      AppLogger.error(
        'Erro ao atualizar atividade: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
      return false;
    }
  }

  // Excluir atividade
  Future<bool> excluirAtividade(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      AppLogger.error(
        'Erro ao excluir atividade: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
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
      AppLogger.error(
        'Erro ao verificar atividade existente: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
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
      AppLogger.error(
        'Erro ao buscar estatísticas de atividades: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
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
      AppLogger.debug(
        'Buscando atividades por contrato: $contratoId',
        tag: 'ATIVIDADE',
      );

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

      AppLogger.debug(
        'Total atividades do contrato: ${todasAtividades.length}',
        tag: 'ATIVIDADE',
      );
      AppLogger.debug(
        'Atividades filtradas por período $mes/$ano: ${atividadesFiltradas.length}',
        tag: 'ATIVIDADE',
      );
      return atividadesFiltradas;
    } catch (e) {
      AppLogger.error(
        'Erro ao buscar atividades por contrato/período: $e',
        tag: 'ATIVIDADE',
        error: e,
      );
      throw Exception('Erro ao buscar atividades por contrato/período: $e');
    }
  }
}
