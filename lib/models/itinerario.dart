import 'turno.dart';

class Itinerario {
  final String id;
  final String regionalId;
  final String? contratoId; // ID do contrato associado

  // Informações básicas
  final String itinerario;
  final TipoTurno turno;
  final List<String> escolaIds;
  final String trajeto;

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
  final bool isCopia; // Indica se este itinerário é uma cópia
  final String?
  itinerarioOriginalId; // ID do itinerário original (se for cópia)

  Itinerario({
    required this.id,
    required this.regionalId,
    this.contratoId,
    required this.itinerario,
    required this.turno,
    required this.escolaIds,
    required this.trajeto,
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
    this.isCopia = false,
    this.itinerarioOriginalId,
  });

  // Construtor para criar Itinerário a partir do Firestore
  factory Itinerario.fromFirestore(Map<String, dynamic> data, String id) {
    return Itinerario(
      id: id,
      regionalId: data['regionalId'] ?? '',
      contratoId: data['contratoId'],
      itinerario: data['itinerario'] ?? '',
      turno: TipoTurno.values.firstWhere(
        (e) => e.name == data['turno'],
        orElse: () => TipoTurno.matutino,
      ),
      escolaIds: List<String>.from(data['escolaIds'] ?? []),
      trajeto: data['trajeto'] ?? '',
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
      isCopia: data['isCopia'] ?? false,
      itinerarioOriginalId: data['itinerarioOriginalId'],
    );
  }

  // Método para converter Itinerário para Map (Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'regionalId': regionalId,
      'contratoId': contratoId,
      'itinerario': itinerario,
      'turno': turno.name,
      'escolaIds': escolaIds,
      'trajeto': trajeto,
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
      'isCopia': isCopia,
      if (dataAtualizacao != null)
        'dataAtualizacao': dataAtualizacao!.millisecondsSinceEpoch,
      if (itinerarioOriginalId != null)
        'itinerarioOriginalId': itinerarioOriginalId,
      if (ei != null) 'ei': ei,
      if (ef != null) 'ef': ef,
      if (em != null) 'em': em,
      if (ee != null) 'ee': ee,
      if (eja != null) 'eja': eja,
    };
  }

  // Método para criar uma cópia com alterações
  Itinerario copyWith({
    String? id,
    String? regionalId,
    String? contratoId,
    String? itinerario,
    TipoTurno? turno,
    List<String>? escolaIds,
    String? trajeto,
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
    bool? isCopia,
    String? itinerarioOriginalId,
  }) {
    return Itinerario(
      id: id ?? this.id,
      regionalId: regionalId ?? this.regionalId,
      contratoId: contratoId ?? this.contratoId,
      itinerario: itinerario ?? this.itinerario,
      turno: turno ?? this.turno,
      escolaIds: escolaIds ?? this.escolaIds,
      trajeto: trajeto ?? this.trajeto,
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
      isCopia: isCopia ?? this.isCopia,
      itinerarioOriginalId: itinerarioOriginalId ?? this.itinerarioOriginalId,
    );
  }

  // Método para calcular totais automaticamente
  Itinerario calcularTotais() {
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
    return 'Itinerario(id: $id, itinerario: $itinerario, escolaIds: $escolaIds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Itinerario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
