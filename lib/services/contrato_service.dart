import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/contrato.dart';

class ContratoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'contratos';

  // Adicionar novo contrato
  Future<String> adicionarContrato(Contrato contrato) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(contrato.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Erro ao adicionar contrato: $e');
    }
  }

  // Atualizar contrato existente
  Future<void> atualizarContrato(Contrato contrato) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(contrato.id)
          .update(contrato.copyWith(dataAtualizacao: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar contrato: $e');
    }
  }

  // Excluir contrato (soft delete - marca como inativo)
  Future<void> excluirContrato(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'ativo': false,
        'dataAtualizacao': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erro ao excluir contrato: $e');
    }
  }

  // Buscar contrato por ID
  Future<Contrato?> buscarContratoPorId(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Contrato.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Erro ao buscar contrato: $e');
    }
  }

  // Listar todos os contratos ativos
  Stream<List<Contrato>> listarContratosAtivos() {
    try {
      print('🔍 [CONTRATO-TODOS] Consultando todos os contratos ativos');
      print(
        '📋 [CONTRATO-TODOS] Query: collection($_collection).where(ativo == true).orderBy(nome)',
      );

      return _firestore
          .collection(_collection)
          .where('ativo', isEqualTo: true)
          .orderBy('nome') // ⚠️ Pode gerar erro se não houver índice simples
          .snapshots()
          .map((snapshot) {
            print(
              '📊 [CONTRATO-TODOS] Contratos encontrados: ${snapshot.docs.length}',
            );
            return snapshot.docs
                .map((doc) => Contrato.fromMap(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      print('❌ [CONTRATO-TODOS] Erro ao listar contratos ativos: $e');
      print('🔗 [CONTRATO-TODOS] ERRO COMPLETO PARA CLICAR NO LINK: $e');
      throw Exception('Erro ao listar contratos: $e');
    }
  }

  // Listar contratos por regional
  Stream<List<Contrato>> listarContratosPorRegional(String regionalId) {
    try {
      print('🔍 Consultando contratos para regional: $regionalId');
      print(
        '📋 Query: collection($_collection).where(regionalId == $regionalId).where(ativo == true).orderBy(nome)',
      );

      return _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('ativo', isEqualTo: true)
          .orderBy('nome') // ⚠️ Vai gerar erro com link para criar índice
          .snapshots()
          .map((snapshot) {
            print('📊 Contratos encontrados: ${snapshot.docs.length}');
            return snapshot.docs
                .map((doc) => Contrato.fromMap(doc.data(), doc.id))
                .toList();
          });
    } catch (e) {
      print('❌ Erro ao listar contratos por regional: $e');
      print('🔗 ERRO COMPLETO PARA CLICAR NO LINK: $e');
      throw Exception('Erro ao listar contratos por regional: $e');
    }
  }

  // Buscar contratos como Future (para dropdowns e seleções)
  Future<List<Contrato>> buscarContratosAtivos() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('ativo', isEqualTo: true)
          .orderBy('nome')
          .get();

      return snapshot.docs
          .map((doc) => Contrato.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar contratos: $e');
    }
  }

  // Buscar contratos ativos por regional como Future
  Future<List<Contrato>> buscarContratosPorRegional(String regionalId) async {
    try {
      print('🔍 [Future] Consultando contratos para regional: $regionalId');
      print(
        '📋 [Future] Query: collection($_collection).where(regionalId == $regionalId).where(ativo == true).orderBy(nome)',
      );

      final snapshot = await _firestore
          .collection(_collection)
          .where('regionalId', isEqualTo: regionalId)
          .where('ativo', isEqualTo: true)
          .orderBy('nome') // ⚠️ Vai gerar erro com link para criar índice
          .get();

      print('📊 [Future] Contratos encontrados: ${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => Contrato.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ [Future] Erro ao buscar contratos por regional: $e');
      print('🔗 [Future] ERRO COMPLETO PARA CLICAR NO LINK: $e');
      throw Exception('Erro ao buscar contratos por regional: $e');
    }
  }

  // Verificar se contrato está sendo usado (tem itinerários ou atividades)
  Future<bool> contratoEstaEmUso(String contratoId) async {
    try {
      // Verificar itinerários
      final itinerariosSnapshot = await _firestore
          .collection('itinerarios')
          .where('contratoId', isEqualTo: contratoId)
          .limit(1)
          .get();

      if (itinerariosSnapshot.docs.isNotEmpty) {
        return true;
      }

      // Verificar atividades extracurriculares
      final atividadesSnapshot = await _firestore
          .collection('atividades_extracurriculares')
          .where('contratoId', isEqualTo: contratoId)
          .limit(1)
          .get();

      return atividadesSnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar uso do contrato: $e');
    }
  }
}
