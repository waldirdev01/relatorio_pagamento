enum ClassificacaoEscola {
  rural('Rural'),
  urbana('Urbana');

  const ClassificacaoEscola(this.descricao);
  final String descricao;
}

class Escola {
  final String id;
  final String nome;
  final ClassificacaoEscola classificacao;
  final String regionalId;
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;

  Escola({
    required this.id,
    required this.nome,
    required this.classificacao,
    required this.regionalId,
    required this.dataCriacao,
    this.dataAtualizacao,
  });

  // Construtor para criar Escola a partir do Firestore
  factory Escola.fromFirestore(Map<String, dynamic> data, String id) {
    return Escola(
      id: id,
      nome: data['nome'] ?? '',
      classificacao: ClassificacaoEscola.values.firstWhere(
        (c) => c.name == data['classificacao'],
        orElse: () => ClassificacaoEscola.urbana,
      ),
      regionalId: data['regionalId'] ?? '',
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(
        data['dataCriacao'] ?? 0,
      ),
      dataAtualizacao: data['dataAtualizacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataAtualizacao'])
          : null,
    );
  }

  // Método para converter para Firestore
  Map<String, dynamic> toFirestore() {
    final map = {
      'nome': nome,
      'classificacao': classificacao.name,
      'regionalId': regionalId,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
    };

    if (dataAtualizacao != null) {
      map['dataAtualizacao'] = dataAtualizacao!.millisecondsSinceEpoch;
    }

    return map;
  }

  // Método para criar cópia com alterações
  Escola copyWith({
    String? id,
    String? nome,
    ClassificacaoEscola? classificacao,
    String? regionalId,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return Escola(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      classificacao: classificacao ?? this.classificacao,
      regionalId: regionalId ?? this.regionalId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

  @override
  String toString() {
    return '$nome (${classificacao.descricao})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Escola && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
