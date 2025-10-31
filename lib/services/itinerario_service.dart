import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/itinerario.dart';

class ItinerarioService {
  static const String _collection = 'itinerarios';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar todos os itinerários de uma regional
  Stream<List<Itinerario>> getItinerariosPorRegional(String regionalId) {
    return _firestore
        .collection(_collection)
        .where('regionalId', isEqualTo: regionalId)
        .snapshots()
        .map((snapshot) {
          final itinerarios = snapshot.docs
              .map((doc) => Itinerario.fromFirestore(doc.data(), doc.id))
              .toList();

          // Ordenar localmente para evitar necessidade de índice
          itinerarios.sort((a, b) => a.itinerario.compareTo(b.itinerario));
          return itinerarios;
        });
  }

  // Buscar itinerários por turno
  Stream<List<Itinerario>> getItinerariosPorTurno(
    String regionalId,
    String turno,
  ) {
    try {
      print(
        '🔍 [ITINERARIO] Consultando por regionalId: $regionalId, turno: $turno',
      );
      print(
        '📋 [ITINERARIO] Query: collection($_collection).where(regionalId == $regionalId).where(turno == $turno).orderBy(itinerario)',
      );

      return _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('turno', isEqualTo: turno)
          .orderBy('itinerario') // ⚠️ Vai gerar erro com link para criar índice
          .snapshots()
          .map((snapshot) {
            print(
              '📊 [ITINERARIO] Itinerários encontrados: ${snapshot.docs.length}',
            );
            return snapshot.docs
                .map((doc) => Itinerario.fromFirestore(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      print('');
      print(
        '🎯 ==================== ITINERÁRIOS - AQUI ESTÁ O LINK! ====================',
      );
      print('🔗 CLIQUE NESTE LINK PARA CRIAR O ÍNDICE DE ITINERÁRIOS:');
      print('$e');
      print(
        '======================================================================',
      );
      print('');
      // Fallback sem orderBy
      return _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('turno', isEqualTo: turno)
          .snapshots()
          .map((snapshot) {
            final itinerarios = snapshot.docs
                .map((doc) => Itinerario.fromFirestore(doc.data(), doc.id))
                .toList();
            itinerarios.sort((a, b) => a.itinerario.compareTo(b.itinerario));
            return itinerarios;
          });
    }
  }

  // Buscar itinerário por ID
  Future<Itinerario?> getItinerarioById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Itinerario.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar itinerário: $e');
    }
  }

  // Adicionar novo itinerário
  Future<String> adicionarItinerario(
    Itinerario itinerario,
    String? usuarioId,
  ) async {
    try {
      // Adicionar ID do usuário que está criando
      final itinerarioComUsuario = itinerario.copyWith(
        usuarioCriacaoId: usuarioId,
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(itinerarioComUsuario.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar itinerário: $e');
    }
  }

  // Atualizar itinerário
  Future<void> atualizarItinerario(
    Itinerario itinerario,
    String? usuarioId,
  ) async {
    try {
      // Adicionar ID do usuário que está atualizando
      final itinerarioAtualizado = itinerario.copyWith(
        dataAtualizacao: DateTime.now(),
        usuarioAtualizacaoId: usuarioId,
      );

      await _firestore
          .collection(_collection)
          .doc(itinerario.id)
          .update(itinerarioAtualizado.toFirestore());
    } catch (e) {
      throw Exception('Erro ao atualizar itinerário: $e');
    }
  }

  // Excluir itinerário
  Future<void> excluirItinerario(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao excluir itinerário: $e');
    }
  }

  // Verificar se existe itinerário com a mesma descrição na regional
  Future<bool> existeItinerarioComDescricao(
    String regionalId,
    String descricao, {
    String? excludeId,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('itinerario', isEqualTo: descricao);

      if (excludeId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeId);
      }

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar descrição: $e');
    }
  }

  // Buscar estatísticas da regional
  Future<Map<String, dynamic>> getEstatisticasRegional(
    String regionalId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      int totalItinerarios = snapshot.docs.length;
      int totalAlunos = 0;
      double totalKm = 0.0;
      int totalOnibus = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalAlunos += (data['total'] ?? 0) as int;
        totalKm += (data['km'] ?? 0.0).toDouble();
        totalOnibus += (data['numeroOnibus'] ?? 0) as int;
      }

      return {
        'totalItinerarios': totalItinerarios,
        'totalAlunos': totalAlunos,
        'totalKm': totalKm,
        'totalOnibus': totalOnibus,
      };
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas: $e');
    }
  }

  // Buscar itinerários para relatório
  Future<List<Itinerario>> getItinerariosParaRelatorio(
    String regionalId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      final itinerarios = snapshot.docs
          .map((doc) => Itinerario.fromFirestore(doc.data(), doc.id))
          .toList();

      // Ordenar localmente por itinerário
      itinerarios.sort((a, b) => a.itinerario.compareTo(b.itinerario));

      return itinerarios;
    } catch (e) {
      throw Exception('Erro ao buscar itinerários para relatório: $e');
    }
  }

  // Buscar itinerários por contrato para relatório
  Future<List<Itinerario>> getItinerariosPorContrato(String contratoId) async {
    try {
      print('🔍 [ITINERARIO] Buscando itinerários por contrato: $contratoId');

      final snapshot = await _firestore
          .collection(_collection)
          .where('contratoId', isEqualTo: contratoId)
          .get();

      final itinerarios = snapshot.docs
          .map((doc) => Itinerario.fromFirestore(doc.data(), doc.id))
          .toList();

      // Ordenar por nome do itinerário
      itinerarios.sort((a, b) => a.itinerario.compareTo(b.itinerario));

      print(
        '📊 [ITINERARIO] Itinerários encontrados por contrato: ${itinerarios.length}',
      );
      return itinerarios;
    } catch (e) {
      print('❌ [ITINERARIO] Erro ao buscar itinerários por contrato: $e');
      throw Exception('Erro ao buscar itinerários por contrato: $e');
    }
  }
}
