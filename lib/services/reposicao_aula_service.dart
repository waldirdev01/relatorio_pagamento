import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reposicao_aula.dart';

class ReposicaoAulaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reposicoes_aula';

  // Buscar todas as reposições de uma regional
  Stream<List<ReposicaoAula>> getReposicoesPorRegional(String regionalId) {
    return _firestore
        .collection(_collection)
        .where('regionalId', isEqualTo: regionalId)
        .snapshots()
        .map((snapshot) {
          final reposicoes = snapshot.docs
              .map((doc) => ReposicaoAula.fromFirestore(doc.data(), doc.id))
              .toList();

          // Ordenar por data de criação (mais recente primeiro)
          reposicoes.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
          return reposicoes;
        });
  }

  // Buscar todas as reposições de um itinerário específico
  Stream<List<ReposicaoAula>> getReposicoesPorItinerario(String itinerarioId) {
    return _firestore
        .collection(_collection)
        .where('itinerarioId', isEqualTo: itinerarioId)
        .snapshots()
        .map((snapshot) {
          final reposicoes = snapshot.docs
              .map((doc) => ReposicaoAula.fromFirestore(doc.data(), doc.id))
              .toList();

          // Ordenar por data de criação (mais recente primeiro)
          reposicoes.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
          return reposicoes;
        });
  }

  // Buscar reposições por itinerário (Future para relatórios)
  Future<List<ReposicaoAula>> getReposicoesPorItinerarioFuture(
    String itinerarioId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('itinerarioId', isEqualTo: itinerarioId)
          .get();

      return snapshot.docs
          .map((doc) => ReposicaoAula.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao buscar reposições: $e');
      return [];
    }
  }

  // Buscar uma reposição específica
  Future<ReposicaoAula?> getReposicaoById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ReposicaoAula.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar reposição: $e');
      return null;
    }
  }

  // Adicionar nova reposição
  Future<String?> adicionarReposicao(ReposicaoAula reposicao) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(reposicao.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erro ao adicionar reposição: $e');
      return null;
    }
  }

  // Atualizar reposição existente
  Future<bool> atualizarReposicao(ReposicaoAula reposicao) async {
    try {
      final reposicaoAtualizada = reposicao.copyWith(
        dataAtualizacao: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(reposicao.id)
          .update(reposicaoAtualizada.toFirestore());
      return true;
    } catch (e) {
      print('Erro ao atualizar reposição: $e');
      return false;
    }
  }

  // Excluir reposição
  Future<bool> excluirReposicao(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erro ao excluir reposição: $e');
      return false;
    }
  }

  // Buscar estatísticas de reposições por regional
  Future<Map<String, dynamic>> getEstatisticasReposicoes(
    String regionalId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      int totalReposicoes = snapshot.docs.length;
      double totalKm = 0;
      int totalDias = 0;
      double totalKmXNumeroOnibusXDias = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalKm += (data['km'] ?? 0).toDouble();
        totalDias += (data['diasTrabalhados'] ?? 0) as int;
        totalKmXNumeroOnibusXDias += (data['kmXNumeroOnibusXDias'] ?? 0)
            .toDouble();
      }

      return {
        'totalReposicoes': totalReposicoes,
        'totalKm': totalKm,
        'totalDias': totalDias,
        'totalKmXNumeroOnibusXDias': totalKmXNumeroOnibusXDias,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas de reposições: $e');
      return {
        'totalReposicoes': 0,
        'totalKm': 0.0,
        'totalDias': 0,
        'totalKmXNumeroOnibusXDias': 0.0,
      };
    }
  }

  // Buscar reposições por período específico (mês/ano)
  Future<List<ReposicaoAula>> getReposicoesPorPeriodo({
    required String regionalId,
    required int mes,
    required int ano,
  }) async {
    try {
      print(
        'Buscando reposições para: regionalId=$regionalId, mês=$mes, ano=$ano',
      );

      // Calcular primeiro e último dia do mês
      final inicioMes = DateTime(ano, mes, 1);
      final fimMes = DateTime(ano, mes + 1, 0, 23, 59, 59, 999);

      print('Período: ${inicioMes.toString()} até ${fimMes.toString()}');
      print(
        'Timestamps: ${inicioMes.millisecondsSinceEpoch} até ${fimMes.millisecondsSinceEpoch}',
      );

      // Primeiro, buscar todas as reposições da regional
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      print(
        'Total de reposições encontradas na regional: ${snapshot.docs.length}',
      );

      final todasReposicoes = snapshot.docs
          .map((doc) => ReposicaoAula.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filtrar por período localmente para ter mais controle
      final reposicoesFiltradas = todasReposicoes.where((reposicao) {
        // Priorizar a data da reposição (quando foi executada)
        if (reposicao.dataReposicao != null) {
          final dentroperiodo =
              reposicao.dataReposicao!.isAfter(
                inicioMes.subtract(Duration(days: 1)),
              ) &&
              reposicao.dataReposicao!.isBefore(fimMes.add(Duration(days: 1)));

          if (dentroperiodo) {
            print(
              'Reposição ID: ${reposicao.id} - Incluída por dataReposicao: ${reposicao.dataReposicao}',
            );
          }

          return dentroperiodo;
        }

        // Se não tem data da reposição, usar data de criação como fallback
        final dataCriacao = reposicao.dataCriacao;
        final dentroperiodo =
            dataCriacao.isAfter(inicioMes.subtract(Duration(days: 1))) &&
            dataCriacao.isBefore(fimMes.add(Duration(days: 1)));

        if (dentroperiodo) {
          print(
            'Reposição ID: ${reposicao.id} - Incluída por dataCriacao: $dataCriacao (sem data de reposição)',
          );
        }

        return dentroperiodo;
      }).toList();

      print('Reposições filtradas por período: ${reposicoesFiltradas.length}');

      return reposicoesFiltradas;
    } catch (e) {
      print('Erro ao buscar reposições por período: $e');
      return [];
    }
  }

  // Excluir todas as reposições de um período específico
  Future<int> excluirReposicoesPorPeriodo({
    required String regionalId,
    required int mes,
    required int ano,
  }) async {
    try {
      final reposicoes = await getReposicoesPorPeriodo(
        regionalId: regionalId,
        mes: mes,
        ano: ano,
      );

      int totalExcluidas = 0;

      // Excluir em lotes para evitar problemas de performance
      final batch = _firestore.batch();

      for (final reposicao in reposicoes) {
        batch.delete(_firestore.collection(_collection).doc(reposicao.id));
        totalExcluidas++;
      }

      await batch.commit();
      return totalExcluidas;
    } catch (e) {
      print('Erro ao excluir reposições por período: $e');
      return 0;
    }
  }

  // Contar reposições por período
  Future<int> contarReposicoesPorPeriodo({
    required String regionalId,
    required int mes,
    required int ano,
  }) async {
    try {
      final reposicoes = await getReposicoesPorPeriodo(
        regionalId: regionalId,
        mes: mes,
        ano: ano,
      );
      return reposicoes.length;
    } catch (e) {
      print('Erro ao contar reposições por período: $e');
      return 0;
    }
  }

  // Verificar se já existe reposição com os mesmos dados
  Future<bool> existeReposicaoSimilar({
    required String itinerarioId,
    required double km,
    required int numeroOnibus,
    required int diasTrabalhados,
    String? excluirId,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('itinerarioId', isEqualTo: itinerarioId)
          .where('km', isEqualTo: km)
          .where('numeroOnibus', isEqualTo: numeroOnibus)
          .where('diasTrabalhados', isEqualTo: diasTrabalhados);

      final snapshot = await query.get();

      // Se estamos editando, excluir o próprio registro da verificação
      if (excluirId != null) {
        return snapshot.docs.any((doc) => doc.id != excluirId);
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar reposição similar: $e');
      return false;
    }
  }

  // =======================================
  // MÉTODOS PARA GRUPOS DE REPOSIÇÕES
  // =======================================

  /// Adicionar múltiplas reposições como um grupo (mesmo processo de solicitação)
  /// Retorna lista dos IDs das reposições criadas
  Future<List<String>> adicionarGrupoReposicoes({
    required String itinerarioId,
    required String regionalId,
    required double km,
    required int numeroOnibus,
    required DateTime dataSolicitacao,
    required List<DateTime> datasReposicao,
    String? observacoes,
  }) async {
    try {
      // Gerar ID único para o grupo
      final grupoId = ReposicaoAula.gerarGrupoSolicitacaoId();
      final List<String> idsReposicoes = [];
      final agora = DateTime.now();

      // Criar batch para transação atômica
      final batch = _firestore.batch();

      for (final dataReposicao in datasReposicao) {
        // Calcular valores para esta reposição (1 dia por reposição)
        final diasTrabalhados = 1;
        final reposicao = ReposicaoAula.calcularValores(
          id: '', // Será definido pelo Firestore
          itinerarioId: itinerarioId,
          regionalId: regionalId,
          grupoSolicitacaoId: grupoId,
          km: km,
          numeroOnibus: numeroOnibus,
          diasTrabalhados: diasTrabalhados,
          dataCriacao: agora,
          dataSolicitacao: dataSolicitacao,
          dataReposicao: dataReposicao,
          observacoes: observacoes,
        );

        // Adicionar ao batch
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, reposicao.toFirestore());
        idsReposicoes.add(docRef.id);
      }

      // Executar todas as inserções
      await batch.commit();

      print(
        'Grupo de ${datasReposicao.length} reposições criado com ID: $grupoId',
      );
      return idsReposicoes;
    } catch (e) {
      print('Erro ao adicionar grupo de reposições: $e');
      return [];
    }
  }

  /// Buscar todas as reposições de um grupo específico
  Future<List<ReposicaoAula>> getReposicoesPorGrupo(String grupoId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('grupoSolicitacaoId', isEqualTo: grupoId)
          .get();

      final reposicoes = snapshot.docs
          .map((doc) => ReposicaoAula.fromFirestore(doc.data(), doc.id))
          .toList();

      // Ordenar por data de reposição
      reposicoes.sort((a, b) {
        if (a.dataReposicao == null && b.dataReposicao == null) return 0;
        if (a.dataReposicao == null) return 1;
        if (b.dataReposicao == null) return -1;
        return a.dataReposicao!.compareTo(b.dataReposicao!);
      });

      return reposicoes;
    } catch (e) {
      print('Erro ao buscar reposições do grupo: $e');
      return [];
    }
  }

  /// Excluir um grupo completo de reposições
  Future<int> excluirGrupoReposicoes(String grupoId) async {
    try {
      final reposicoes = await getReposicoesPorGrupo(grupoId);

      if (reposicoes.isEmpty) {
        print('Nenhuma reposição encontrada para o grupo: $grupoId');
        return 0;
      }

      final batch = _firestore.batch();

      for (final reposicao in reposicoes) {
        batch.delete(_firestore.collection(_collection).doc(reposicao.id));
      }

      await batch.commit();

      print('Grupo $grupoId excluído com ${reposicoes.length} reposições');
      return reposicoes.length;
    } catch (e) {
      print('Erro ao excluir grupo de reposições: $e');
      return 0;
    }
  }

  /// Atualizar dados comuns de um grupo (como observações)
  Future<bool> atualizarGrupoReposicoes({
    required String grupoId,
    String? observacoes,
    DateTime? novaDataSolicitacao,
  }) async {
    try {
      final reposicoes = await getReposicoesPorGrupo(grupoId);

      if (reposicoes.isEmpty) {
        print('Nenhuma reposição encontrada para o grupo: $grupoId');
        return false;
      }

      final batch = _firestore.batch();
      final agora = DateTime.now();

      for (final reposicao in reposicoes) {
        final reposicaoAtualizada = reposicao.copyWith(
          observacoes: observacoes,
          dataSolicitacao: novaDataSolicitacao,
          dataAtualizacao: agora,
        );

        batch.update(
          _firestore.collection(_collection).doc(reposicao.id),
          reposicaoAtualizada.toFirestore(),
        );
      }

      await batch.commit();

      print('Grupo $grupoId atualizado com ${reposicoes.length} reposições');
      return true;
    } catch (e) {
      print('Erro ao atualizar grupo de reposições: $e');
      return false;
    }
  }

  // Buscar reposições por contrato e período para relatório
  Future<List<ReposicaoAula>> getReposicoesPorContratoPeriodo({
    required String contratoId,
    required int mes,
    required int ano,
  }) async {
    try {
      print('🔍 [REPOSICAO] Buscando reposições por contrato: $contratoId');

      // Buscar todas as reposições (sem filtro de data inicial para incluir nulls)
      final snapshot = await _firestore.collection(_collection).get();

      final reposicoes = <ReposicaoAula>[];
      final dataInicio = DateTime(ano, mes, 1);
      final dataFim = DateTime(ano, mes + 1, 0);

      for (final doc in snapshot.docs) {
        final reposicao = ReposicaoAula.fromFirestore(doc.data(), doc.id);

        // Verificar data em memória (usar dataCriacao se dataReposicao for null)
        final dataRef = reposicao.dataReposicao ?? reposicao.dataCriacao;
        if (!dataRef.isAfter(dataInicio.subtract(const Duration(days: 1))) ||
            !dataRef.isBefore(dataFim.add(const Duration(days: 1)))) {
          continue; // Pular se não estiver no período
        }

        // Verificar contrato via itinerário
        final itinerarioDoc = await _firestore
            .collection('itinerarios')
            .doc(reposicao.itinerarioId)
            .get();

        if (itinerarioDoc.exists) {
          final itinerarioData = itinerarioDoc.data()!;
          if (itinerarioData['contratoId'] == contratoId) {
            reposicoes.add(reposicao);
          }
        }
      }

      // Ordenar por data da reposição
      reposicoes.sort((a, b) {
        final dataA = a.dataReposicao ?? a.dataCriacao;
        final dataB = b.dataReposicao ?? b.dataCriacao;
        return dataA.compareTo(dataB);
      });

      print(
        '📊 [REPOSICAO] Reposições filtradas por período $mes/$ano: ${reposicoes.length}',
      );
      return reposicoes;
    } catch (e) {
      print('❌ [REPOSICAO] Erro ao buscar reposições por contrato/período: $e');
      throw Exception('Erro ao buscar reposições por contrato/período: $e');
    }
  }
}
