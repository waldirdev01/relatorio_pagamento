import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/escola.dart';

class EscolaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'escolas';

  // Buscar todas as escolas de uma regional
  Stream<List<Escola>> getEscolasPorRegional(String regionalId) {
    // ÍNDICE COMPOSTO NECESSÁRIO: regionalId + nome
    // Execute este comando no terminal do Firebase para criar o índice:
    // Link: https://console.firebase.google.com/project/relatorio-pagamento-2e5c6/firestore/indexes
    print('=== FIREBASE INDEX BUILDING ===');
    print('Coleção: escolas');
    print('Campos: regionalId (Ascending), nome (Ascending)');
    print('Status: O índice está sendo criado pelo Firebase');
    print('Aguarde 5-10 minutos e o erro deve sumir');
    print(
      'Link direto: https://console.firebase.google.com/project/relatorio-pagamento-2e5c6/firestore/indexes',
    );
    print('--- Se abrir conta Google errada: ---');
    print('1. Troque /u/0/ por /u/1/ ou /u/2/ na URL');
    print('2. Ou acesse https://console.firebase.google.com/ e troque a conta');
    print('========================');

    return _firestore
        .collection(_collection)
        .where('regionalId', isEqualTo: regionalId)
        // .orderBy('nome') // Temporariamente comentado até índice terminar
        .snapshots()
        .map((snapshot) {
          final escolas = snapshot.docs
              .map((doc) => Escola.fromFirestore(doc.data(), doc.id))
              .toList();
          // Ordenação no cliente enquanto índice não está pronto
          escolas.sort((a, b) => a.nome.compareTo(b.nome));
          return escolas;
        });
  }

  // Buscar escolas por regional (Future para formulários)
  Future<List<Escola>> getEscolasPorRegionalFuture(String regionalId) async {
    try {
      // Simplificado: busca por regional e ordena no cliente para evitar índice composto
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      final escolas = snapshot.docs
          .map((doc) => Escola.fromFirestore(doc.data(), doc.id))
          .toList();

      // Ordenação no cliente
      escolas.sort((a, b) => a.nome.compareTo(b.nome));

      return escolas;
    } catch (e) {
      print('Erro ao buscar escolas: $e');
      return [];
    }
  }

  // Buscar uma escola específica
  Future<Escola?> getEscolaById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Escola.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar escola: $e');
      return null;
    }
  }

  // Adicionar nova escola
  Future<String?> adicionarEscola(Escola escola) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(escola.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erro ao adicionar escola: $e');
      return null;
    }
  }

  // Atualizar escola existente
  Future<bool> atualizarEscola(Escola escola) async {
    try {
      final escolaAtualizada = escola.copyWith(dataAtualizacao: DateTime.now());

      await _firestore
          .collection(_collection)
          .doc(escola.id)
          .update(escolaAtualizada.toFirestore());

      return true;
    } catch (e) {
      print('Erro ao atualizar escola: $e');
      return false;
    }
  }

  // Excluir escola
  Future<bool> excluirEscola(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erro ao excluir escola: $e');
      return false;
    }
  }

  // Verificar se já existe escola com o mesmo nome na regional
  Future<bool> existeEscolaNaRegional({
    required String nome,
    required String regionalId,
    String? excluirId,
  }) async {
    try {
      // ÍNDICE COMPOSTO NECESSÁRIO: regionalId + nome
      print('=== FIREBASE INDEX NEEDED ===');
      print('Coleção: escolas');
      print('Campos: regionalId (Ascending), nome (Ascending)');
      print(
        'Link: https://console.firebase.google.com/project/relatorio-pagamento-2e5c6/firestore/indexes',
      );
      print('--- Se abrir conta Google errada: ---');
      print(
        '1. Use: https://console.firebase.google.com/u/1/project/relatorio-pagamento-2e5c6/firestore/indexes',
      );
      print('2. Ou troque conta em: https://console.firebase.google.com/');
      print('========================');

      Query query = _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('nome', isEqualTo: nome);

      final snapshot = await query.get();

      // Se estamos editando, excluir o próprio registro da verificação
      if (excluirId != null) {
        return snapshot.docs.any((doc) => doc.id != excluirId);
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar escola existente: $e');
      return false;
    }
  }

  // Buscar nomes das escolas por lista de IDs
  Future<List<String>> getNomesEscolas(List<String> escolaIds) async {
    if (escolaIds.isEmpty) return [];

    try {
      // Otimizado: usa whereIn para buscar múltiplos IDs em uma consulta
      // Limite do Firebase: máximo 10 IDs por consulta whereIn
      final List<String> nomes = [];

      // Divide em lotes de 10 para respeitar limite do Firebase
      for (int i = 0; i < escolaIds.length; i += 10) {
        final batch = escolaIds.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          final escola = Escola.fromFirestore(doc.data(), doc.id);
          nomes.add(escola.nome);
        }
      }

      return nomes;
    } catch (e) {
      print('Erro ao buscar nomes das escolas: $e');
      return [];
    }
  }

  // Buscar múltiplas escolas por IDs
  Future<List<Escola>> getEscolasByIds(List<String> escolaIds) async {
    if (escolaIds.isEmpty) return [];

    try {
      // Otimizado: usa whereIn para buscar múltiplos IDs em uma consulta
      final List<Escola> escolas = [];

      // Divide em lotes de 10 para respeitar limite do Firebase
      for (int i = 0; i < escolaIds.length; i += 10) {
        final batch = escolaIds.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          escolas.add(Escola.fromFirestore(doc.data(), doc.id));
        }
      }

      return escolas;
    } catch (e) {
      print('Erro ao buscar escolas por IDs: $e');
      return [];
    }
  }

  // Buscar estatísticas de escolas por regional
  Future<Map<String, dynamic>> getEstatisticasEscolas(String regionalId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .get();

      int totalEscolas = snapshot.docs.length;
      int escolasRurais = 0;
      int escolasUrbanas = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final classificacao = data['classificacao'] ?? 'urbana';

        if (classificacao == 'rural') {
          escolasRurais++;
        } else {
          escolasUrbanas++;
        }
      }

      return {
        'totalEscolas': totalEscolas,
        'escolasRurais': escolasRurais,
        'escolasUrbanas': escolasUrbanas,
      };
    } catch (e) {
      print('Erro ao buscar estatísticas de escolas: $e');
      return {'totalEscolas': 0, 'escolasRurais': 0, 'escolasUrbanas': 0};
    }
  }
}
