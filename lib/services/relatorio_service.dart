import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/atividade_extracurricular.dart';
import '../models/contrato.dart';
import '../models/itinerario.dart';
import '../models/regional.dart';
import '../models/reposicao_aula.dart';
import '../models/turno.dart';
import 'escola_service.dart';

class RelatorioService {
  final EscolaService _escolaService = EscolaService();

  // Gerar relatório PDF
  Future<Uint8List> gerarRelatorioPDF({
    required Regional regional,
    required Contrato contrato,
    required List<Itinerario> itinerarios,
    required List<AtividadeExtracurricular> atividadesExtracurriculares,
    required Map<String, List<ReposicaoAula>> reposicoesPorItinerario,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final pdf = pw.Document();

    // Obter nomes das escolas para todos os itinerários e atividades (paralelo)
    final Map<String, List<String>> escolasPorItinerario = {};
    final futuresItinerarios = itinerarios
        .map(
          (it) async => MapEntry(
            it.id,
            await _escolaService.getNomesEscolas(it.escolaIds),
          ),
        )
        .toList();
    final resultadosItinerarios = await Future.wait(futuresItinerarios);
    for (final entry in resultadosItinerarios) {
      escolasPorItinerario[entry.key] = entry.value;
    }

    final Map<String, List<String>> escolasPorAtividade = {};
    final futuresAtividades = atividadesExtracurriculares
        .map(
          (at) async => MapEntry(
            at.id,
            await _escolaService.getNomesEscolas(at.escolaIds),
          ),
        )
        .toList();
    final resultadosAtividades = await Future.wait(futuresAtividades);
    for (final entry in resultadosAtividades) {
      escolasPorAtividade[entry.key] = entry.value;
    }

    // Calcular totais
    final totais = _calcularTotais(
      itinerarios,
      atividadesExtracurriculares,
      reposicoesPorItinerario,
      dataInicio,
      dataFim,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabeçalho
            _buildCabecalho(regional, contrato, dataInicio, dataFim),
            pw.SizedBox(height: 20),

            // Tabela de itinerários e atividades extracurriculares
            _buildTabelaItinerarios(
              itinerarios,
              atividadesExtracurriculares,
              reposicoesPorItinerario,
              escolasPorItinerario,
              escolasPorAtividade,
              dataInicio,
              dataFim,
            ),
            pw.SizedBox(height: 15),

            // Seção de totais por modalidade e KM (lado a lado)
            _buildTotaisDetalhados(totais),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // Imprimir relatório
  Future<void> imprimirRelatorio({
    required Regional regional,
    required Contrato contrato,
    required List<Itinerario> itinerarios,
    required List<AtividadeExtracurricular> atividadesExtracurriculares,
    required Map<String, List<ReposicaoAula>> reposicoesPorItinerario,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final pdfBytes = await gerarRelatorioPDF(
      regional: regional,
      contrato: contrato,
      itinerarios: itinerarios,
      atividadesExtracurriculares: atividadesExtracurriculares,
      reposicoesPorItinerario: reposicoesPorItinerario,
      dataInicio: dataInicio,
      dataFim: dataFim,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name:
          '${contrato.nome} ${_obterNomeMes(dataInicio.month)} ${dataInicio.year}.pdf',
    );
  }

  // Construir cabeçalho
  pw.Widget _buildCabecalho(
    Regional regional,
    Contrato contrato,
    DateTime dataInicio,
    DateTime dataFim,
  ) {
    final meses = [
      'JANEIRO',
      'FEVEREIRO',
      'MARÇO',
      'ABRIL',
      'MAIO',
      'JUNHO',
      'JULHO',
      'AGOSTO',
      'SETEMBRO',
      'OUTUBRO',
      'NOVEMBRO',
      'DEZEMBRO',
    ];
    final mes = meses[dataInicio.month - 1];
    final ano = dataInicio.year;

    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'QUADRO DE ITINERÁRIOS -- $mes $ano -- ${regional.descricao.toUpperCase()} - CONTRATO: ${contrato.nome.toUpperCase()}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'VALOR POR KM: R\$ ${contrato.valorPorKm.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Data de Emissão: ${_formatarData(DateTime.now())}',
            style: pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Construir tabela de itinerários e atividades extracurriculares
  pw.Widget _buildTabelaItinerarios(
    List<Itinerario> itinerarios,
    List<AtividadeExtracurricular> atividadesExtracurriculares,
    Map<String, List<ReposicaoAula>> reposicoesPorItinerario,
    Map<String, List<String>> escolasPorItinerario,
    Map<String, List<String>> escolasPorAtividade,
    DateTime dataInicio,
    DateTime dataFim,
  ) {
    // Filtrar atividades extracurriculares: apenas status REALIZADA e mesmo mês
    final atividadesFiltradas = atividadesExtracurriculares.where((atividade) {
      if (atividade.status != StatusAtividadeExtracurricular.realizada) {
        return false;
      }

      // Verificar se é do mesmo mês
      final dataReferencia = atividade.dataAtividade ?? atividade.dataCriacao;
      return dataReferencia.month == dataInicio.month &&
          dataReferencia.year == dataInicio.year;
    }).toList();

    final headers = [
      'DESCRIÇÃO',
      'TURNO',
      'ESCOLAS',
      'TRAJETO',
      'EI',
      'EF',
      'EM',
      'EE',
      'EJA',
      'TOTAL',
      'Nº\nÔNIBUS',
      'PLACAS',
      'KM',
      'KM X Nº ÔNIBUS',
      'DIAS TRAB.',
      'KM X Nº ÔNIBUS X DIAS',
      'KM\nREP',
      'Nº ÔNIBUS\nREP.',
      'KM X ÔNIBUS\nREP.',
      'DIAS TRAB.\nREP.',
      'KM X ÔNIBUS X DIAS\nREP.',
      'MOTORISTAS',
      'MONITORAS',
      'DATA ATIV. EXTRA/REP. / OBS',
    ];

    final rows = <List<String>>[];

    // Adicionar linhas dos itinerários (somando reposições do mês/ano na mesma linha)
    for (final itinerario in itinerarios) {
      final escolas = escolasPorItinerario[itinerario.id] ?? [];
      final escolasText = escolas.join(', ');

      final reposicoesDoItinerario =
          (reposicoesPorItinerario[itinerario.id] ?? []).where((r) {
            final dataRef =
                r.dataReposicao ?? r.dataSolicitacao ?? r.dataCriacao;
            return dataRef.month == dataInicio.month &&
                dataRef.year == dataInicio.year;
          }).toList();

      double somaKmRepos = 0;
      double somaKmXOnibusRepos = 0;
      int somaDiasRepos = 0;
      double somaKmXOnibusXDiasRepos = 0;
      final List<String> dataObsRepos = [];
      for (final r in reposicoesDoItinerario) {
        somaKmRepos += r.km;
        somaKmXOnibusRepos += r.kmXNumeroOnibus;
        somaDiasRepos += r.diasTrabalhados;
        somaKmXOnibusXDiasRepos += r.kmXNumeroOnibusXDias;
        final dataRef = r.dataReposicao ?? r.dataSolicitacao ?? r.dataCriacao;
        final obs = r.observacoes ?? '';
        dataObsRepos.add(
          '${_formatarData(dataRef)}${obs.isNotEmpty ? ' - $obs' : ''}',
        );
      }

      final colunaDataObs = dataObsRepos.isEmpty ? '' : dataObsRepos.join('\n');

      rows.add([
        itinerario.itinerario,
        itinerario.turno.descricao,
        escolasText,
        itinerario.trajeto,
        (itinerario.ei ?? 0).toString(),
        (itinerario.ef ?? 0).toString(),
        (itinerario.em ?? 0).toString(),
        (itinerario.ee ?? 0).toString(),
        (itinerario.eja ?? 0).toString(),
        itinerario.total.toString(),
        itinerario.numeroOnibus.toString(),
        itinerario.placas,
        itinerario.km.toStringAsFixed(1), // KM regular
        itinerario.kmXNumeroOnibus.toStringAsFixed(1), // KM X ÔNIBUS regular
        itinerario.diasTrabalhados.toString(), // DIAS TRAB. regular
        itinerario.kmXNumeroOnibusXDias.toStringAsFixed(
          1,
        ), // KM X ÔNIBUS X DIAS regular
        somaKmRepos.toStringAsFixed(1), // KM REPOSIÇÃO
        reposicoesDoItinerario.isNotEmpty
            ? reposicoesDoItinerario.map((r) => r.numeroOnibus).join(', ')
            : '', // Nº ÔNIBUS REPOSIÇÃO
        somaKmXOnibusRepos.toStringAsFixed(1), // KM X ÔNIBUS REPOSIÇÃO
        somaDiasRepos.toString(), // DIAS TRAB. REPOSIÇÃO
        somaKmXOnibusXDiasRepos.toStringAsFixed(
          1,
        ), // KM X ÔNIBUS X DIAS REPOSIÇÃO
        itinerario.motoristas,
        itinerario.monitoras,
        colunaDataObs,
      ]);
    }

    // Adicionar linhas das atividades extracurriculares filtradas
    final atividadeRows = <List<String>>[];
    for (final atividade in atividadesFiltradas) {
      final escolas = escolasPorAtividade[atividade.id] ?? [];
      final escolasText = escolas.join(', ');
      final dataRef =
          atividade.dataAtividade ??
          atividade.dataSolicitacao ??
          atividade.dataCriacao;
      final obs = atividade.observacoes ?? '';
      final dataObs =
          '${_formatarData(dataRef)}${obs.isNotEmpty ? ' - $obs' : ''}';

      atividadeRows.add([
        'Atividade Extracurricular', // Primeira coluna sempre "Atividade Extracurricular"
        atividade.turno.descricao,
        escolasText,
        atividade.trajeto,
        (atividade.ei ?? 0).toString(),
        (atividade.ef ?? 0).toString(),
        (atividade.em ?? 0).toString(),
        (atividade.ee ?? 0).toString(),
        (atividade.eja ?? 0).toString(),
        atividade.total.toString(),
        atividade.numeroOnibus.toString(),
        atividade.placas,
        '0', // KM regular (atividade extra não tem KM regular)
        '0', // KM X ÔNIBUS regular
        '0', // DIAS TRAB. regular
        '0', // KM X ÔNIBUS X DIAS regular
        atividade.km.toStringAsFixed(
          1,
        ), // KM REPOSIÇÃO (atividade extra vai aqui)
        atividade.numeroOnibus.toString(), // Nº ÔNIBUS REPOSIÇÃO
        atividade.kmXNumeroOnibus.toStringAsFixed(1), // KM X ÔNIBUS REPOSIÇÃO
        atividade.diasTrabalhados.toString(), // DIAS TRAB. REPOSIÇÃO
        atividade.kmXNumeroOnibusXDias.toStringAsFixed(
          1,
        ), // KM X ÔNIBUS X DIAS REPOSIÇÃO
        atividade.motoristas,
        atividade.monitoras,
        dataObs,
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.1), // DESCRIÇÃO (reduzido)
        1: const pw.FlexColumnWidth(1.1), // TURNO (reduzido)
        2: const pw.FlexColumnWidth(1.2), // ESCOLAS (reduzido)
        3: const pw.FlexColumnWidth(2.5), // TRAJETO (reduzido)
        4: const pw.FlexColumnWidth(0.4), // EI (novo)
        5: const pw.FlexColumnWidth(0.4), // EF (reduzido)
        6: const pw.FlexColumnWidth(0.4), // EM (reduzido)
        7: const pw.FlexColumnWidth(0.4), // EE (reduzido)
        8: const pw.FlexColumnWidth(0.6), // EJA (reduzido)
        9: const pw.FlexColumnWidth(0.6), // TOTAL (reduzido)
        10: const pw.FlexColumnWidth(0.6), // Nº ÔNIBUS (reduzido)
        11: const pw.FlexColumnWidth(1.2), // PLACAS (reduzido)
        12: const pw.FlexColumnWidth(0.6), // KM (reduzido)
        13: const pw.FlexColumnWidth(1.0), // KM X Nº ÔNIBUS (reduzido)
        14: const pw.FlexColumnWidth(0.7), // DIAS TRAB. (reduzido)
        15: const pw.FlexColumnWidth(1.0), // KM X Nº ÔNIBUS X DIAS (reduzido)
        16: const pw.FlexColumnWidth(0.8), // KM REPOSIÇÃO
        17: const pw.FlexColumnWidth(1.0), // Nº ÔNIBUS REPOSIÇÃO
        18: const pw.FlexColumnWidth(1.0), // KM X ÔNIBUS REPOSIÇÃO
        19: const pw.FlexColumnWidth(0.8), // DIAS TRAB. REPOSIÇÃO
        20: const pw.FlexColumnWidth(1.2), // KM X ÔNIBUS X DIAS REPOSIÇÃO
        21: const pw.FlexColumnWidth(1.2), // MOTORISTAS (reduzido)
        22: const pw.FlexColumnWidth(1.2), // MONITORAS (reduzido)
        23: const pw.FlexColumnWidth(2.0), // DATA/OBS (reduzido)
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map((header) => _buildCell(header, isHeader: true))
              .toList(),
        ),
        // Linhas de itinerários (fundo branco)
        ...rows.map(
          (row) => pw.TableRow(
            children: row.map((cell) => _buildCell(cell)).toList(),
          ),
        ),
        // Linhas de atividades extracurriculares (fundo salmão claro)
        ...atividadeRows.map(
          (row) => pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFB6C1),
            ), // Light salmon/pink
            children: row.map((cell) => _buildCell(cell)).toList(),
          ),
        ),
      ],
    );
  }

  // Construir célula da tabela
  pw.Widget _buildCell(String text, {bool isHeader = false}) {
    return pw.Container(
      alignment: pw.Alignment.bottomCenter,
      child: isHeader && text == 'DESCRIÇÃO'
          ? pw.Transform.rotate(
              angle: 0.5708, // -90 graus
              child: pw.Container(
                width: 25,
                height: 40,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: 4,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            )
          : pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 5,
                fontWeight: isHeader
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
              textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
            ),
    );
  }

  // Construir totais detalhados (lado a lado)
  pw.Widget _buildTotaisDetalhados(Map<String, dynamic> totais) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Totais por modalidade (esquerda) - fundo laranja
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
              color: const PdfColor.fromInt(0xFFFFE0B2), // Laranja claro
            ),
            child: pw.Column(
              children: [
                // Cabeçalho principal
                pw.Container(
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.orange300,
                  ),
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(
                    'TOTAL DE ALUNOS POR MODALIDADE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // Tabela de modalidades
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                  children: [
                    // Cabeçalho da tabela
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.orange200,
                      ),
                      children: [
                        _buildCellTotais('EI', isHeader: true),
                        _buildCellTotais('EF', isHeader: true),
                        _buildCellTotais('EM', isHeader: true),
                        _buildCellTotais('EE', isHeader: true),
                        _buildCellTotais('EJA', isHeader: true),
                        _buildCellTotais('TOTAL', isHeader: true),
                      ],
                    ),
                    // Dados
                    pw.TableRow(
                      children: [
                        _buildCellTotais('${totais['totalEi']}'),
                        _buildCellTotais('${totais['totalEf']}'),
                        _buildCellTotais('${totais['totalEm']}'),
                        _buildCellTotais('${totais['totalEe']}'),
                        _buildCellTotais('${totais['totalEja']}'),
                        _buildCellTotais(
                          '${totais['totalAlunos']}',
                          isBold: true,
                        ),
                      ],
                    ),
                    // Linha extra para igualar altura com outras tabelas
                    pw.TableRow(
                      children: [
                        pw.Container(
                          height:
                              8, // Altura fixa para igualar com outras tabelas
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 0.5,
                            ),
                          ),
                        ),
                        pw.Container(
                          height: 8,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 0.5,
                            ),
                          ),
                        ),
                        pw.Container(
                          height: 8,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 0.5,
                            ),
                          ),
                        ),
                        pw.Container(
                          height: 8,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 0.5,
                            ),
                          ),
                        ),
                        pw.Container(
                          height: 8,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 0.5,
                            ),
                          ),
                        ),
                        pw.Container(
                          height: 8,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 5),
        // Totais de KM (meio) - fundo azul
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
              color: const PdfColor.fromInt(0xFFE3F2FD), // Azul claro
            ),
            child: pw.Column(
              children: [
                // Cabeçalho principal
                pw.Container(
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(color: PdfColors.blue300),
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(
                    'TOTAIS DE KM',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // Tabela de KM
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                  children: [
                    // Cabeçalho da tabela
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue200,
                      ),
                      children: [
                        _buildCellTotais(
                          'KM DIÁRIO\n(01 veículo)',
                          isHeader: true,
                        ),
                        _buildCellTotais('KM DIÁRIO', isHeader: true),
                        _buildCellTotais('KM MENSAL', isHeader: true),
                        _buildCellTotais('KM EXTRA', isHeader: true),
                        _buildCellTotais('TOTAL\nÔNIBUS', isHeader: true),
                        _buildCellTotais('TOTAL\nÔNIBUS A.E', isHeader: true),
                      ],
                    ),
                    // Dados
                    pw.TableRow(
                      children: [
                        _buildCellTotais('${totais['kmDiario']}'),
                        _buildCellTotais('${totais['kmDiarioPorVeiculo']}'),
                        _buildCellTotais('${totais['totalKmXOnibusXDias']}'),
                        _buildCellTotais(
                          '${totais['totalKmExtra']}',
                          isBold: true,
                        ),
                        _buildCellTotais('${totais['totalOnibus']}'),
                        _buildCellTotais('${totais['totalOnibusAtividades']}'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 5),
        // Contagem de itinerários (direita) - fundo roxo
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
              color: const PdfColor.fromInt(0xFFF3E5F5), // Roxo claro
            ),
            child: pw.Column(
              children: [
                // Cabeçalho principal
                pw.Container(
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.purple300,
                  ),
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(
                    'CONTAGEM DE ITINERÁRIOS E ATIVIDADES',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                // Tabela de contagem
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                  children: [
                    // Cabeçalho da tabela
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.purple200,
                      ),
                      children: [
                        _buildCellTotais('TOTAL\nITINERÁRIOS', isHeader: true),
                        _buildCellTotais('CÓPIAS', isHeader: true),
                        _buildCellTotais('ATIVIDADES\nEXTRAS', isHeader: true),
                      ],
                    ),
                    // Dados
                    pw.TableRow(
                      children: [
                        _buildCellTotais('${totais['totalItinerarios']}'),
                        _buildCellTotais('${totais['totalCopias']}'),
                        _buildCellTotais('${totais['totalAtividades']}'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Célula para tabelas de totais
  pw.Widget _buildCellTotais(
    String text, {
    bool isHeader = false,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6,
          fontWeight: isHeader || isBold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Calcular todos os totais
  Map<String, dynamic> _calcularTotais(
    List<Itinerario> itinerarios,
    List<AtividadeExtracurricular> atividadesExtracurriculares,
    Map<String, List<ReposicaoAula>> reposicoesPorItinerario,
    DateTime dataInicio,
    DateTime dataFim,
  ) {
    // Filtrar atividades extracurriculares: apenas status REALIZADA e mesmo mês
    final atividadesFiltradas = atividadesExtracurriculares.where((atividade) {
      if (atividade.status != StatusAtividadeExtracurricular.realizada) {
        return false;
      }

      // Verificar se é do mesmo mês
      final dataReferencia = atividade.dataAtividade ?? atividade.dataCriacao;
      return dataReferencia.month == dataInicio.month &&
          dataReferencia.year == dataInicio.year;
    }).toList();

    // TOTAIS DE ALUNOS (soma tudo)
    int totalEi = 0;
    int totalEf = 0;
    int totalEm = 0;
    int totalEe = 0;
    int totalEja = 0;

    // TOTAIS REGULARES (apenas itinerários)
    double totalKmRegular = 0;
    double totalKmXOnibusRegular = 0;
    int totalDiasRegular = 0;
    double totalKmXOnibusXDiasRegular = 0;

    // TOTAIS EXTRAS (reposições + atividades extras)
    double totalKmXOnibusExtra = 0;
    int totalDiasExtra = 0;
    double totalKmXOnibusXDiasExtra = 0;

    // Contar itinerários e cópias
    int totalItinerarios = 0;
    int totalCopias = 0;

    // Contar ônibus únicos por placas
    Set<String> placasUnicas = {};
    Set<String> placasAtividades = {};

    // Somar totais dos itinerários (REGULARES)
    for (final itinerario in itinerarios) {
      totalEi += (itinerario.ei ?? 0);
      totalEf += (itinerario.ef ?? 0);
      totalEm += (itinerario.em ?? 0);
      totalEe += (itinerario.ee ?? 0);
      totalEja += (itinerario.eja ?? 0);

      totalKmRegular += itinerario.km;
      totalKmXOnibusRegular += itinerario.kmXNumeroOnibus;
      totalDiasRegular += itinerario.diasTrabalhados;
      totalKmXOnibusXDiasRegular += itinerario.kmXNumeroOnibusXDias;

      // Contar itinerários e cópias
      totalItinerarios++;
      if (itinerario.isCopia) {
        totalCopias++;
      }

      // Coletar placas únicas (convertendo para maiúscula)
      if (itinerario.placas.isNotEmpty) {
        // Dividir por vírgula, ponto e vírgula ou quebra de linha para múltiplas placas
        final placasList = itinerario.placas
            .split(RegExp(r'[,;\n]'))
            .map((p) => p.trim().toUpperCase())
            .where((p) => p.isNotEmpty);
        placasUnicas.addAll(placasList);
      }
    }

    // Somar totais das atividades extracurriculares filtradas (EXTRAS)
    for (final atividade in atividadesFiltradas) {
      totalEi += (atividade.ei ?? 0);
      totalEf += (atividade.ef ?? 0);
      totalEm += (atividade.em ?? 0);
      totalEe += (atividade.ee ?? 0);
      totalEja += (atividade.eja ?? 0);

      totalKmXOnibusExtra += atividade.kmXNumeroOnibus;
      totalDiasExtra += atividade.diasTrabalhados;
      totalKmXOnibusXDiasExtra += atividade.kmXNumeroOnibusXDias;

      // Coletar placas das atividades (convertendo para maiúscula)
      if (atividade.placas.isNotEmpty) {
        // Dividir por vírgula, ponto e vírgula ou quebra de linha para múltiplas placas
        final placasList = atividade.placas
            .split(RegExp(r'[,;\n]'))
            .map((p) => p.trim().toUpperCase())
            .where((p) => p.isNotEmpty);
        placasAtividades.addAll(placasList);
      }
    }

    // Somar totais das reposições do período (EXTRAS)
    for (final entry in reposicoesPorItinerario.entries) {
      final reposicoes = entry.value.where((r) {
        final dataRef = r.dataReposicao ?? r.dataSolicitacao ?? r.dataCriacao;
        return dataRef.month == dataInicio.month &&
            dataRef.year == dataInicio.year;
      });
      for (final reposicao in reposicoes) {
        totalKmXOnibusExtra += reposicao.kmXNumeroOnibus;
        totalDiasExtra += reposicao.diasTrabalhados;
        totalKmXOnibusXDiasExtra += reposicao.kmXNumeroOnibusXDias;
      }
    }

    final totalAlunos = totalEi + totalEf + totalEm + totalEe + totalEja;

    // Calcular KM DIÁRIO (01 veículo) = total KM X ÔNIBUS X DIAS regulares ÷ total dias regulares
    final kmDiarioPorVeiculo = totalDiasRegular > 0
        ? (totalKmXOnibusXDiasRegular / totalDiasRegular).toStringAsFixed(1)
        : '0.0';

    // Calcular KM DIÁRIO = total KM X ÔNIBUS X DIAS regulares ÷ total dias regulares ÷ total ônibus regulares
    final totalOnibusRegular = itinerarios.fold(
      0,
      (sum, it) => sum + it.numeroOnibus,
    );
    final kmDiario = totalDiasRegular > 0 && totalOnibusRegular > 0
        ? (totalKmXOnibusXDiasRegular / totalDiasRegular / totalOnibusRegular)
              .toStringAsFixed(1)
        : '0.0';

    return {
      'totalEi': totalEi,
      'totalEf': totalEf,
      'totalEm': totalEm,
      'totalEe': totalEe,
      'totalEja': totalEja,
      'totalAlunos': totalAlunos,
      // KM REGULARES (para KM DIÁRIO e KM MENSAL)
      'totalKm': totalKmRegular.toStringAsFixed(1),
      'totalKmXOnibus': totalKmXOnibusRegular.toStringAsFixed(1),
      'totalDias': totalDiasRegular,
      'totalKmXOnibusXDias': totalKmXOnibusXDiasRegular.toStringAsFixed(1),
      // KM DIÁRIO calculados
      'kmDiarioPorVeiculo': kmDiarioPorVeiculo,
      'kmDiario': kmDiario,
      // KM EXTRAS (para KM EXTRA) - soma KM X ÔNIBUS X DIAS das reposições + atividades extras
      'totalKmExtra': totalKmXOnibusXDiasExtra.toStringAsFixed(1),
      'totalKmXOnibusExtra': totalKmXOnibusExtra.toStringAsFixed(1),
      'totalDiasExtra': totalDiasExtra,
      'totalKmXOnibusXDiasExtra': totalKmXOnibusXDiasExtra.toStringAsFixed(1),
      'totalItinerarios': totalItinerarios,
      'totalCopias': totalCopias,
      'totalAtividades': atividadesFiltradas.length,
      'totalOnibus': placasUnicas.length,
      'totalOnibusAtividades': placasAtividades.length,
    };
  }

  // Obter nome do mês
  String _obterNomeMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return meses[mes - 1];
  }

  // Formatar data
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
