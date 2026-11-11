import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/domain/momento_liturgico.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/song_id.dart';
import '../domain/song_model.dart';
import '../domain/song_parser.dart';

/// Stream of songs for the currently selected group (from local DB)
final selectedGrupoIdProvider = StateProvider<String?>((ref) => null);

final musicasByGrupoProvider = StreamProvider.family<List<SongModel>, String>((
  ref,
  grupoId,
) {
  final db = ref.watch(databaseProvider);
  return db
      .watchMusicasByGrupo(grupoId)
      .map(
        (rows) =>
            rows
                .map(
                  (r) => SongModel(
                    id: r.id,
                    grupoId: r.grupoId,
                    titulo: r.titulo,
                    tomOriginal: r.tomOriginal,
                    bpm: r.bpm,
                    categorias: List<String>.from(
                      jsonDecode(r.categorias) as List,
                    ),
                    momentosLiturgicos: _decodeMomentos(r.momentosLiturgicos),
                    conteudoRaw: r.conteudoRaw,
                    conteudoJson: SongContent.fromJson(
                      jsonDecode(r.conteudoJson) as Map<String, dynamic>,
                    ),
                    updatedAt: r.updatedAt,
                  ),
                )
                .toList(),
      );
});

final musicasSyncAtProvider = StreamProvider.family<DateTime?, String>((
  ref,
  grupoId,
) {
  return ref.watch(databaseProvider).watchMusicasSyncAt(grupoId);
});

class SongEditResult {
  final String? syncWarning;

  const SongEditResult({this.syncWarning});

  bool get isSynced => syncWarning == null;
}

/// Service for song CRUD, import and sync
class SongsService {
  final Ref _ref;
  SongsService(this._ref);

  AppDatabase get _db => _ref.read(databaseProvider);
  dynamic get _supabase => _ref.read(supabaseProvider);
  String? get _userId => _ref.read(currentUserIdProvider);

  /// Import a song from a .txt file picked by the user.
  /// Returns the song title on success, throws on error.
  Future<String> importFromFile({required String grupoId}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw const SongParseException('Nenhum arquivo selecionado.');
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      throw const SongParseException('Não foi possível ler o arquivo.');
    }

    final raw = utf8.decode(bytes);
    final content = SongParser.parse(raw);

    final id = SongId.generate();
    await _db.upsertMusica(
      MusicasLocalCompanion.insert(
        id: id,
        grupoId: grupoId,
        titulo: content.titulo,
        tomOriginal: drift.Value(content.tomOriginal),
        bpm: drift.Value(content.bpm),
        categorias: drift.Value(jsonEncode(content.categorias)),
        momentosLiturgicos: drift.Value(
          jsonEncode(
            content.momentosLiturgicos.map((moment) => moment.name).toList(),
          ),
        ),
        conteudoRaw: raw,
        conteudoJson: jsonEncode(content.toJson()),
        updatedAt: DateTime.now(),
      ),
    );

    return content.titulo;
  }

  /// Save edited song text locally and update its published copy when possible.
  Future<SongEditResult> updateMusica({
    required String musicaId,
    required String conteudoRaw,
  }) async {
    final local = await _db.getMusica(musicaId);
    if (local == null) {
      throw StateError('Música não encontrada no banco local.');
    }

    final content = SongParser.parse(conteudoRaw);
    final updatedAt = DateTime.now();
    await _db.upsertMusica(
      MusicasLocalCompanion.insert(
        id: local.id,
        grupoId: local.grupoId,
        titulo: content.titulo,
        tomOriginal: drift.Value(content.tomOriginal),
        bpm: drift.Value(content.bpm),
        categorias: drift.Value(jsonEncode(content.categorias)),
        momentosLiturgicos: drift.Value(
          jsonEncode(
            content.momentosLiturgicos.map((moment) => moment.name).toList(),
          ),
        ),
        conteudoRaw: conteudoRaw,
        conteudoJson: jsonEncode(content.toJson()),
        updatedAt: updatedAt,
      ),
    );

    if (!SongId.isUuid(local.id)) {
      return const SongEditResult(
        syncWarning: 'A música precisa ser publicada no grupo.',
      );
    }

    try {
      final updated =
          await _supabase
                  .from('musicas')
                  .update({
                    'titulo': content.titulo,
                    'tom_original': content.tomOriginal,
                    'bpm': content.bpm,
                    'categorias': content.categorias,
                    'momentos_liturgicos':
                        content.momentosLiturgicos
                            .map((moment) => moment.name)
                            .toList(),
                    'conteudo_raw': conteudoRaw,
                    'conteudo_json': content.toJson(),
                    'updated_at': updatedAt.toUtc().toIso8601String(),
                  })
                  .eq('id', local.id)
                  .eq('grupo_id', local.grupoId)
                  .select('id')
                  .maybeSingle()
              as Map<String, dynamic>?;

      if (updated == null) {
        return const SongEditResult(
          syncWarning:
              'Alteração salva neste dispositivo, mas a música ainda não '
              'foi publicada ou você não tem permissão para editá-la.',
        );
      }
      return const SongEditResult();
    } catch (error) {
      return SongEditResult(
        syncWarning:
            'Alteração salva neste dispositivo, mas não foi sincronizada. '
            'Verifique sua conexão e publique as músicas do grupo. Detalhe: '
            '$error',
      );
    }
  }

  /// Delete a song from local DB
  Future<void> deleteMusica(String id) => _db.deleteMusica(id);

  Future<void> updateMomentosLiturgicos(
    String musicaId,
    List<MomentoLiturgico> momentos,
  ) async {
    final remote =
        await _supabase
                .from('musicas')
                .select('id')
                .eq('id', musicaId)
                .maybeSingle()
            as Map<String, dynamic>?;

    if (remote != null) {
      await _supabase
          .from('musicas')
          .update({
            'momentos_liturgicos':
                momentos.map((moment) => moment.name).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', musicaId);
    }

    await _db.updateMusicaMomentos(
      musicaId,
      jsonEncode(momentos.map((moment) => moment.name).toList()),
    );
  }

  /// Publish all local songs of a group to Supabase (Coordenador only)
  Future<int> publishMusicas(String grupoId) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuário não autenticado');

    final musicas = await _db.getMusicasByGrupo(grupoId);
    int count = 0;
    for (final m in musicas) {
      await _publishMusica(m, userId);
      count++;
    }
    await _db.updateMusicasSyncAt(grupoId, DateTime.now());
    return count;
  }

  /// Ensure a song selected for a celebration exists remotely before its FK
  /// is written. Local-only songs are published by the group coordinator.
  Future<void> ensureMusicaPublished({
    required String grupoId,
    required String musicaId,
  }) async {
    final song = await _db.getMusica(musicaId);
    if (song != null && song.grupoId != grupoId) {
      throw StateError(
        'A música selecionada não pertence ao hinário deste grupo.',
      );
    }

    if (SongId.isUuid(musicaId)) {
      final remote =
          await _supabase
                  .from('musicas')
                  .select('id')
                  .eq('id', musicaId)
                  .eq('grupo_id', grupoId)
                  .maybeSingle()
              as Map<String, dynamic>?;
      if (remote != null) return;
    }

    if (song == null) {
      throw StateError(
        'A música selecionada não foi encontrada no hinário local nem no '
        'Supabase. Sincronize o hinário e selecione a música novamente.',
      );
    }

    final userId = _userId;
    if (userId == null) throw Exception('Usuário não autenticado');
    try {
      await _publishMusica(song, userId);
    } catch (error) {
      throw StateError(
        'A música "${song.titulo}" ainda não foi publicada no grupo. '
        'Conecte-se como coordenador e publique o hinário antes de '
        'sincronizar a celebração. Detalhe: $error',
      );
    }
  }

  Future<void> _publishMusica(MusicasLocalData song, String userId) async {
    final musicaId = SongId.isUuid(song.id) ? song.id : SongId.generate();
    if (musicaId != song.id) {
      await _db.updateMusicaId(song.id, musicaId);
    }
    await _supabase.from('musicas').upsert({
      'id': musicaId,
      'grupo_id': song.grupoId,
      'titulo': song.titulo,
      'tom_original': song.tomOriginal,
      'bpm': song.bpm,
      'categorias': jsonDecode(song.categorias),
      'momentos_liturgicos':
          _decodeMomentos(
            song.momentosLiturgicos,
          ).map((moment) => moment.name).toList(),
      'conteudo_raw': song.conteudoRaw,
      'conteudo_json': jsonDecode(song.conteudoJson),
      'criado_por': userId,
      'updated_at': song.updatedAt.toIso8601String(),
    });
  }

  /// Download all songs for a group from Supabase to local DB
  Future<int> syncMusicas(String grupoId) async {
    final rows =
        await _supabase.from('musicas').select().eq('grupo_id', grupoId)
            as List<dynamic>;

    await _db.transaction(() async {
      for (final row in rows) {
        final m = row as Map<String, dynamic>;
        await _db.upsertMusica(
          MusicasLocalCompanion.insert(
            id: m['id'] as String,
            grupoId: m['grupo_id'] as String,
            titulo: m['titulo'] as String,
            tomOriginal: drift.Value(m['tom_original'] as String?),
            bpm: drift.Value(m['bpm'] as int?),
            categorias: drift.Value(jsonEncode(m['categorias'] ?? [])),
            momentosLiturgicos: drift.Value(
              jsonEncode(m['momentos_liturgicos'] ?? []),
            ),
            conteudoRaw: m['conteudo_raw'] as String,
            conteudoJson: jsonEncode(m['conteudo_json']),
            updatedAt:
                DateTime.tryParse(m['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
      }
      await _db.updateMusicasSyncAt(grupoId, DateTime.now());
    });
    return rows.length;
  }

  /// List songs published by other groups that can be copied into this group.
  Future<List<SongModel>> getCatalogoMusicas(String grupoId) async {
    final rows =
        await _supabase
                .from('musicas')
                .select()
                .neq('grupo_id', grupoId)
                .order('titulo')
            as List<dynamic>;

    return rows
        .map((row) => SongModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Copy a catalog song into the target group's independent library.
  Future<String> copiarMusicaDoCatalogo({
    required String grupoId,
    required String musicaId,
  }) async {
    final copiedId =
        await _supabase.rpc(
              'copy_song_to_group',
              params: {'p_musica_id': musicaId, 'p_grupo_id': grupoId},
            )
            as String;
    await syncMusicas(grupoId);
    return copiedId;
  }

  /// Copy every song in the shared catalog, then sync the local library once.
  Future<int> copiarTodasMusicasDoCatalogo({
    required String grupoId,
    required List<SongModel> musicas,
  }) async {
    var copiedCount = 0;
    Object? copyError;

    for (final musica in musicas) {
      try {
        await _supabase.rpc(
          'copy_song_to_group',
          params: {'p_musica_id': musica.id, 'p_grupo_id': grupoId},
        );
        copiedCount++;
      } catch (error) {
        copyError = error;
        break;
      }
    }

    try {
      await syncMusicas(grupoId);
    } catch (syncError) {
      if (copyError != null) {
        throw StateError(
          'Falha ao adicionar músicas após $copiedCount de '
          '${musicas.length} tentativas ($copyError). '
          'Também não foi possível sincronizar o hinário: $syncError',
        );
      }
      rethrow;
    }

    if (copyError != null) {
      throw StateError(
        'Falha ao adicionar músicas após $copiedCount de '
        '${musicas.length} tentativas: $copyError',
      );
    }
    return copiedCount;
  }
}

final songsServiceProvider = Provider<SongsService>((ref) => SongsService(ref));

List<MomentoLiturgico> _decodeMomentos(String json) {
  final values = jsonDecode(json);
  if (values is! List) return const [];
  return values
      .whereType<String>()
      .map(MomentoLiturgico.fromTag)
      .whereType<MomentoLiturgico>()
      .toList();
}
