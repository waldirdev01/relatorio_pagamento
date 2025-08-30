import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/contrato.dart';
import '../models/escola.dart';
import '../models/itinerario.dart';
import '../models/regional.dart';
import '../models/turno.dart';
import '../services/atividade_extracurricular_service.dart';
import '../services/escola_service.dart';
import '../services/itinerario_service.dart';
import '../services/reposicao_aula_service.dart';

class TotalizadorService {
  final ItinerarioService _itinerarioService = ItinerarioService();
  final AtividadeExtracurricularService _atividadeService =
      AtividadeExtracurricularService();
  final ReposicaoAulaService _reposicaoService = ReposicaoAulaService();
  final EscolaService _escolaService = EscolaService();

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

    // Calcular alunos por turno (assumindo que todos são matutinos por enquanto)
    final alunosPorTurno = {
      'M': totalAlunos, // Todos os alunos são matutinos por enquanto
      'V': 0,
      'N': 0,
      'INT': 0,
    };

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
        'QUADRO DE ITINERÁRIO - $mesLabel - $ano - REGIÃO "${regional.descricao.toUpperCase()}" - ${contrato.nome.toUpperCase()}',
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
    String money(double v) => 'R\$ ${v.toStringAsFixed(2)}';

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
}
