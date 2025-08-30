import 'package:cloud_firestore/cloud_firestore.dart';

class Contrato {
  final String id;
  final String nome;
  final double valorPorKm; // Valor pago por quilômetro rodado
  final String? regionalId; // ID da regional associada
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;
  final bool ativo; // Para controlar se o contrato está ativo

  const Contrato({
    required this.id,
    required this.nome,
    required this.valorPorKm,
    this.regionalId,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.ativo = true,
  });

  // Construtor para criar um novo contrato (sem ID)
  Contrato.novo({
    required this.nome,
    required this.valorPorKm,
    this.regionalId,
    this.ativo = true,
  }) : id = '',
       dataCriacao = DateTime.now(),
       dataAtualizacao = null;

  // Converter de Map (Firestore)
  factory Contrato.fromMap(Map<String, dynamic> map, String id) {
    return Contrato(
      id: id,
      nome: map['nome'] ?? '',
      valorPorKm: (map['valorPorKm'] ?? 0.0).toDouble(),
      regionalId: map['regionalId'],
      dataCriacao:
          (map['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataAtualizacao: (map['dataAtualizacao'] as Timestamp?)?.toDate(),
      ativo: map['ativo'] ?? true,
    );
  }

  // Converter para Map (Firestore)
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'valorPorKm': valorPorKm,
      'regionalId': regionalId,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
      'dataAtualizacao': dataAtualizacao != null
          ? Timestamp.fromDate(dataAtualizacao!)
          : null,
      'ativo': ativo,
    };
  }

  // Métodos auxiliares
  Contrato copyWith({
    String? id,
    String? nome,
    double? valorPorKm,
    String? regionalId,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
    bool? ativo,
  }) {
    return Contrato(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valorPorKm: valorPorKm ?? this.valorPorKm,
      regionalId: regionalId ?? this.regionalId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() {
    return 'Contrato(id: $id, nome: $nome, valorPorKm: $valorPorKm, regionalId: $regionalId, ativo: $ativo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contrato && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
