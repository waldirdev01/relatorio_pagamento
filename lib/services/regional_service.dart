import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/regional.dart';

class RegionalService {
  static const String _collection = 'regionais';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Buscar todas as regionais
  Stream<List<Regional>> getRegionais() {
    return _firestore
        .collection(_collection)
        .orderBy('descricao')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Regional.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // Buscar regional por ID
  Future<Regional?> getRegionalById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Regional.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar regional: $e');
    }
  }

    // Adicionar nova regional
  Future<String> adicionarRegional(Regional regional) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(regional.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar regional: $e');
    }
  }

    // Atualizar regional
  Future<void> atualizarRegional(Regional regional) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(regional.id)
          .update(
            regional.copyWith(dataAtualizacao: DateTime.now()).toFirestore(),
          );
    } catch (e) {
      throw Exception('Erro ao atualizar regional: $e');
    }
  }

    // Excluir regional
  Future<void> excluirRegional(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Erro ao excluir regional: $e');
    }
  }

  // Verificar se existe regional com a mesma descrição
  Future<bool> existeRegionalComDescricao(
    String descricao, {
    String? excludeId,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('descricao', isEqualTo: descricao);

      if (excludeId != null) {
        query = query.where(FieldPath.documentId, isNotEqualTo: excludeId);
      }

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar descrição: $e');
    }
  }
}
