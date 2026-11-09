import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../songs/domain/song_id.dart';
import '../domain/celebration_model.dart';

final celebracoesByGrupoProvider =
    StreamProvider.family<List<CelebracoesLocalData>, String>((ref, grupoId) {
      return ref.watch(databaseProvider).watchCelebracoesByGrupo(grupoId);
    });

final itensByCelebracaoProvider =
    StreamProvider.family<List<ItensCelebracaoLocalData>, String>((
      ref,
      celebracaoId,
    ) {
      return ref.watch(databaseProvider).watchItensByCelebracao(celebracaoId);
    });

class CelebracoesService {
  final Ref _ref;

  CelebracoesService(this._ref);

  AppDatabase get _db => _ref.read(databaseProvider);
  dynamic get _supabase => _ref.read(supabaseProvider);

  /// Create a celebration with the default Roman Rite moments.
  Future<String> createCelebracao({
    required String grupoId,
    required String titulo,
    required DateTime dataHora,
  }) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Usuário não autenticado');

    final celebracaoId = SongId.generate();
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.upsertCelebracao(
        CelebracoesLocalCompanion.insert(
          id: celebracaoId,
          grupoId: grupoId,
          titulo: titulo.trim(),
          dataHora: dataHora,
          criadoPor: userId,
          updatedAt: now,
          isSynced: const drift.Value(false),
        ),
      );
      for (final item in defaultRitoRomano(celebracaoId)) {
        await _db.upsertItemCelebracao(
          ItensCelebracaoLocalCompanion.insert(
            id: SongId.generate(),
            celebracaoId: celebracaoId,
            musicaId: drift.Value(item.musicaId),
            ordem: item.ordem,
            momentoLiturgico: item.momentoLiturgico.name,
            observacao: drift.Value(item.observacao),
            isSynced: const drift.Value(false),
          ),
        );
      }
    });
    return celebracaoId;
  }

  /// Push local edits, then download the group's current data for offline use.
  Future<int> syncCelebracoes(String grupoId) async {
    final localCelebrations = await _db.getCelebracoesByGrupo(grupoId);
    for (final celebration in localCelebrations.where((row) => !row.isSynced)) {
      await _supabase.from('celebracoes').upsert({
        'id': celebration.id,
        'grupo_id': celebration.grupoId,
        'titulo': celebration.titulo,
        'data_hora': celebration.dataHora.toUtc().toIso8601String(),
        'criado_por': celebration.criadoPor,
        'updated_at': celebration.updatedAt.toUtc().toIso8601String(),
      });
      await _db.markCelebracaoSynced(celebration.id);
    }

    for (final celebration in localCelebrations) {
      final localItems = await _db.getItensByCelebracao(celebration.id);
      for (final item in localItems.where((row) => !row.isSynced)) {
        await _supabase.from('itens_celebracao').upsert({
          'id': item.id,
          'celebracao_id': item.celebracaoId,
          'musica_id': item.musicaId,
          'ordem': item.ordem,
          'momento_liturgico': item.momentoLiturgico,
          'observacao': item.observacao,
        });
        await _db.markItemCelebracaoSynced(item.id);
      }
    }

    final celebrations =
        await _supabase
                .from('celebracoes')
                .select()
                .eq('grupo_id', grupoId)
                .order('data_hora')
            as List<dynamic>;

    final celebrationIds =
        celebrations
            .map((row) => (row as Map<String, dynamic>)['id'] as String)
            .toList();
    final items =
        celebrationIds.isEmpty
            ? <dynamic>[]
            : await _supabase
                    .from('itens_celebracao')
                    .select()
                    .inFilter('celebracao_id', celebrationIds)
                as List<dynamic>;

    final remoteIds = celebrationIds.toSet();
    await _db.transaction(() async {
      for (final local in await _db.getCelebracoesByGrupo(grupoId)) {
        if (!remoteIds.contains(local.id)) {
          await _db.deleteItensByCelebracao(local.id);
          await _db.deleteCelebracao(local.id);
        }
      }

      for (final row in celebrations) {
        final celebration = row as Map<String, dynamic>;
        await _db.upsertCelebracao(
          CelebracoesLocalCompanion.insert(
            id: celebration['id'] as String,
            grupoId: celebration['grupo_id'] as String,
            titulo: celebration['titulo'] as String,
            dataHora:
                DateTime.parse(celebration['data_hora'] as String).toLocal(),
            criadoPor: celebration['criado_por'] as String,
            updatedAt:
                DateTime.tryParse(celebration['updated_at'] as String? ?? '') ??
                DateTime.now(),
            isSynced: const drift.Value(true),
          ),
        );
        await _db.deleteItensByCelebracao(celebration['id'] as String);
      }

      for (final row in items) {
        await _saveItem(row as Map<String, dynamic>);
      }
    });

    return celebrations.length;
  }

  Future<void> updateCelebracao({
    required String id,
    required String titulo,
    required DateTime dataHora,
  }) async {
    final local = await _db.getCelebracao(id);
    if (local == null) {
      throw StateError('Celebração não encontrada no banco local.');
    }

    await _db.upsertCelebracao(
      CelebracoesLocalCompanion.insert(
        id: local.id,
        grupoId: local.grupoId,
        titulo: titulo.trim(),
        dataHora: dataHora,
        criadoPor: local.criadoPor,
        updatedAt: DateTime.now(),
        isSynced: const drift.Value(false),
      ),
    );
  }

  Future<void> updateItem({
    required String celebracaoId,
    required String itemId,
    required String? musicaId,
    required String? observacao,
  }) async {
    final localItems = await _db.getItensByCelebracao(celebracaoId);
    final item = localItems.where((row) => row.id == itemId).firstOrNull;
    if (item == null) {
      throw StateError('Item da celebração não encontrado no banco local.');
    }

    await _db.upsertItemCelebracao(
      ItensCelebracaoLocalCompanion.insert(
        id: item.id,
        celebracaoId: item.celebracaoId,
        musicaId: drift.Value(musicaId),
        ordem: item.ordem,
        momentoLiturgico: item.momentoLiturgico,
        observacao: drift.Value(
          observacao?.trim().isEmpty == true ? null : observacao?.trim(),
        ),
        isSynced: const drift.Value(false),
      ),
    );
  }

  Future<void> _saveItem(Map<String, dynamic> item) async {
    await _db.upsertItemCelebracao(
      ItensCelebracaoLocalCompanion.insert(
        id: item['id'] as String,
        celebracaoId: item['celebracao_id'] as String,
        musicaId: drift.Value(item['musica_id'] as String?),
        ordem: item['ordem'] as int,
        momentoLiturgico: item['momento_liturgico'] as String,
        observacao: drift.Value(item['observacao'] as String?),
        isSynced: const drift.Value(true),
      ),
    );
  }
}

final celebracoesServiceProvider = Provider<CelebracoesService>(
  (ref) => CelebracoesService(ref),
);
