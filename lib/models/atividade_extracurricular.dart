import 'turno.dart';

enum StatusAtividadeExtracurricular {
  criada('Criada'),
  enviadaParaTcb('Enviada para TCB'),
  aprovadaPelaTcb('Aprovada pela TCB'),
  realizada('Realizada'),
  cancelada('Cancelada'),
  reprovada('Reprovada');

  const StatusAtividadeExtracurricular(this.descricao);
  final String descricao;
}

class AtividadeExtracurricular {
  final String id;
  final String regionalId;
  final String contratoId; // Vinculação com contrato

  // Informações básicas
  final String descricao; // Em vez de "itinerario"
  final TipoTurno turno;
  final List<String> escolaIds;
  final String trajeto;

  // Campos específicos de atividade extracurricular
  final StatusAtividadeExtracurricular status;
  final String? codigoTcb;
  final DateTime? dataSolicitacao;
  final DateTime? dataAtividade; // Quando a atividade está programada
  final String? motivoCancelamento; // Para status cancelada ou reprovada

  // Contadores de alunos
  final int? ei; // Ensino Infantil
  final int? ef; // Ensino Fundamental
  final int? em; // Ensino Médio
  final int? ee; // Educação Especial
  final int? eja; // Educação de Jovens e Adultos
  final int total;

  // Informações de transporte
  final int numeroOnibus;
  final String placas;
  final double km;
  final double kmXNumeroOnibus;
  final int diasTrabalhados;
  final double kmXNumeroOnibusXDias;

  // Pessoal
  final String motoristas;
  final String monitoras;

  // Metadados
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;
  final String? observacoes;

  // Rastreamento de usuário
  final String? usuarioCriacaoId; // Quem criou
  final String? usuarioAtualizacaoId; // Quem fez a última atualização

  AtividadeExtracurricular({
    required this.id,
    required this.regionalId,
    required this.contratoId,
    required this.descricao,
    required this.turno,
    required this.escolaIds,
    required this.trajeto,
    required this.status,
    this.codigoTcb,
    this.dataSolicitacao,
    this.dataAtividade,
    this.motivoCancelamento,
    this.ei,
    this.ef,
    this.em,
    this.ee,
    this.eja,
    required this.total,
    required this.numeroOnibus,
    required this.placas,
    required this.km,
    required this.kmXNumeroOnibus,
    required this.diasTrabalhados,
    required this.kmXNumeroOnibusXDias,
    required this.motoristas,
    required this.monitoras,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.observacoes,
    this.usuarioCriacaoId,
    this.usuarioAtualizacaoId,
  });

  // Construtor para criar AtividadeExtracurricular a partir do Firestore
  factory AtividadeExtracurricular.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return AtividadeExtracurricular(
      id: id,
      regionalId: data['regionalId'] ?? '',
      contratoId: data['contratoId'] ?? '',
      descricao: data['descricao'] ?? '',
      turno: TipoTurno.values.firstWhere(
        (e) => e.name == data['turno'],
        orElse: () => TipoTurno.matutino,
      ),
      escolaIds: List<String>.from(data['escolaIds'] ?? []),
      trajeto: data['trajeto'] ?? '',
      status: StatusAtividadeExtracurricular.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => StatusAtividadeExtracurricular.criada,
      ),
      codigoTcb: data['codigoTcb'],
      dataSolicitacao: data['dataSolicitacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataSolicitacao'])
          : null,
      dataAtividade: data['dataAtividade'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataAtividade'])
          : null,
      motivoCancelamento: data['motivoCancelamento'],
      ei: data['ei'],
      ef: data['ef'],
      em: data['em'],
      ee: data['ee'],
      eja: data['eja'],
      total: data['total'] ?? 0,
      numeroOnibus: data['numeroOnibus'] ?? 0,
      placas: data['placas'] ?? '',
      km: (data['km'] ?? 0.0).toDouble(),
      kmXNumeroOnibus: (data['kmXNumeroOnibus'] ?? 0.0).toDouble(),
      diasTrabalhados: data['diasTrabalhados'] ?? 0,
      kmXNumeroOnibusXDias: (data['kmXNumeroOnibusXDias'] ?? 0.0).toDouble(),
      motoristas: data['motoristas'] ?? '',
      monitoras: data['monitoras'] ?? '',
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(data['dataCriacao']),
      dataAtualizacao: data['dataAtualizacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataAtualizacao'])
          : null,
      observacoes: data['observacoes'],
      usuarioCriacaoId: data['usuarioCriacaoId'],
      usuarioAtualizacaoId: data['usuarioAtualizacaoId'],
    );
  }

  // Método para converter AtividadeExtracurricular para Map (Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'regionalId': regionalId,
      'contratoId': contratoId,
      'descricao': descricao,
      'turno': turno.name,
      'escolaIds': escolaIds,
      'trajeto': trajeto,
      'status': status.name,
      if (codigoTcb != null) 'codigoTcb': codigoTcb,
      if (dataSolicitacao != null)
        'dataSolicitacao': dataSolicitacao!.millisecondsSinceEpoch,
      if (dataAtividade != null)
        'dataAtividade': dataAtividade!.millisecondsSinceEpoch,
      if (motivoCancelamento != null) 'motivoCancelamento': motivoCancelamento,
      'total': total,
      'numeroOnibus': numeroOnibus,
      'placas': placas,
      'km': km,
      'kmXNumeroOnibus': kmXNumeroOnibus,
      'diasTrabalhados': diasTrabalhados,
      'kmXNumeroOnibusXDias': kmXNumeroOnibusXDias,
      'motoristas': motoristas,
      'monitoras': monitoras,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      if (dataAtualizacao != null)
        'dataAtualizacao': dataAtualizacao!.millisecondsSinceEpoch,
      if (observacoes != null) 'observacoes': observacoes,
      if (ei != null) 'ei': ei,
      if (ef != null) 'ef': ef,
      if (em != null) 'em': em,
      if (ee != null) 'ee': ee,
      if (eja != null) 'eja': eja,
      if (usuarioCriacaoId != null) 'usuarioCriacaoId': usuarioCriacaoId,
      if (usuarioAtualizacaoId != null)
        'usuarioAtualizacaoId': usuarioAtualizacaoId,
    };
  }

  // Método para criar uma cópia com alterações
  AtividadeExtracurricular copyWith({
    String? id,
    String? regionalId,
    String? contratoId,
    String? descricao,
    TipoTurno? turno,
    List<String>? escolaIds,
    String? trajeto,
    StatusAtividadeExtracurricular? status,
    String? codigoTcb,
    DateTime? dataSolicitacao,
    DateTime? dataAtividade,
    String? motivoCancelamento,
    int? ei,
    int? ef,
    int? em,
    int? ee,
    int? eja,
    int? total,
    int? numeroOnibus,
    String? placas,
    double? km,
    double? kmXNumeroOnibus,
    int? diasTrabalhados,
    double? kmXNumeroOnibusXDias,
    String? motoristas,
    String? monitoras,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    String? observacoes,
    String? usuarioCriacaoId,
    String? usuarioAtualizacaoId,
  }) {
    return AtividadeExtracurricular(
      id: id ?? this.id,
      regionalId: regionalId ?? this.regionalId,
      contratoId: contratoId ?? this.contratoId,
      descricao: descricao ?? this.descricao,
      turno: turno ?? this.turno,
      escolaIds: escolaIds ?? this.escolaIds,
      trajeto: trajeto ?? this.trajeto,
      status: status ?? this.status,
      codigoTcb: codigoTcb ?? this.codigoTcb,
      dataSolicitacao: dataSolicitacao ?? this.dataSolicitacao,
      dataAtividade: dataAtividade ?? this.dataAtividade,
      motivoCancelamento: motivoCancelamento ?? this.motivoCancelamento,
      ei: ei ?? this.ei,
      ef: ef ?? this.ef,
      em: em ?? this.em,
      ee: ee ?? this.ee,
      eja: eja ?? this.eja,
      total: total ?? this.total,
      numeroOnibus: numeroOnibus ?? this.numeroOnibus,
      placas: placas ?? this.placas,
      km: km ?? this.km,
      kmXNumeroOnibus: kmXNumeroOnibus ?? this.kmXNumeroOnibus,
      diasTrabalhados: diasTrabalhados ?? this.diasTrabalhados,
      kmXNumeroOnibusXDias: kmXNumeroOnibusXDias ?? this.kmXNumeroOnibusXDias,
      motoristas: motoristas ?? this.motoristas,
      monitoras: monitoras ?? this.monitoras,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      observacoes: observacoes ?? this.observacoes,
      usuarioCriacaoId: usuarioCriacaoId ?? this.usuarioCriacaoId,
      usuarioAtualizacaoId: usuarioAtualizacaoId ?? this.usuarioAtualizacaoId,
    );
  }

  // Método para calcular totais automaticamente
  AtividadeExtracurricular calcularTotais() {
    final totalCalculado =
        (ei ?? 0) + (ef ?? 0) + (em ?? 0) + (ee ?? 0) + (eja ?? 0);
    final kmXOnibus = km * numeroOnibus;
    final kmXOnibusXDias = kmXOnibus * diasTrabalhados;

    return copyWith(
      total: totalCalculado,
      kmXNumeroOnibus: kmXOnibus,
      kmXNumeroOnibusXDias: kmXOnibusXDias,
    );
  }

  @override
  String toString() {
    return 'AtividadeExtracurricular(id: $id, descricao: $descricao, escolaIds: $escolaIds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AtividadeExtracurricular && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
