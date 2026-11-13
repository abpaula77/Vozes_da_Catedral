/// Domain models for group join requests (issue #41).
///
/// Data comes only from the Supabase RPCs described in
/// `.kiro/specs/pedido-filiacao-grupos/design.md`; nothing is cached locally.
library;

/// Status of a join request.
enum StatusSolicitacao {
  pendente('pendente'),
  aprovada('aprovada'),
  recusada('recusada'),
  cancelada('cancelada');

  final String value;
  const StatusSolicitacao(this.value);

  /// Returns null for a null or unknown value (e.g. "no request").
  static StatusSolicitacao? fromString(String? value) {
    if (value == null) return null;
    for (final status in StatusSolicitacao.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// Formats a date as DD/MM/AAAA in the device's local time zone.
String formatarData(DateTime data) {
  final local = data.toLocal();
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(local.day)}/${doisDigitos(local.month)}/${local.year}';
}

DateTime? _parseDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// A group open to join requests, as seen by a user who is not a member.
class GrupoAbertoModel {
  final String id;
  final String nome;
  final String? descricao;

  /// Status of the user's own request: pending, rejected (still within the
  /// 7-day wait) or null when the user may request.
  final StatusSolicitacao? meuStatus;

  /// End of the 7-day wait after a rejection, if any.
  final DateTime? podeSolicitarEm;

  const GrupoAbertoModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.meuStatus,
    this.podeSolicitarEm,
  });

  factory GrupoAbertoModel.fromJson(Map<String, dynamic> json) =>
      GrupoAbertoModel(
        id: json['id'] as String,
        nome: json['nome'] as String,
        descricao: json['descricao'] as String?,
        meuStatus: StatusSolicitacao.fromString(json['meu_status'] as String?),
        podeSolicitarEm: _parseDate(json['pode_solicitar_em']),
      );

  /// Whether the "Solicitar entrada" action should be enabled.
  bool podeSolicitar([DateTime? agora]) {
    if (meuStatus == StatusSolicitacao.pendente) return false;
    final fimEspera = podeSolicitarEm;
    if (fimEspera != null) {
      return !(agora ?? DateTime.now()).isBefore(fimEspera);
    }
    return true;
  }
}

/// One of the current user's own requests.
class MinhaSolicitacaoModel {
  final String id;
  final String grupoId;
  final String grupoNome;
  final StatusSolicitacao status;
  final String? mensagem;
  final DateTime criadaEm;
  final DateTime? podeSolicitarEm;

  const MinhaSolicitacaoModel({
    required this.id,
    required this.grupoId,
    required this.grupoNome,
    required this.status,
    this.mensagem,
    required this.criadaEm,
    this.podeSolicitarEm,
  });

  factory MinhaSolicitacaoModel.fromJson(Map<String, dynamic> json) =>
      MinhaSolicitacaoModel(
        id: json['id'] as String,
        grupoId: json['grupo_id'] as String,
        grupoNome: json['grupo_nome'] as String,
        status:
            StatusSolicitacao.fromString(json['status'] as String?) ??
            StatusSolicitacao.pendente,
        mensagem: json['mensagem'] as String?,
        criadaEm: DateTime.parse(json['criada_em'] as String),
        podeSolicitarEm: _parseDate(json['pode_solicitar_em']),
      );

  bool get podeCancelar => status == StatusSolicitacao.pendente;
}

/// A pending request, as seen by a coordinator of the group.
class SolicitacaoPendenteModel {
  final String id;
  final String userId;
  final String nome;

  /// Profile photo URL (from Google), when available.
  final String? foto;
  final String? mensagem;
  final DateTime criadaEm;

  const SolicitacaoPendenteModel({
    required this.id,
    required this.userId,
    required this.nome,
    this.foto,
    this.mensagem,
    required this.criadaEm,
  });

  factory SolicitacaoPendenteModel.fromJson(Map<String, dynamic> json) =>
      SolicitacaoPendenteModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        nome: json['nome'] as String,
        foto: _blankToNull(json['foto'] as String?),
        mensagem: _blankToNull(json['mensagem'] as String?),
        criadaEm: DateTime.parse(json['criada_em'] as String),
      );

  /// First letter of the name, used when there is no photo.
  String get inicial =>
      nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();
}

String? _blankToNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value;
