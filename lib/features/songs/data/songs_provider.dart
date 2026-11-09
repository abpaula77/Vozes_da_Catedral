import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
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
        conteudoRaw: raw,
        conteudoJson: jsonEncode(content.toJson()),
        updatedAt: DateTime.now(),
      ),
    );

    return content.titulo;
  }

  /// Delete a song from local DB
  Future<void> deleteMusica(String id) => _db.deleteMusica(id);

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
}

final songsServiceProvider = Provider<SongsService>((ref) => SongsService(ref));
