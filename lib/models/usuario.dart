class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? regionalId;
  final bool ativo;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.regionalId,
    required this.ativo,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      regionalId: map['regionalId'],
      ativo: map['ativo'] ?? true,
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['dataCriacao'] ?? 0),
      dataAtualizacao: DateTime.fromMillisecondsSinceEpoch(
        map['dataAtualizacao'] ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'regionalId': regionalId,
      'ativo': ativo,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao.millisecondsSinceEpoch,
    };
  }

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? regionalId,
    bool? ativo,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      regionalId: regionalId ?? this.regionalId,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
