import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/contrato.dart';
import '../models/escola.dart';
import '../models/itinerario.dart';
import '../models/regional.dart';
import '../models/turno.dart';
import '../services/atividade_extracurricular_service.dart';
import '../services/contrato_service.dart';
import '../services/escola_service.dart';
import '../services/itinerario_service.dart';
import '../services/reposicao_aula_service.dart';
import '../utils/currency_formatter.dart';

class TotalizadorService {
  final ItinerarioService _itinerarioService = ItinerarioService();
  final AtividadeExtracurricularService _atividadeService =
      AtividadeExtracurricularService();
  final ReposicaoAulaService _reposicaoService = ReposicaoAulaService();
  final EscolaService _escolaService = EscolaService();
  final ContratoService _contratoService = ContratoService();

  Future<void> gerarRelatorioTotalizadorPDF({
    required Regional regional,
    required Contrato contrato,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? processoOrigem,
    String? observacoes,
  }) async {
    // Buscar dados
    final itinerarios = await _itinerarioService
        .getItinerariosPorContrato(contrato.id)
        .catchError((e) => <Itinerario>[]);

    final atividades = await _atividadeService.getAtividadesPorContratoPeriodo(
      contratoId: contrato.id,
      mes: dataInicio.month,
      ano: dataInicio.year,
    );

    final reposicoes = await _reposicaoService.getReposicoesPorContratoPeriodo(
      contratoId: contrato.id,
      mes: dataInicio.month,
      ano: dataInicio.year,
    );

    // Filtrar itinerários por mês/ano
    final itinerariosMes = itinerarios.where((i) {
      return i.dataCriacao.month == dataInicio.month &&
          i.dataCriacao.year == dataInicio.year;
    }).toList();

    // Escolas por id para classificar URBANA/RURAL
    final escolaIds = <String>{}
      ..addAll(itinerariosMes.expand((i) => i.escolaIds))
      ..addAll(atividades.expand((a) => a.escolaIds));
    final escolas = await _escolaService.getEscolasByIds(escolaIds.toList());
    final idToEscola = {for (final e in escolas) e.id: e};

    // Agregações principais
    final placasUnicas = <String>{};

    double kmRegular = 0;
    double kmExtra = 0;

    int totalEi = 0, totalEf = 0, totalEm = 0, totalEe = 0, totalEja = 0;

    for (final i in itinerariosMes) {
      _adicionarPlacas(placasUnicas, i.placas);
      kmRegular += i.kmXNumeroOnibusXDias;
      totalEi += i.ei ?? 0;
      totalEf += i.ef ?? 0;
      totalEm += i.em ?? 0;
      totalEe += i.ee ?? 0;
      totalEja += i.eja ?? 0;
    }

    for (final a in atividades) {
      _adicionarPlacas(placasUnicas, a.placas);
      kmExtra += a.kmXNumeroOnibusXDias;
      totalEi += a.ei ?? 0;
      totalEf += a.ef ?? 0;
      totalEm += a.em ?? 0;
      totalEe += a.ee ?? 0;
      totalEja += a.eja ?? 0;
    }

    for (final r in reposicoes) {
      // Reposição não tem placas próprias: usa do itinerário original já coberto
      kmExtra += r.kmXNumeroOnibusXDias;
    }

    final totalAlunos = totalEi + totalEf + totalEm + totalEe + totalEja;
    final totalKm = kmRegular + kmExtra;
    final valorNota = totalKm * contrato.valorPorKm;

    double pct(int v) => totalAlunos > 0 ? v / totalAlunos : 0;
    // String fmt(double v) => v.toStringAsFixed(2);

    // Valores por modalidade rateados pelo percentual de alunos
    final valorEi = valorNota * pct(totalEi);
    final valorEf = valorNota * pct(totalEf);
    final valorEm = valorNota * pct(totalEm);
    final valorEe = valorNota * pct(totalEe);
    final valorEja = valorNota * pct(totalEja);

    // Calcular dados por turno
    final alunosPorModalidade = {
      'EI': totalEi,
      'EF': totalEf,
      'EM': totalEm,
      'EE': totalEe,
      'EJA': totalEja,
    };

    // Calcular alunos por turno usando dados reais
    final alunosPorTurno = <String, int>{'M': 0, 'V': 0, 'N': 0, 'INT': 0};

    for (final i in itinerariosMes) {
      final alunosItinerario =
          (i.ei ?? 0) + (i.ef ?? 0) + (i.em ?? 0) + (i.ee ?? 0) + (i.eja ?? 0);
      switch (i.turno) {
        case TipoTurno.matutino:
          alunosPorTurno['M'] = (alunosPorTurno['M'] ?? 0) + alunosItinerario;
          break;
        case TipoTurno.vespertino:
          alunosPorTurno['V'] = (alunosPorTurno['V'] ?? 0) + alunosItinerario;
          break;
        case TipoTurno.noturno:
          alunosPorTurno['N'] = (alunosPorTurno['N'] ?? 0) + alunosItinerario;
          break;
        case TipoTurno.integral:
          alunosPorTurno['INT'] =
              (alunosPorTurno['INT'] ?? 0) + alunosItinerario;
          break;
      }
    }

    // Adicionar alunos das atividades extracurriculares
    for (final a in atividades) {
      final alunosAtividade =
          (a.ei ?? 0) + (a.ef ?? 0) + (a.em ?? 0) + (a.ee ?? 0) + (a.eja ?? 0);
      switch (a.turno) {
        case TipoTurno.matutino:
          alunosPorTurno['M'] = (alunosPorTurno['M'] ?? 0) + alunosAtividade;
          break;
        case TipoTurno.vespertino:
          alunosPorTurno['V'] = (alunosPorTurno['V'] ?? 0) + alunosAtividade;
          break;
        case TipoTurno.noturno:
          alunosPorTurno['N'] = (alunosPorTurno['N'] ?? 0) + alunosAtividade;
          break;
        case TipoTurno.integral:
          alunosPorTurno['INT'] =
              (alunosPorTurno['INT'] ?? 0) + alunosAtividade;
          break;
      }
    }

    // Calcular itinerários por turno
    final itinerariosPorTurno = <String, int>{'M': 0, 'V': 0, 'N': 0, 'INT': 0};

    for (final i in itinerariosMes) {
      switch (i.turno) {
        case TipoTurno.matutino:
          itinerariosPorTurno['M'] = (itinerariosPorTurno['M'] ?? 0) + 1;
          break;
        case TipoTurno.vespertino:
          itinerariosPorTurno['V'] = (itinerariosPorTurno['V'] ?? 0) + 1;
          break;
        case TipoTurno.noturno:
          itinerariosPorTurno['N'] = (itinerariosPorTurno['N'] ?? 0) + 1;
          break;
        case TipoTurno.integral:
          itinerariosPorTurno['INT'] = (itinerariosPorTurno['INT'] ?? 0) + 1;
          break;
      }
    }

    // Calcular veículos por turno (mesmo que itinerários por turno)
    final veiculosPorTurno = Map<String, int>.from(itinerariosPorTurno);

    // Contagem escolas atendidas por classificação (aproximação: escola única)
    final escolasUrb = escolaIds
        .where(
          (id) => idToEscola[id]?.classificacao == ClassificacaoEscola.urbana,
        )
        .length;
    final escolasRur = escolaIds
        .where(
          (id) => idToEscola[id]?.classificacao == ClassificacaoEscola.rural,
        )
        .length;

    // Documento com fontes que suportam Unicode (acentos)
    final baseFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final italicFont = await PdfGoogleFonts.openSansItalic();
    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      italic: italicFont,
    );
    final doc = pw.Document(theme: theme);
    final mesLabel = _nomeMes(dataInicio.month).toUpperCase();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        build: (context) => [
          _buildTitulo(regional, contrato, mesLabel, dataInicio.year),
          pw.SizedBox(height: 8),
          _buildTopInfos(
            mesLabel: mesLabel,
            ano: dataInicio.year.toString(),
            processoOrigem: processoOrigem ?? '',
            quantidadeOnibus: placasUnicas.length,
          ),
          pw.SizedBox(height: 6),
          // Tabelas de quantitativo e estatísticas
          _buildQuantitativoAlunos(
            alunosPorModalidade: alunosPorModalidade,
            alunosPorTurno: alunosPorTurno,
            totalAlunos: totalAlunos,
          ),
          pw.SizedBox(height: 6),
          _buildItinerariosVeiculosPorTurno(
            itinerariosPorTurno: itinerariosPorTurno,
            veiculosPorTurno: veiculosPorTurno,
          ),
          pw.SizedBox(height: 6),
          _buildTotalEscolas(
            escolasUrbanas: escolasUrb,
            escolasRurais: escolasRur,
          ),
          pw.SizedBox(height: 6),
          _buildValoresCabecalho(
            valorNota: valorNota,
            valorEi: valorEi,
            valorEf: valorEf,
            valorEm: valorEm,
            valorEe: valorEe,
            valorEja: valorEja,
            contrato: contrato,
          ),
          pw.SizedBox(height: 8),
          _buildObservacoes(observacoes ?? ''),
          pw.SizedBox(height: 10),
          _buildQuadroQuilometragens(
            kmMensal: kmRegular,
            kmAtivDif: kmExtra,
            kmTotal: totalKm,
          ),
          pw.SizedBox(height: 10),
          _buildEscolasUR(
            escolasUrbanas: escolasUrb,
            escolasRurais: escolasRur,
          ),
          pw.SizedBox(height: 10),
          _buildRodape(regional: regional),
        ],
      ),
    );

    await Printing.layoutPdf(
      name:
          'TOTALIZADOR_${regional.descricao}_${contrato.nome}_${mesLabel}_${dataInicio.year}.pdf',
      onLayout: (format) async => doc.save(),
    );
  }

  // ----- UI helpers -----

  pw.Widget _buildTitulo(
    Regional regional,
    Contrato contrato,
    String mesLabel,
    int ano,
  ) {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      child: pw.Text(
        'QUADRO TOTALIZADOR - $mesLabel - $ano - REGIÃO "${regional.descricao.toUpperCase()}" - ${contrato.nome.toUpperCase()}',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _smallBox(String title, String value, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
        color: color,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildTopInfos({
    required String mesLabel,
    required String ano,
    required String processoOrigem,
    required int quantidadeOnibus,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.8),
        3: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          children: [
            _smallBox('MÊS:', mesLabel),
            _smallBox('ANO:', ano),
            _smallBox('Nº PROCESSO DE ORIGEM:', processoOrigem),
            _smallBox('QUANTIDADE DE ÔNIBUS', quantidadeOnibus.toString()),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildQuantitativoAlunos({
    required Map<String, int> alunosPorModalidade,
    required Map<String, int> alunosPorTurno,
    required int totalAlunos,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(1),
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _smallBox('MODALIDADE DE ENSINO', ''),
            _smallBox('M', ''),
            _smallBox('V', ''),
            _smallBox('N', ''),
            _smallBox('INT', ''),
            _smallBox('TOTAL', ''),
            _smallBox('%', ''),
          ],
        ),
        // Linhas de dados
        pw.TableRow(
          children: [
            _smallBox('ENSINO INFANTIL', ''),
            _smallBox((alunosPorModalidade['EI'] ?? 0).toString(), ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox((alunosPorModalidade['EI'] ?? 0).toString(), ''),
            _smallBox(
              '${((alunosPorModalidade['EI'] ?? 0) / totalAlunos * 100).toStringAsFixed(2)}%',
              '',
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('ENSINO FUNDAMENTAL', ''),
            _smallBox((alunosPorModalidade['EF'] ?? 0).toString(), ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox((alunosPorModalidade['EF'] ?? 0).toString(), ''),
            _smallBox(
              '${((alunosPorModalidade['EF'] ?? 0) / totalAlunos * 100).toStringAsFixed(2)}%',
              '',
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('ENSINO MÉDIO', ''),
            _smallBox((alunosPorModalidade['EM'] ?? 0).toString(), ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox((alunosPorModalidade['EM'] ?? 0).toString(), ''),
            _smallBox(
              '${((alunosPorModalidade['EM'] ?? 0) / totalAlunos * 100).toStringAsFixed(2)}%',
              '',
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('ENSINO ESPECIAL', ''),
            _smallBox((alunosPorModalidade['EE'] ?? 0).toString(), ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox((alunosPorModalidade['EE'] ?? 0).toString(), ''),
            _smallBox(
              '${((alunosPorModalidade['EE'] ?? 0) / totalAlunos * 100).toStringAsFixed(2)}%',
              '',
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('EJA', ''),
            _smallBox('0', ''),
            _smallBox('0', ''),
            _smallBox((alunosPorModalidade['EJA'] ?? 0).toString(), ''),
            _smallBox('0', ''),
            _smallBox((alunosPorModalidade['EJA'] ?? 0).toString(), ''),
            _smallBox(
              '${((alunosPorModalidade['EJA'] ?? 0) / totalAlunos * 100).toStringAsFixed(2)}%',
              '',
            ),
          ],
        ),
        // Linha de total
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _smallBox('TOTAL', ''),
            _smallBox((alunosPorTurno['M'] ?? 0).toString(), ''),
            _smallBox((alunosPorTurno['V'] ?? 0).toString(), ''),
            _smallBox((alunosPorTurno['N'] ?? 0).toString(), ''),
            _smallBox((alunosPorTurno['INT'] ?? 0).toString(), ''),
            _smallBox(totalAlunos.toString(), ''),
            _smallBox('100.00%', ''),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildItinerariosVeiculosPorTurno({
    required Map<String, int> itinerariosPorTurno,
    required Map<String, int> veiculosPorTurno,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _smallBox('ITINERÁRIOS POR TURNO', ''),
            _smallBox('VEÍCULOS POR TURNO', ''),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('MATUTINO', (itinerariosPorTurno['M'] ?? 0).toString()),
            _smallBox('MATUTINO', (veiculosPorTurno['M'] ?? 0).toString()),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('VESPERTINO', (itinerariosPorTurno['V'] ?? 0).toString()),
            _smallBox('VESPERTINO', (veiculosPorTurno['V'] ?? 0).toString()),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('NOTURNO', (itinerariosPorTurno['N'] ?? 0).toString()),
            _smallBox('NOTURNO', (veiculosPorTurno['N'] ?? 0).toString()),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('INTEGRAL', (itinerariosPorTurno['INT'] ?? 0).toString()),
            _smallBox('INTEGRAL', (veiculosPorTurno['INT'] ?? 0).toString()),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _smallBox(
              'TOTAL',
              (itinerariosPorTurno.values.fold(0, (a, b) => a + b)).toString(),
            ),
            _smallBox(
              'TOTAL',
              (veiculosPorTurno.values.fold(0, (a, b) => a + b)).toString(),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTotalEscolas({
    required int escolasUrbanas,
    required int escolasRurais,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [_smallBox('TOTAL DE ESCOLA', '')],
        ),
        pw.TableRow(children: [_smallBox('URBANA', escolasUrbanas.toString())]),
        pw.TableRow(children: [_smallBox('RURAL', escolasRurais.toString())]),
      ],
    );
  }

  pw.Widget _buildValoresCabecalho({
    required double valorNota,
    required double valorEi,
    required double valorEf,
    required double valorEm,
    required double valorEe,
    required double valorEja,
    required Contrato contrato,
  }) {
    String money(double v) => CurrencyFormatter.format(v);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.6),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(1.6),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.6),
        5: pw.FlexColumnWidth(1.6),
        6: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          children: [
            _smallBox(
              'VALOR DA NOTA FISCAL EM R\$',
              money(valorNota),
              color: PdfColors.pink200,
            ),
            _smallBox('ENSINO INFANTIL EM R\$', money(valorEi)),
            _smallBox('ENSINO FUNDAMENTAL EM R\$', money(valorEf)),
            _smallBox('ENSINO MÉDIO EM R\$', money(valorEm)),
            _smallBox('ENSINO ESPECIAL EM R\$', money(valorEe)),
            _smallBox('EJA EM R\$', money(valorEja)),
            _smallBox('VALOR KM', money(contrato.valorPorKm)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildObservacoes(String texto) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Observações:',
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(texto, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  pw.Widget _buildQuadroQuilometragens({
    required double kmMensal,
    required double kmAtivDif,
    required double kmTotal,
  }) {
    String km(double v) => v.toStringAsFixed(2);
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          children: [
            _smallBox('QUILOMETRAGEM MENSAL', km(kmMensal)),
            _smallBox(
              'QUILOMETRAGEM DAS ATIVIDADES DIFERENCIADAS',
              km(kmAtivDif),
            ),
            _smallBox(
              'QUILOMETRAGEM TOTAL',
              km(kmTotal),
              color: PdfColors.blue200,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildEscolasUR({
    required int escolasUrbanas,
    required int escolasRurais,
  }) {
    pw.Widget bloco(String titulo, int escolas) {
      return pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text(
              titulo,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            children: [
              pw.TableRow(
                children: [_smallBox('ESCOLAS ATENDIDAS', escolas.toString())],
              ),
            ],
          ),
        ],
      );
    }

    // Render como tabela de 2 colunas para evitar Expanded/Flex overflow
    return pw.Table(
      columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1)},
      border: null,
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.only(right: 4),
              child: bloco('URBANA', escolasUrbanas),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.only(left: 4),
              child: bloco('RURAL', escolasRurais),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildRodape({required Regional regional}) {
    final dataAtual = DateTime.now();
    final dataFormatada =
        '${dataAtual.day.toString().padLeft(2, '0')}/${dataAtual.month.toString().padLeft(2, '0')}/${dataAtual.year}';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EM: $dataFormatada',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Nome chefe UNIAE',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Matrícula Chefe UNIAE',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Chefe UNIAE - ${regional.descricao.toUpperCase()}',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----- utils -----

  void _adicionarPlacas(Set<String> destino, String placasStr) {
    placasStr
        .split(RegExp(r'[;,\n]'))
        .map((p) => p.trim().toUpperCase())
        .where((p) => p.isNotEmpty)
        .forEach(destino.add);
  }

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

  /// Gera o totalizador consolidado da regional (todos os contratos)
  Future<void> gerarRelatorioTotalizadorRegionalPDF({
    required Regional regional,
    required DateTime dataInicio,
    required DateTime dataFim,
    String? processoOrigem,
    String? observacoes,
  }) async {
    // Buscar todos os contratos da regional
    final contratos = await _contratoService.buscarContratosPorRegional(
      regional.id,
    );

    if (contratos.isEmpty) {
      throw Exception('Nenhum contrato encontrado para esta regional');
    }

    // Agregar dados de todos os contratos
    final placasUnicas = <String>{};
    double kmRegularTotal = 0;
    double kmExtraTotal = 0;
    int totalEi = 0, totalEf = 0, totalEm = 0, totalEe = 0, totalEja = 0;
    double valorTotalNota = 0;

    // Dados por contrato para o relatório
    final dadosPorContrato = <Map<String, dynamic>>[];

    for (final contrato in contratos) {
      // Buscar dados do contrato
      final itinerarios = await _itinerarioService
          .getItinerariosPorContrato(contrato.id)
          .catchError((e) => <Itinerario>[]);

      final atividades = await _atividadeService
          .getAtividadesPorContratoPeriodo(
            contratoId: contrato.id,
            mes: dataInicio.month,
            ano: dataInicio.year,
          );

      final reposicoes = await _reposicaoService
          .getReposicoesPorContratoPeriodo(
            contratoId: contrato.id,
            mes: dataInicio.month,
            ano: dataInicio.year,
          );

      // Filtrar itinerários por mês/ano
      final itinerariosMes = itinerarios.where((i) {
        return i.dataCriacao.month == dataInicio.month &&
            i.dataCriacao.year == dataInicio.year;
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
      final totalAlunosContrato =
          eiContrato + efContrato + emContrato + eeContrato + ejaContrato;

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

      // Dados do contrato para o relatório
      dadosPorContrato.add({
        'contrato': contrato,
        'kmRegular': kmRegularContrato,
        'kmExtra': kmExtraContrato,
        'totalKm': totalKmContrato,
        'valorNota': valorNotaContrato,
        'ei': eiContrato,
        'ef': efContrato,
        'em': emContrato,
        'ee': eeContrato,
        'eja': ejaContrato,
        'totalAlunos': totalAlunosContrato,
        'placas': placasContrato.length,
      });
    }

    final totalAlunos = totalEi + totalEf + totalEm + totalEe + totalEja;
    final totalKm = kmRegularTotal + kmExtraTotal;

    // Calcular percentuais por modalidade
    double pct(int v) => totalAlunos > 0 ? v / totalAlunos : 0;
    final valorEi = valorTotalNota * pct(totalEi);
    final valorEf = valorTotalNota * pct(totalEf);
    final valorEm = valorTotalNota * pct(totalEm);
    final valorEe = valorTotalNota * pct(totalEe);
    final valorEja = valorTotalNota * pct(totalEja);

    // Gerar PDF
    final baseFont = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();
    final italicFont = await PdfGoogleFonts.openSansItalic();
    final theme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      italic: italicFont,
    );
    final doc = pw.Document(theme: theme);
    final mesLabel = _nomeMes(dataInicio.month).toUpperCase();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        build: (context) => [
          _buildTituloRegional(regional, mesLabel, dataInicio.year),
          pw.SizedBox(height: 8),
          _buildTopInfosRegional(
            mesLabel: mesLabel,
            ano: dataInicio.year.toString(),
            processoOrigem: processoOrigem ?? '',
            quantidadeOnibus: placasUnicas.length,
            quantidadeContratos: contratos.length,
          ),
          pw.SizedBox(height: 6),
          // Resumo geral da regional
          _buildResumoGeralRegional(
            totalAlunos: totalAlunos,
            totalKm: totalKm,
            valorTotalNota: valorTotalNota,
            valorEi: valorEi,
            valorEf: valorEf,
            valorEm: valorEm,
            valorEe: valorEe,
            valorEja: valorEja,
          ),
          pw.SizedBox(height: 6),
          // Detalhamento por contrato
          _buildDetalhamentoPorContrato(dadosPorContrato),
          pw.SizedBox(height: 8),
          _buildObservacoes(observacoes ?? ''),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name:
          'Totalizador_Regional_${regional.descricao}_${mesLabel}_${dataInicio.year}.pdf',
    );
  }

  pw.Widget _buildTituloRegional(Regional regional, String mesLabel, int ano) {
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
            'TOTALIZADOR CONSOLIDADO DA REGIONAL',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${regional.descricao.toUpperCase()} - $mesLabel $ano',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopInfosRegional({
    required String mesLabel,
    required String ano,
    required String processoOrigem,
    required int quantidadeOnibus,
    required int quantidadeContratos,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          children: [
            _smallBox('MÊS/ANO', '$mesLabel $ano'),
            _smallBox('PROCESSO ORIGEM', processoOrigem),
            _smallBox('TOTAL DE ÔNIBUS', quantidadeOnibus.toString()),
            _smallBox('TOTAL DE CONTRATOS', quantidadeContratos.toString()),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildResumoGeralRegional({
    required int totalAlunos,
    required double totalKm,
    required double valorTotalNota,
    required double valorEi,
    required double valorEf,
    required double valorEm,
    required double valorEe,
    required double valorEja,
  }) {
    String money(double v) => CurrencyFormatter.format(v);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(1.5),
        6: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _smallBox('TOTAL DE ALUNOS', totalAlunos.toString()),
            _smallBox('TOTAL KM', totalKm.toStringAsFixed(1)),
            _smallBox(
              'VALOR TOTAL NOTA',
              money(valorTotalNota),
              color: PdfColors.pink200,
            ),
            _smallBox('ENSINO INFANTIL', money(valorEi)),
            _smallBox('ENSINO FUNDAMENTAL', money(valorEf)),
            _smallBox('ENSINO MÉDIO', money(valorEm)),
            _smallBox('ENSINO ESPECIAL', money(valorEe)),
          ],
        ),
        pw.TableRow(
          children: [
            _smallBox('EJA', money(valorEja)),
            _smallBox('', ''),
            _smallBox('', ''),
            _smallBox('', ''),
            _smallBox('', ''),
            _smallBox('', ''),
            _smallBox('', ''),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDetalhamentoPorContrato(
    List<Map<String, dynamic>> dadosPorContrato,
  ) {
    String money(double v) => CurrencyFormatter.format(v);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
        5: pw.FlexColumnWidth(1),
        6: pw.FlexColumnWidth(1),
        7: pw.FlexColumnWidth(1),
        8: pw.FlexColumnWidth(1),
        9: pw.FlexColumnWidth(1),
        10: pw.FlexColumnWidth(1),
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _smallBox('CONTRATO', ''),
            _smallBox('KM REGULAR', ''),
            _smallBox('KM EXTRA', ''),
            _smallBox('TOTAL KM', ''),
            _smallBox('VALOR NOTA', ''),
            _smallBox('EI', ''),
            _smallBox('EF', ''),
            _smallBox('EM', ''),
            _smallBox('EE', ''),
            _smallBox('EJA', ''),
            _smallBox('TOTAL ALUNOS', ''),
          ],
        ),
        // Dados de cada contrato
        ...dadosPorContrato.map((dados) {
          final contrato = dados['contrato'] as Contrato;
          return pw.TableRow(
            children: [
              _smallBox(contrato.nome, ''),
              _smallBox(dados['kmRegular'].toStringAsFixed(1), ''),
              _smallBox(dados['kmExtra'].toStringAsFixed(1), ''),
              _smallBox(dados['totalKm'].toStringAsFixed(1), ''),
              _smallBox(money(dados['valorNota']), ''),
              _smallBox(dados['ei'].toString(), ''),
              _smallBox(dados['ef'].toString(), ''),
              _smallBox(dados['em'].toString(), ''),
              _smallBox(dados['ee'].toString(), ''),
              _smallBox(dados['eja'].toString(), ''),
              _smallBox(dados['totalAlunos'].toString(), ''),
            ],
          );
        }),
      ],
    );
  }
}
