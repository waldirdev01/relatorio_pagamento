class Regional {
  final String id;
  final String descricao;
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;

  Regional({
    required this.id,
    required this.descricao,
    required this.dataCriacao,
    this.dataAtualizacao,
  });

  // Construtor para criar Regional a partir do Firestore
  factory Regional.fromFirestore(Map<String, dynamic> data, String id) {
    return Regional(
      id: id,
      descricao: data['descricao'] ?? '',
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(data['dataCriacao']),
      dataAtualizacao: data['dataAtualizacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['dataAtualizacao'])
          : null,
    );
  }

  // Método para converter Regional para Map (Firestore)
  Map<String, dynamic> toFirestore() {
    return {
      'descricao': descricao,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao?.millisecondsSinceEpoch,
    };
  }

  // Método para criar uma cópia com alterações
  Regional copyWith({
    String? id,
    String? descricao,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return Regional(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

  @override
  String toString() {
    return 'Regional(id: $id, descricao: $descricao, dataCriacao: $dataCriacao)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Regional && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
