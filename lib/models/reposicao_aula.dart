class ReposicaoAula {
  final String id;
  final String itinerarioId; // ID do itinerário original
  final String regionalId;
  final String?
  grupoSolicitacaoId; // ID para agrupar reposições da mesma solicitação

  // Campos específicos da reposição
  final double km;
  final int numeroOnibus;
  final int diasTrabalhados;

  // Campos calculados automaticamente
  final double kmXNumeroOnibus;
  final double kmXNumeroOnibusXDias;

  // Metadados
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;
  final String? observacoes;

  // Datas específicas da reposição
  final DateTime? dataSolicitacao;
  final DateTime? dataReposicao;

  ReposicaoAula({
    required this.id,
    required this.itinerarioId,
    required this.regionalId,
    this.grupoSolicitacaoId,
    required this.km,
    required this.numeroOnibus,
    required this.diasTrabalhados,
    required this.kmXNumeroOnibus,
    required this.kmXNumeroOnibusXDias,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.observacoes,
    this.dataSolicitacao,
    this.dataReposicao,
  });

  // Construtor para criar Reposição a partir do Firestore
  factory ReposicaoAula.fromFirestore(Map<String, dynamic> data, String id) {
    return ReposicaoAula(
      id: id,
      itinerarioId: data['itinerarioId'] ?? '',
      regionalId: data['regionalId'] ?? '',
      grupoSolicitacaoId: data['grupoSolicitacaoId'] as String?,
      km: (data['km'] ?? 0).toDouble(),
      numeroOnibus: data['numeroOnibus'] ?? 0,
      diasTrabalhados: data['diasTrabalhados'] ?? 0,
      kmXNumeroOnibus: (data['kmXNumeroOnibus'] ?? 0).toDouble(),
      kmXNumeroOnibusXDias: (data['kmXNumeroOnibusXDias'] ?? 0).toDouble(),
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(
        data['dataCriacao'] ?? 0,
      ),
      dataAtualizacao: data['dataAtualizacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataAtualizacao'])
          : null,
      observacoes: data['observacoes'] as String?,
      dataSolicitacao: data['dataSolicitacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataSolicitacao'])
          : null,
      dataReposicao: data['dataReposicao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataReposicao'])
          : null,
    );
  }

  // Método para converter para Firestore
  Map<String, dynamic> toFirestore() {
    final map = {
      'itinerarioId': itinerarioId,
      'regionalId': regionalId,
      'km': km,
      'numeroOnibus': numeroOnibus,
      'diasTrabalhados': diasTrabalhados,
      'kmXNumeroOnibus': kmXNumeroOnibus,
      'kmXNumeroOnibusXDias': kmXNumeroOnibusXDias,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
    };

    // Adicionar campos opcionais apenas se não forem null
    if (grupoSolicitacaoId != null) {
      map['grupoSolicitacaoId'] = grupoSolicitacaoId as String;
    }
    if (dataAtualizacao != null) {
      map['dataAtualizacao'] = dataAtualizacao!.millisecondsSinceEpoch;
    }
    if (observacoes != null) {
      map['observacoes'] = observacoes as String;
    }
    if (dataSolicitacao != null) {
      map['dataSolicitacao'] = dataSolicitacao!.millisecondsSinceEpoch;
    }
    if (dataReposicao != null) {
      map['dataReposicao'] = dataReposicao!.millisecondsSinceEpoch;
    }

    return map;
  }

  // Método para criar cópia com alterações
  ReposicaoAula copyWith({
    String? id,
    String? itinerarioId,
    String? regionalId,
    String? grupoSolicitacaoId,
    double? km,
    int? numeroOnibus,
    int? diasTrabalhados,
    double? kmXNumeroOnibus,
    double? kmXNumeroOnibusXDias,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    String? observacoes,
    DateTime? dataSolicitacao,
    DateTime? dataReposicao,
  }) {
    return ReposicaoAula(
      id: id ?? this.id,
      itinerarioId: itinerarioId ?? this.itinerarioId,
      regionalId: regionalId ?? this.regionalId,
      grupoSolicitacaoId: grupoSolicitacaoId ?? this.grupoSolicitacaoId,
      km: km ?? this.km,
      numeroOnibus: numeroOnibus ?? this.numeroOnibus,
      diasTrabalhados: diasTrabalhados ?? this.diasTrabalhados,
      kmXNumeroOnibus: kmXNumeroOnibus ?? this.kmXNumeroOnibus,
      kmXNumeroOnibusXDias: kmXNumeroOnibusXDias ?? this.kmXNumeroOnibusXDias,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      observacoes: observacoes ?? this.observacoes,
      dataSolicitacao: dataSolicitacao ?? this.dataSolicitacao,
      dataReposicao: dataReposicao ?? this.dataReposicao,
    );
  }

  // Método para calcular os valores automaticamente
  static ReposicaoAula calcularValores({
    required String id,
    required String itinerarioId,
    required String regionalId,
    String? grupoSolicitacaoId,
    required double km,
    required int numeroOnibus,
    required int diasTrabalhados,
    required DateTime dataCriacao,
    DateTime? dataAtualizacao,
    String? observacoes,
    DateTime? dataSolicitacao,
    DateTime? dataReposicao,
  }) {
    final kmXNumeroOnibus = km * numeroOnibus;
    final kmXNumeroOnibusXDias = kmXNumeroOnibus * diasTrabalhados;

    return ReposicaoAula(
      id: id,
      itinerarioId: itinerarioId,
      regionalId: regionalId,
      grupoSolicitacaoId: grupoSolicitacaoId,
      km: km,
      numeroOnibus: numeroOnibus,
      diasTrabalhados: diasTrabalhados,
      kmXNumeroOnibus: kmXNumeroOnibus,
      kmXNumeroOnibusXDias: kmXNumeroOnibusXDias,
      dataCriacao: dataCriacao,
      dataAtualizacao: dataAtualizacao,
      observacoes: observacoes,
      dataSolicitacao: dataSolicitacao,
      dataReposicao: dataReposicao,
    );
  }

  // Métodos para trabalhar com grupos de solicitação

  /// Verifica se esta reposição faz parte de um grupo
  bool get fazParteDeGrupo => grupoSolicitacaoId != null;

  /// Gera um ID único para agrupar várias reposições da mesma solicitação
  static String gerarGrupoSolicitacaoId() {
    return 'grupo_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }

  /// Agrupa uma lista de reposições por grupo de solicitação
  static Map<String?, List<ReposicaoAula>> agruparPorSolicitacao(
    List<ReposicaoAula> reposicoes,
  ) {
    final Map<String?, List<ReposicaoAula>> grupos = {};

    for (final reposicao in reposicoes) {
      final key =
          reposicao.grupoSolicitacaoId ??
          reposicao.id; // Use ID individual se não tiver grupo
      grupos.putIfAbsent(key, () => []).add(reposicao);
    }

    return grupos;
  }

  /// Obtém o resumo de um grupo de reposições
  static String obterResumoGrupo(List<ReposicaoAula> grupo) {
    if (grupo.isEmpty) return 'Grupo vazio';
    if (grupo.length == 1) return 'Reposição individual';

    final primeira = grupo.first;
    return 'Grupo de ${grupo.length} reposições - Solicitação: ${primeira.dataSolicitacao != null ? _formatarData(primeira.dataSolicitacao!) : "N/A"}';
  }

  /// Formata data para exibição
  static String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
