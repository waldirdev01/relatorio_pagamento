enum TipoTurno { matutino, vespertino, noturno, integral }

extension TipoTurnoExtension on TipoTurno {
  String get descricao {
    switch (this) {
      case TipoTurno.matutino:
        return 'MATUTINO';
      case TipoTurno.vespertino:
        return 'VESPERTINO';
      case TipoTurno.noturno:
        return 'NOTURNO';
      case TipoTurno.integral:
        return 'INTEGRAL';
    }
  }

  String get descricaoCompleta {
    switch (this) {
      case TipoTurno.matutino:
        return 'Matutino (Manhã)';
      case TipoTurno.vespertino:
        return 'Vespertino (Tarde)';
      case TipoTurno.noturno:
        return 'Noturno (Noite)';
      case TipoTurno.integral:
        return 'Integral (Manhã e Tarde)';
    }
  }
}
