import 'dart:convert';

/// Domain model for a song (música) with parsed chord+lyric structure.
class SongModel {
  final String id;
  final String grupoId;
  final String titulo;
  final String? tomOriginal;
  final int? bpm;
  final List<String> categorias;
  final String conteudoRaw;
  final SongContent conteudoJson;
  final DateTime updatedAt;

  const SongModel({
    required this.id,
    required this.grupoId,
    required this.titulo,
    this.tomOriginal,
    this.bpm,
    required this.categorias,
    required this.conteudoRaw,
    required this.conteudoJson,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'grupo_id': grupoId,
        'titulo': titulo,
        'tom_original': tomOriginal,
        'bpm': bpm,
        'categorias': categorias,
        'conteudo_raw': conteudoRaw,
        'conteudo_json': conteudoJson.toJson(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
        id: json['id'] as String,
        grupoId: json['grupo_id'] as String,
        titulo: json['titulo'] as String,
        tomOriginal: json['tom_original'] as String?,
        bpm: json['bpm'] as int?,
        categorias: List<String>.from(json['categorias'] as List),
        conteudoRaw: json['conteudo_raw'] as String,
        conteudoJson: SongContent.fromJson(
            json['conteudo_json'] as Map<String, dynamic>),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  String get categoriasJsonString => jsonEncode(categorias);
  String get conteudoJsonString => jsonEncode(conteudoJson.toJson());
}

/// Parsed content of a song: sections with chord+lyric lines.
class SongContent {
  final String titulo;
  final String? tomOriginal;
  final int? bpm;
  final List<String> categorias;
  final List<SongSection> secoes;

  const SongContent({
    required this.titulo,
    this.tomOriginal,
    this.bpm,
    required this.categorias,
    required this.secoes,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'tomOriginal': tomOriginal,
        'bpm': bpm,
        'categorias': categorias,
        'secoes': secoes.map((s) => s.toJson()).toList(),
      };

  factory SongContent.fromJson(Map<String, dynamic> json) => SongContent(
        titulo: json['titulo'] as String,
        tomOriginal: json['tomOriginal'] as String?,
        bpm: json['bpm'] as int?,
        categorias: List<String>.from(json['categorias'] as List? ?? []),
        secoes: (json['secoes'] as List)
            .map((s) => SongSection.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// A section of a song (ESTROFE, REFRAO, PONTE, etc.)
class SongSection {
  final String tipo;
  final List<SongLine> linhas;

  const SongSection({required this.tipo, required this.linhas});

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'linhas': linhas.map((l) => l.toJson()).toList(),
      };

  factory SongSection.fromJson(Map<String, dynamic> json) => SongSection(
        tipo: json['tipo'] as String,
        linhas: (json['linhas'] as List)
            .map((l) => SongLine.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}

/// A single line pairing: chord line above, lyric line below.
class SongLine {
  final String? cifra;
  final String letra;

  const SongLine({this.cifra, required this.letra});

  Map<String, dynamic> toJson() => {
        'cifra': cifra,
        'letra': letra,
      };

  factory SongLine.fromJson(Map<String, dynamic> json) => SongLine(
        cifra: json['cifra'] as String?,
        letra: json['letra'] as String,
      );
}
