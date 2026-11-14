import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UsersLocal,
    GruposLocal,
    MusicasLocal,
    SyncStatusLocal,
    CelebracoesLocal,
    ItensCelebracaoLocal,
    AppMetaLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory or custom database, for tests.
  AppDatabase.forTesting(super.executor);

  /// Metadata key holding the id of the account that owns the local cache.
  static const chaveDonoCache = 'dono_cache';

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(syncStatusLocal);
      if (from < 3) {
        await migrator.addColumn(celebracoesLocal, celebracoesLocal.isSynced);
        await migrator.addColumn(
          itensCelebracaoLocal,
          itensCelebracaoLocal.isSynced,
        );
      }
      if (from < 4) {
        await migrator.addColumn(musicasLocal, musicasLocal.momentosLiturgicos);
      }
      if (from < 5) await migrator.createTable(appMetaLocal);
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'vozes_da_catedral_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<UsersLocalData?> getUser(String id) =>
      (select(usersLocal)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertUser(UsersLocalCompanion user) =>
      into(usersLocal).insertOnConflictUpdate(user);

  // ── Groups ─────────────────────────────────────────────────────────────────

  Stream<List<GruposLocalData>> watchGrupos() => select(gruposLocal).watch();

  Future<List<GruposLocalData>> getGrupos() => select(gruposLocal).get();

  Future<void> upsertGrupo(GruposLocalCompanion grupo) =>
      into(gruposLocal).insertOnConflictUpdate(grupo);

  Future<void> deleteGrupo(String id) =>
      (delete(gruposLocal)..where((t) => t.id.equals(id))).go();

  // ── Songs ──────────────────────────────────────────────────────────────────

  Stream<List<MusicasLocalData>> watchMusicasByGrupo(String grupoId) =>
      (select(musicasLocal)..where((t) => t.grupoId.equals(grupoId))).watch();

  Future<List<MusicasLocalData>> getMusicasByGrupo(String grupoId) =>
      (select(musicasLocal)..where((t) => t.grupoId.equals(grupoId))).get();

  Future<MusicasLocalData?> getMusica(String id) =>
      (select(musicasLocal)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertMusica(MusicasLocalCompanion musica) =>
      into(musicasLocal).insertOnConflictUpdate(musica);

  Future<void> updateMusicaMomentos(String id, String momentosLiturgicos) =>
      (update(musicasLocal)..where((t) => t.id.equals(id))).write(
        MusicasLocalCompanion(
          momentosLiturgicos: Value(momentosLiturgicos),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteMusica(String id) =>
      (delete(musicasLocal)..where((t) => t.id.equals(id))).go();

  Future<void> updateMusicaId(String oldId, String newId) async {
    if (oldId == newId) return;
    await transaction(() async {
      await (update(musicasLocal)..where(
        (t) => t.id.equals(oldId),
      )).write(MusicasLocalCompanion(id: Value(newId)));
      await (update(itensCelebracaoLocal)..where(
        (t) => t.musicaId.equals(oldId),
      )).write(ItensCelebracaoLocalCompanion(musicaId: Value(newId)));
    });
  }

  Stream<DateTime?> watchMusicasSyncAt(String grupoId) =>
      (select(syncStatusLocal)
        ..where((t) => t.grupoId.equals(grupoId))).watch().map(
        (rows) => rows.isEmpty ? null : rows.first.musicasSincronizadoEm,
      );

  Future<void> updateMusicasSyncAt(String grupoId, DateTime syncedAt) =>
      into(syncStatusLocal).insertOnConflictUpdate(
        SyncStatusLocalCompanion.insert(
          grupoId: grupoId,
          musicasSincronizadoEm: Value(syncedAt),
        ),
      );

  // ── Celebrations ───────────────────────────────────────────────────────────

  Stream<List<CelebracoesLocalData>> watchCelebracoesByGrupo(String grupoId) =>
      (select(celebracoesLocal)
            ..where((t) => t.grupoId.equals(grupoId))
            ..orderBy([(t) => OrderingTerm.desc(t.dataHora)]))
          .watch();

  Future<List<CelebracoesLocalData>> getCelebracoesByGrupo(String grupoId) =>
      (select(celebracoesLocal)..where((t) => t.grupoId.equals(grupoId))).get();

  Future<CelebracoesLocalData?> getCelebracao(String id) =>
      (select(celebracoesLocal)
        ..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertCelebracao(CelebracoesLocalCompanion celebracao) =>
      into(celebracoesLocal).insertOnConflictUpdate(celebracao);

  Future<void> markCelebracaoSynced(String id) => (update(celebracoesLocal)
    ..where(
      (t) => t.id.equals(id),
    )).write(const CelebracoesLocalCompanion(isSynced: Value(true)));

  Future<void> deleteCelebracao(String id) =>
      (delete(celebracoesLocal)..where((t) => t.id.equals(id))).go();

  // ── Celebration Items ──────────────────────────────────────────────────────

  Stream<List<ItensCelebracaoLocalData>> watchItensByCelebracao(
    String celebracaoId,
  ) =>
      (select(itensCelebracaoLocal)
            ..where((t) => t.celebracaoId.equals(celebracaoId))
            ..orderBy([(t) => OrderingTerm.asc(t.ordem)]))
          .watch();

  Future<List<ItensCelebracaoLocalData>> getItensByCelebracao(
    String celebracaoId,
  ) =>
      (select(itensCelebracaoLocal)
            ..where((t) => t.celebracaoId.equals(celebracaoId))
            ..orderBy([(t) => OrderingTerm.asc(t.ordem)]))
          .get();

  Future<void> upsertItemCelebracao(ItensCelebracaoLocalCompanion item) =>
      into(itensCelebracaoLocal).insertOnConflictUpdate(item);

  Future<void> markItemCelebracaoSynced(String id) =>
      (update(itensCelebracaoLocal)..where(
        (t) => t.id.equals(id),
      )).write(const ItensCelebracaoLocalCompanion(isSynced: Value(true)));

  Future<void> deleteItensByCelebracao(String celebracaoId) =>
      (delete(itensCelebracaoLocal)
        ..where((t) => t.celebracaoId.equals(celebracaoId))).go();

  // ── Cache maintenance (#61) ────────────────────────────────────────────────

  /// Removes a group and everything cached for it: celebration items,
  /// celebrations, songs and sync status. Other groups are untouched.
  Future<void> removerConteudoDoGrupo(String grupoId) => transaction(() async {
    final celebracoesDoGrupo =
        selectOnly(celebracoesLocal)
          ..addColumns([celebracoesLocal.id])
          ..where(celebracoesLocal.grupoId.equals(grupoId));
    await (delete(itensCelebracaoLocal)
      ..where((t) => t.celebracaoId.isInQuery(celebracoesDoGrupo))).go();
    await (delete(celebracoesLocal)
      ..where((t) => t.grupoId.equals(grupoId))).go();
    await (delete(musicasLocal)..where((t) => t.grupoId.equals(grupoId))).go();
    await (delete(syncStatusLocal)
      ..where((t) => t.grupoId.equals(grupoId))).go();
    await deleteGrupo(grupoId);
  });

  /// Deletes every cached row, including metadata.
  Future<void> limparTudo() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });

  Future<String?> lerMeta(String chave) async {
    final row =
        await (select(appMetaLocal)
          ..where((t) => t.chave.equals(chave))).getSingleOrNull();
    return row?.valor;
  }

  Future<void> gravarMeta(String chave, String valor) =>
      into(appMetaLocal).insertOnConflictUpdate(
        AppMetaLocalCompanion.insert(chave: chave, valor: valor),
      );

  /// Makes sure the local cache belongs to [userId]. When another account
  /// owned it, everything is cleared first. When no owner is recorded yet
  /// (first run after the update), the current content is kept and assigned
  /// to [userId].
  Future<void> garantirDonoDoCache(String userId) => transaction(() async {
    final dono = await lerMeta(chaveDonoCache);
    if (dono == userId) return;
    if (dono != null) await limparTudo();
    await gravarMeta(chaveDonoCache, userId);
  });
}
