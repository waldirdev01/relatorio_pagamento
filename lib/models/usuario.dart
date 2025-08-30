enum TipoUsuario { gcote, chefeUniae, administrativoUniae }

enum StatusAprovacao { aguardando, aprovado, rejeitado }

class Usuario {
  final String id;
  final String nome;
  final String matricula;
  final String telefone;
  final String email;
  final String? senha; // Só para cadastro, não armazenar no Firestore
  final TipoUsuario tipoUsuario;
  final String? regionalId;
  final StatusAprovacao statusAprovacao;
  final bool ativo;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;

  const Usuario({
    required this.id,
    required this.nome,
    required this.matricula,
    required this.telefone,
    required this.email,
    this.senha,
    required this.tipoUsuario,
    this.regionalId,
    required this.statusAprovacao,
    required this.ativo,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      matricula: map['matricula'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      tipoUsuario: TipoUsuario.values.firstWhere(
        (e) => e.name == map['tipoUsuario'],
        orElse: () => TipoUsuario.administrativoUniae,
      ),
      regionalId: map['regionalId'],
      statusAprovacao: StatusAprovacao.values.firstWhere(
        (e) => e.name == map['statusAprovacao'],
        orElse: () => StatusAprovacao.aguardando,
      ),
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
      'matricula': matricula,
      'telefone': telefone,
      'email': email,
      'tipoUsuario': tipoUsuario.name,
      'regionalId': regionalId,
      'statusAprovacao': statusAprovacao.name,
      'ativo': ativo,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'dataAtualizacao': dataAtualizacao.millisecondsSinceEpoch,
    };
  }

  Usuario copyWith({
    String? id,
    String? nome,
    String? matricula,
    String? telefone,
    String? email,
    String? senha,
    TipoUsuario? tipoUsuario,
    String? regionalId,
    StatusAprovacao? statusAprovacao,
    bool? ativo,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      matricula: matricula ?? this.matricula,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      regionalId: regionalId ?? this.regionalId,
      statusAprovacao: statusAprovacao ?? this.statusAprovacao,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

  String get tipoUsuarioLabel {
    switch (tipoUsuario) {
      case TipoUsuario.gcote:
        return 'GCOTE';
      case TipoUsuario.chefeUniae:
        return 'Chefe UNIAE';
      case TipoUsuario.administrativoUniae:
        return 'Administrativo UNIAE';
    }
  }

  String get statusAprovacaoLabel {
    switch (statusAprovacao) {
      case StatusAprovacao.aguardando:
        return 'Aguardando Aprovação';
      case StatusAprovacao.aprovado:
        return 'Aprovado';
      case StatusAprovacao.rejeitado:
        return 'Rejeitado';
    }
  }

  String get statusAprovacaoIcon {
    switch (statusAprovacao) {
      case StatusAprovacao.aguardando:
        return '⏳';
      case StatusAprovacao.aprovado:
        return '✅';
      case StatusAprovacao.rejeitado:
        return '❌';
    }
  }
}
