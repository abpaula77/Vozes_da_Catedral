/// User roles within a group.
enum PapelGrupo {
  coordenador('coordenador'),
  membro('membro');

  final String value;
  const PapelGrupo(this.value);

  static PapelGrupo fromString(String value) {
    return PapelGrupo.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PapelGrupo.membro,
    );
  }

  bool get isCoordenador => this == PapelGrupo.coordenador;
}

/// Domain model for a group (coral / ministério).
class GrupoModel {
  final String id;
  final String nome;
  final String? descricao;
  final String criadoPor;
  final PapelGrupo meuPapel;
  final DateTime updatedAt;

  const GrupoModel({
    required this.id,
    required this.nome,
    this.descricao,
    required this.criadoPor,
    required this.meuPapel,
    required this.updatedAt,
  });

  bool get isCoordenador => meuPapel.isCoordenador;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
    'criado_por': criadoPor,
    'updated_at': updatedAt.toIso8601String(),
  };

  factory GrupoModel.fromJson(
    Map<String, dynamic> json, {
    required String meuPapelStr,
  }) => GrupoModel(
    id: json['id'] as String,
    nome: json['nome'] as String,
    descricao: json['descricao'] as String?,
    criadoPor: json['criado_por'] as String,
    meuPapel: PapelGrupo.fromString(meuPapelStr),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

/// A member's role and profile within a group.
class MembroGrupoModel {
  final String userId;
  final String nome;
  final PapelGrupo papel;

  /// Raw `users.foto` value (Google URL or `avatars/...` path), issue #42.
  final String? foto;

  const MembroGrupoModel({
    required this.userId,
    required this.nome,
    required this.papel,
    this.foto,
  });
}
