import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/itinerario.dart';
import '../models/regional.dart';
import '../services/atividade_extracurricular_service.dart';
import '../services/contrato_service.dart';
import '../services/itinerario_service.dart';
import '../services/reposicao_aula_service.dart';
import '../utils/currency_formatter.dart';

class EstatisticasGlobaisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContratoService _contratoService = ContratoService();
  final ItinerarioService _itinerarioService = ItinerarioService();
  final AtividadeExtracurricularService _atividadeService =
      AtividadeExtracurricularService();
  final ReposicaoAulaService _reposicaoService = ReposicaoAulaService();

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

      // Calcular estatísticas por regional usando a mesma lógica do totalizador
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
        'valorTotalNota': 0.0,
        'placasUnicas': <String>{},
      };

      for (final regional in regionais) {
        final estatisticasRegional = await _calcularEstatisticasRegional(
          regional,
          mes,
          ano,
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
        totalGeral['valorTotalNota'] +=
            estatisticasRegional['valorTotalNota'] as double;

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

  /// Calcula estatísticas de uma regional usando a mesma lógica do totalizador
  Future<Map<String, dynamic>> _calcularEstatisticasRegional(
    Regional regional,
    int mes,
    int ano,
  ) async {
    // Buscar todos os contratos da regional
    final contratos = await _contratoService.buscarContratosPorRegional(
      regional.id,
    );

    if (contratos.isEmpty) {
      return {
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
        'valorTotalNota': 0.0,
        'placasUnicas': <String>[],
      };
    }

    // Agregar dados de todos os contratos
    final placasUnicas = <String>{};
    double kmRegularTotal = 0;
    double kmExtraTotal = 0;
    int totalEi = 0, totalEf = 0, totalEm = 0, totalEe = 0, totalEja = 0;
    double valorTotalNota = 0;
    int totalItinerarios = 0;
    int totalAtividades = 0;
    int totalReposicoes = 0;

    for (final contrato in contratos) {
      // Buscar dados do contrato
      final itinerarios = await _itinerarioService
          .getItinerariosPorContrato(contrato.id)
          .catchError((e) => <Itinerario>[]);

      final atividades = await _atividadeService
          .getAtividadesPorContratoPeriodo(
            contratoId: contrato.id,
            mes: mes,
            ano: ano,
          );

      final reposicoes = await _reposicaoService
          .getReposicoesPorContratoPeriodo(
            contratoId: contrato.id,
            mes: mes,
            ano: ano,
          );

      // Filtrar itinerários por mês/ano
      final itinerariosMes = itinerarios.where((i) {
        return i.dataCriacao.month == mes && i.dataCriacao.year == ano;
      }).toList();

      // Agregações do contrato
      final placasContrato = <String>{};
      double kmRegularContrato = 0;
      double kmExtraContrato = 0;
      int eiContrato = 0,
          efContrato = 0,
          emContrato = 0,
          eeContrato = 0,
          ejaContrato = 0;

      for (final i in itinerariosMes) {
        _adicionarPlacas(placasContrato, i.placas);
        kmRegularContrato += i.kmXNumeroOnibusXDias;
        eiContrato += i.ei ?? 0;
        efContrato += i.ef ?? 0;
        emContrato += i.em ?? 0;
        eeContrato += i.ee ?? 0;
        ejaContrato += i.eja ?? 0;
      }

      for (final a in atividades) {
        _adicionarPlacas(placasContrato, a.placas);
        kmExtraContrato += a.kmXNumeroOnibusXDias;
        eiContrato += a.ei ?? 0;
        efContrato += a.ef ?? 0;
        emContrato += a.em ?? 0;
        eeContrato += a.ee ?? 0;
        ejaContrato += a.eja ?? 0;
      }

      for (final r in reposicoes) {
        kmExtraContrato += r.kmXNumeroOnibusXDias;
      }

      final totalKmContrato = kmRegularContrato + kmExtraContrato;
      final valorNotaContrato = totalKmContrato * contrato.valorPorKm;

      // Adicionar ao total geral
      placasUnicas.addAll(placasContrato);
      kmRegularTotal += kmRegularContrato;
      kmExtraTotal += kmExtraContrato;
      totalEi += eiContrato;
      totalEf += efContrato;
      totalEm += emContrato;
      totalEe += eeContrato;
      totalEja += ejaContrato;
      valorTotalNota += valorNotaContrato;
      totalItinerarios += itinerariosMes.length;
      totalAtividades += atividades.length;
      totalReposicoes += reposicoes.length;
    }

    final totalAlunos = totalEi + totalEf + totalEm + totalEe + totalEja;
    final totalKm = kmRegularTotal + kmExtraTotal;

    return {
      'totalAlunos': totalAlunos,
      'totalEnsinoInfantil': totalEi,
      'totalEnsinoFundamental': totalEf,
      'totalEnsinoMedio': totalEm,
      'totalEducacaoEspecial': totalEe,
      'totalEja': totalEja,
      'totalOnibus': placasUnicas.length,
      'totalItinerarios': totalItinerarios,
      'totalAtividadesExtracurriculares': totalAtividades,
      'totalReposicoesAula': totalReposicoes,
      'quilometragemTotal': totalKm,
      'valorTotalNota': valorTotalNota,
      'placasUnicas': placasUnicas.toList(),
    };
  }

  /// Adiciona placas únicas ao conjunto (mesma lógica do totalizador)
  void _adicionarPlacas(Set<String> destino, String placas) {
    placas
        .split(RegExp(r'[,;\n]'))
        .map((p) => p.trim().toUpperCase())
        .where((p) => p.isNotEmpty)
        .forEach(destino.add);
  }

  /// Gera relatório PDF das estatísticas globais
  Future<void> gerarRelatorioEstatisticasPDF({
    required Map<String, dynamic> dados,
    required int mes,
    required int ano,
  }) async {
    final estatisticasPorRegional =
        dados['estatisticasPorRegional'] as Map<String, Map<String, dynamic>>;
    final totalGeral = dados['totalGeral'] as Map<String, dynamic>;

    // Configurar tema do PDF
    final theme = pw.ThemeData.withFont(
      base: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
    );

    final doc = pw.Document(theme: theme);
    final mesLabel = _nomeMes(mes).toUpperCase();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        build: (context) => [
          _buildTituloGlobal(mesLabel, ano),
          pw.SizedBox(height: 8),
          _buildResumoGeral(totalGeral, mesLabel, ano.toString()),
          pw.SizedBox(height: 8),
          _buildEstatisticasPorRegional(estatisticasPorRegional),
        ],
      ),
    );

    // Salvar e abrir o PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Relatorio_Global_${mesLabel}_$ano.pdf',
    );
  }

  /// Constrói o título do relatório global
  pw.Widget _buildTituloGlobal(String mesLabel, int ano) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'SECRETARIA DE EDUCAÇÃO',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'RELATÓRIO GLOBAL DE TRANSPORTE ESCOLAR',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$mesLabel $ano',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.blue600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói o resumo geral
  pw.Widget _buildResumoGeral(
    Map<String, dynamic> totalGeral,
    String mesLabel,
    String ano,
  ) {
    String money(double v) => CurrencyFormatter.format(v);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMO GERAL - $mesLabel $ano',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoBox(
                'TOTAL DE ALUNOS',
                totalGeral['totalAlunos'].toString(),
              ),
              _buildInfoBox(
                'TOTAL DE ÔNIBUS',
                totalGeral['totalOnibus'].toString(),
              ),
              _buildInfoBox(
                'QUILOMETRAGEM TOTAL',
                '${totalGeral['quilometragemTotal'].toStringAsFixed(1)} km',
              ),
              _buildInfoBox(
                'VALOR TOTAL',
                money(totalGeral['valorTotalNota'] ?? 0.0),
                color: PdfColors.green700,
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoBox(
                'ENSINO INFANTIL',
                totalGeral['totalEnsinoInfantil'].toString(),
              ),
              _buildInfoBox(
                'ENSINO FUNDAMENTAL',
                totalGeral['totalEnsinoFundamental'].toString(),
              ),
              _buildInfoBox(
                'ENSINO MÉDIO',
                totalGeral['totalEnsinoMedio'].toString(),
              ),
              _buildInfoBox(
                'EDUCAÇÃO ESPECIAL',
                totalGeral['totalEducacaoEspecial'].toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Constrói as estatísticas por regional
  pw.Widget _buildEstatisticasPorRegional(
    Map<String, Map<String, dynamic>> estatisticasPorRegional,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ESTATÍSTICAS POR REGIONAL',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1),
            6: const pw.FlexColumnWidth(1),
            7: const pw.FlexColumnWidth(1),
            8: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Cabeçalho
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildHeaderCell('REGIONAL'),
                _buildHeaderCell('ALUNOS'),
                _buildHeaderCell('EI'),
                _buildHeaderCell('EF'),
                _buildHeaderCell('EM'),
                _buildHeaderCell('EE'),
                _buildHeaderCell('ÔNIBUS'),
                _buildHeaderCell('KM'),
                _buildHeaderCell('VALOR'),
              ],
            ),
            // Dados das regionais
            ...estatisticasPorRegional.values.map((entry) {
              final regional = entry['regional'] as Regional;
              final estatisticas =
                  entry['estatisticas'] as Map<String, dynamic>;

              return pw.TableRow(
                children: [
                  _buildDataCell(regional.descricao, isBold: true),
                  _buildDataCell(estatisticas['totalAlunos'].toString()),
                  _buildDataCell(
                    estatisticas['totalEnsinoInfantil'].toString(),
                  ),
                  _buildDataCell(
                    estatisticas['totalEnsinoFundamental'].toString(),
                  ),
                  _buildDataCell(estatisticas['totalEnsinoMedio'].toString()),
                  _buildDataCell(
                    estatisticas['totalEducacaoEspecial'].toString(),
                  ),
                  _buildDataCell(estatisticas['totalOnibus'].toString()),
                  _buildDataCell(
                    '${estatisticas['quilometragemTotal'].toStringAsFixed(1)} km',
                  ),
                  _buildDataCell(
                    CurrencyFormatter.format(
                      estatisticas['valorTotalNota'] ?? 0.0,
                    ),
                    isBold: true,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Constrói uma caixa de informação
  pw.Widget _buildInfoBox(String label, String value, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColors.grey800,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Constrói uma célula de cabeçalho
  pw.Widget _buildHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Constrói uma célula de dados
  pw.Widget _buildDataCell(String text, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey800,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Retorna o nome do mês
  String _nomeMes(int mes) {
    const meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return meses[mes - 1];
  }
}
