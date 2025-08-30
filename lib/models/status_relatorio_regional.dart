enum StatusRelatorio { aguardando, recebido, emAnalise, aprovado, devolvido }

class StatusRelatorioRegional {
  final String id;
  final String regionalId;
  final int mes;
  final int ano;
  final StatusRelatorio status;
  final String usuarioId;
  final DateTime dataAlteracao;
  final DateTime horaAlteracao;

  const StatusRelatorioRegional({
    required this.id,
    required this.regionalId,
    required this.mes,
    required this.ano,
    required this.status,
    required this.usuarioId,
    required this.dataAlteracao,
    required this.horaAlteracao,
  });

  factory StatusRelatorioRegional.fromMap(Map<String, dynamic> map) {
    return StatusRelatorioRegional(
      id: map['id'] ?? '',
      regionalId: map['regionalId'] ?? '',
      mes: map['mes'] ?? 1,
      ano: map['ano'] ?? DateTime.now().year,
      status: StatusRelatorio.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusRelatorio.aguardando,
      ),
      usuarioId: map['usuarioId'] ?? '',
      dataAlteracao: DateTime.fromMillisecondsSinceEpoch(
        map['dataAlteracao'] ?? 0,
      ),
      horaAlteracao: DateTime.fromMillisecondsSinceEpoch(
        map['horaAlteracao'] ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'regionalId': regionalId,
      'mes': mes,
      'ano': ano,
      'status': status.name,
      'usuarioId': usuarioId,
      'dataAlteracao': dataAlteracao.millisecondsSinceEpoch,
      'horaAlteracao': horaAlteracao.millisecondsSinceEpoch,
    };
  }

  StatusRelatorioRegional copyWith({
    String? id,
    String? regionalId,
    int? mes,
    int? ano,
    StatusRelatorio? status,
    String? usuarioId,
    DateTime? dataAlteracao,
    DateTime? horaAlteracao,
  }) {
    return StatusRelatorioRegional(
      id: id ?? this.id,
      regionalId: regionalId ?? this.regionalId,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
      status: status ?? this.status,
      usuarioId: usuarioId ?? this.usuarioId,
      dataAlteracao: dataAlteracao ?? this.dataAlteracao,
      horaAlteracao: horaAlteracao ?? this.horaAlteracao,
    );
  }

  String get statusLabel {
    switch (status) {
      case StatusRelatorio.aguardando:
        return 'Aguardando';
      case StatusRelatorio.recebido:
        return 'Recebido';
      case StatusRelatorio.emAnalise:
        return 'Em Análise';
      case StatusRelatorio.aprovado:
        return 'Aprovado';
      case StatusRelatorio.devolvido:
        return 'Devolvido';
    }
  }

  String get statusIcon {
    switch (status) {
      case StatusRelatorio.aguardando:
        return '⏳';
      case StatusRelatorio.recebido:
        return '📨';
      case StatusRelatorio.emAnalise:
        return '🔍';
      case StatusRelatorio.aprovado:
        return '✅';
      case StatusRelatorio.devolvido:
        return '❌';
    }
  }
}
