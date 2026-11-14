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

int _contagem(Object? value) => (value as num?)?.toInt() ?? 0;

/// What would be lost when deleting a group (#61).
class ResumoExclusao {
  final int membros;
  final int musicas;

  /// Songs that exist only in this group (no copy elsewhere, not an
  /// unchanged copy of another group's song).
  final int musicasExclusivas;
  final int celebracoes;
  final int solicitacoesPendentes;

  const ResumoExclusao({
    required this.membros,
    required this.musicas,
    required this.musicasExclusivas,
    required this.celebracoes,
    required this.solicitacoesPendentes,
  });

  /// Whether there is anything worth copying to another group.
  bool get temConteudoParaCopiar => musicasExclusivas > 0 || celebracoes > 0;

  factory ResumoExclusao.fromJson(Map<String, dynamic> json) => ResumoExclusao(
    membros: _contagem(json['membros']),
    musicas: _contagem(json['musicas']),
    musicasExclusivas: _contagem(json['musicas_exclusivas']),
    celebracoes: _contagem(json['celebracoes']),
    solicitacoesPendentes: _contagem(json['solicitacoes_pendentes']),
  );
}

/// Result of copying a group's exclusive content to another group (#61).
class CopiaConteudo {
  final int musicas;
  final int celebracoes;

  const CopiaConteudo({required this.musicas, required this.celebracoes});

  factory CopiaConteudo.fromJson(Map<String, dynamic> json) => CopiaConteudo(
    musicas: _contagem(json['musicas']),
    celebracoes: _contagem(json['celebracoes']),
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
