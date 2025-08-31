import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/atividade_extracurricular.dart';
import '../models/itinerario.dart';
import '../models/regional.dart';
import '../models/reposicao_aula.dart';

class EstatisticasGlobaisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calcula estatísticas globais para um mês específico
  Future<Map<String, dynamic>> calcularEstatisticasGlobais({
    required int mes,
    required int ano,
  }) async {
    try {
      // Buscar todas as regionais
      final regionaisSnapshot = await _firestore
          .collection('regionais')
          .orderBy('descricao')
          .get();

      final regionais = regionaisSnapshot.docs
          .map((doc) => Regional.fromFirestore(doc.data(), doc.id))
          .toList();

      // Buscar todos os itinerários ativos
      final itinerariosSnapshot = await _firestore
          .collection('itinerarios')
          .where('ativo', isEqualTo: true)
          .get();

      // Buscar todas as atividades extracurriculares
      final atividadesSnapshot = await _firestore
          .collection('atividades_extracurriculares')
          .get();

      // Buscar todas as reposições de aula
      final reposicoesSnapshot = await _firestore
          .collection('reposicoes_aula')
          .get();

      // Converter para objetos
      final itinerarios = itinerariosSnapshot.docs
          .map((doc) => Itinerario.fromFirestore(doc.data(), doc.id))
          .toList();

      final atividades = atividadesSnapshot.docs
          .map(
            (doc) => AtividadeExtracurricular.fromFirestore(doc.data(), doc.id),
          )
          .toList();

      final reposicoes = reposicoesSnapshot.docs
          .map((doc) => ReposicaoAula.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filtrar por mês/ano
      final itinerariosFiltrados = _filtrarPorMesAno(
        itinerarios,
        mes,
        ano,
        (item) => item.dataCriacao,
      );

      final atividadesFiltradas = _filtrarPorMesAno(
        atividades,
        mes,
        ano,
        (item) => item.dataAtividade ?? item.dataCriacao,
      );

      final reposicoesFiltradas = _filtrarPorMesAno(
        reposicoes,
        mes,
        ano,
        (item) => item.dataReposicao ?? item.dataCriacao,
      );

      // Calcular estatísticas por regional
      final estatisticasPorRegional = <String, Map<String, dynamic>>{};
      Map<String, dynamic> totalGeral = {
        'totalAlunos': 0,
        'totalEnsinoInfantil': 0,
        'totalEnsinoFundamental': 0,
        'totalEnsinoMedio': 0,
        'totalEducacaoEspecial': 0,
        'totalEja': 0,
        'totalOnibus': 0,
        'totalItinerarios': 0,
        'totalAtividadesExtracurriculares': 0,
        'totalReposicoesAula': 0,
        'quilometragemTotal': 0.0,
        'placasUnicas': <String>{},
      };

      for (final regional in regionais) {
        final itinerariosRegional = itinerariosFiltrados
            .where((i) => i.regionalId == regional.id)
            .toList();
        final atividadesRegional = atividadesFiltradas
            .where((a) => a.regionalId == regional.id)
            .toList();
        final reposicoesRegional = reposicoesFiltradas
            .where((r) => r.regionalId == regional.id)
            .toList();

        final estatisticasRegional = _calcularEstatisticas(
          itinerariosRegional,
          atividadesRegional,
          reposicoesRegional,
        );

        estatisticasPorRegional[regional.id] = {
          'regional': regional,
          'estatisticas': estatisticasRegional,
        };

        // Somar ao total geral
        totalGeral['totalAlunos'] += estatisticasRegional['totalAlunos'] as int;
        totalGeral['totalEnsinoInfantil'] +=
            estatisticasRegional['totalEnsinoInfantil'] as int;
        totalGeral['totalEnsinoFundamental'] +=
            estatisticasRegional['totalEnsinoFundamental'] as int;
        totalGeral['totalEnsinoMedio'] +=
            estatisticasRegional['totalEnsinoMedio'] as int;
        totalGeral['totalEducacaoEspecial'] +=
            estatisticasRegional['totalEducacaoEspecial'] as int;
        totalGeral['totalEja'] += estatisticasRegional['totalEja'] as int;
        totalGeral['totalItinerarios'] +=
            estatisticasRegional['totalItinerarios'] as int;
        totalGeral['totalAtividadesExtracurriculares'] +=
            estatisticasRegional['totalAtividadesExtracurriculares'] as int;
        totalGeral['totalReposicoesAula'] +=
            estatisticasRegional['totalReposicoesAula'] as int;
        totalGeral['quilometragemTotal'] +=
            estatisticasRegional['quilometragemTotal'] as double;

        // Unir placas únicas
        final placasRegionais =
            estatisticasRegional['placasUnicas'] as List<String>;
        (totalGeral['placasUnicas'] as Set<String>).addAll(placasRegionais);
      }

      // Calcular total de ônibus únicos
      totalGeral['totalOnibus'] =
          (totalGeral['placasUnicas'] as Set<String>).length;

      return {
        'estatisticasPorRegional': estatisticasPorRegional,
        'totalGeral': totalGeral,
        'mes': mes,
        'ano': ano,
      };
    } catch (e) {
      print('Erro ao calcular estatísticas globais: $e');
      rethrow;
    }
  }

  /// Filtra uma lista de itens por mês e ano
  List<T> _filtrarPorMesAno<T>(
    List<T> itens,
    int mes,
    int ano,
    DateTime Function(T) getData,
  ) {
    return itens.where((item) {
      final data = getData(item);
      return data.month == mes && data.year == ano;
    }).toList();
  }

  /// Calcula as estatísticas baseadas nos dados filtrados
  Map<String, dynamic> _calcularEstatisticas(
    List<Itinerario> itinerarios,
    List<AtividadeExtracurricular> atividades,
    List<ReposicaoAula> reposicoes,
  ) {
    // Contar alunos por modalidade
    int totalAlunos = 0;
    int totalEnsinoInfantil = 0;
    int totalEnsinoFundamental = 0;
    int totalEnsinoMedio = 0;
    int totalEducacaoEspecial = 0;
    int totalEja = 0;

    // Contar ônibus únicos (por placa)
    Set<String> placasUnicas = {};

    // Contar quilometragem total
    double quilometragemTotal = 0.0;

    // Processar itinerários
    for (final itinerario in itinerarios) {
      final itinerarioComTotais = itinerario.calcularTotais();
      totalAlunos += itinerarioComTotais.total;
      totalEnsinoInfantil += itinerarioComTotais.ei ?? 0;
      totalEnsinoFundamental += itinerarioComTotais.ef ?? 0;
      totalEnsinoMedio += itinerarioComTotais.em ?? 0;
      totalEducacaoEspecial += itinerarioComTotais.ee ?? 0;
      totalEja += itinerarioComTotais.eja ?? 0;

      // Adicionar placas únicas
      if (itinerario.placas.isNotEmpty) {
        final placas = itinerario.placas.split(RegExp(r'[,;\n]'));
        for (final placa in placas) {
          final placaLimpa = placa.trim();
          if (placaLimpa.isNotEmpty) {
            placasUnicas.add(placaLimpa);
          }
        }
      }

      // Calcular quilometragem (usando KM x ÔNIBUS x DIAS)
      quilometragemTotal += itinerario.kmXNumeroOnibusXDias;
    }

    // Processar atividades extracurriculares
    for (final atividade in atividades) {
      final atividadeComTotais = atividade.calcularTotais();
      totalAlunos += atividadeComTotais.total;
      totalEnsinoInfantil += atividadeComTotais.ei ?? 0;
      totalEnsinoFundamental += atividadeComTotais.ef ?? 0;
      totalEnsinoMedio += atividadeComTotais.em ?? 0;
      totalEducacaoEspecial += atividadeComTotais.ee ?? 0;
      totalEja += atividadeComTotais.eja ?? 0;

      // Adicionar placas únicas das atividades
      if (atividade.placas.isNotEmpty) {
        final placas = atividade.placas.split(RegExp(r'[,;\n]'));
        for (final placa in placas) {
          final placaLimpa = placa.trim();
          if (placaLimpa.isNotEmpty) {
            placasUnicas.add(placaLimpa);
          }
        }
      }

      // Calcular quilometragem (usando KM x ÔNIBUS x DIAS)
      quilometragemTotal += atividade.kmXNumeroOnibusXDias;
    }

    // Processar reposições de aula
    for (final reposicao in reposicoes) {
      // Reposições não têm contagem de alunos, apenas quilometragem
      quilometragemTotal += reposicao.kmXNumeroOnibusXDias;
    }

    return {
      'totalAlunos': totalAlunos,
      'totalEnsinoInfantil': totalEnsinoInfantil,
      'totalEnsinoFundamental': totalEnsinoFundamental,
      'totalEnsinoMedio': totalEnsinoMedio,
      'totalEducacaoEspecial': totalEducacaoEspecial,
      'totalEja': totalEja,
      'totalOnibus': placasUnicas.length,
      'totalItinerarios': itinerarios.length,
      'totalAtividadesExtracurriculares': atividades.length,
      'totalReposicoesAula': reposicoes.length,
      'quilometragemTotal': quilometragemTotal,
      'placasUnicas': placasUnicas.toList(),
    };
  }

  /// Gera relatório PDF das estatísticas globais
  Future<void> gerarRelatorioEstatisticasPDF({
    required Map<String, dynamic> dados,
    required int mes,
    required int ano,
  }) async {
    // TODO: Implementar geração de PDF
    // Por enquanto, apenas printar as estatísticas
    print('=== ESTATÍSTICAS GLOBAIS - $mes/$ano ===');

    final estatisticasPorRegional =
        dados['estatisticasPorRegional'] as Map<String, Map<String, dynamic>>;
    final totalGeral = dados['totalGeral'] as Map<String, dynamic>;

    // Printar estatísticas por regional
    for (final entry in estatisticasPorRegional.entries) {
      final regional = entry.value['regional'] as Regional;
      final estatisticas = entry.value['estatisticas'] as Map<String, dynamic>;

      print('\n--- ${regional.descricao} ---');
      print('Alunos: ${estatisticas['totalAlunos']}');
      print('EI: ${estatisticas['totalEnsinoInfantil']}');
      print('EF: ${estatisticas['totalEnsinoFundamental']}');
      print('EM: ${estatisticas['totalEnsinoMedio']}');
      print('EE: ${estatisticas['totalEducacaoEspecial']}');
      print('EJA: ${estatisticas['totalEja']}');
      print('Ônibus: ${estatisticas['totalOnibus']}');
      print('Itinerários: ${estatisticas['totalItinerarios']}');
      print('Atividades: ${estatisticas['totalAtividadesExtracurriculares']}');
      print('Reposições: ${estatisticas['totalReposicoesAula']}');
      print('KM: ${estatisticas['quilometragemTotal']}');
    }

    // Printar total geral
    print('\n=== TOTAL GERAL ===');
    print('Total de Alunos: ${totalGeral['totalAlunos']}');
    print('Ensino Infantil: ${totalGeral['totalEnsinoInfantil']}');
    print('Ensino Fundamental: ${totalGeral['totalEnsinoFundamental']}');
    print('Ensino Médio: ${totalGeral['totalEnsinoMedio']}');
    print('Educação Especial: ${totalGeral['totalEducacaoEspecial']}');
    print('EJA: ${totalGeral['totalEja']}');
    print('Total de Ônibus: ${totalGeral['totalOnibus']}');
    print('Total de Itinerários: ${totalGeral['totalItinerarios']}');
    print(
      'Total de Atividades Extracurriculares: ${totalGeral['totalAtividadesExtracurriculares']}',
    );
    print('Total de Reposições de Aula: ${totalGeral['totalReposicoesAula']}');
    print('Quilometragem Total: ${totalGeral['quilometragemTotal']} km');
  }
}
