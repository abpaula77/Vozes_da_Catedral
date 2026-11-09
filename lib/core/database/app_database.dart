import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    UsersLocal,
    GruposLocal,
    MusicasLocal,
    CelebracoesLocal,
    ItensCelebracaoLocal,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'vozes_da_catedral_db');
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

  Future<void> deleteMusica(String id) =>
      (delete(musicasLocal)..where((t) => t.id.equals(id))).go();

  // ── Celebrations ───────────────────────────────────────────────────────────

  Stream<List<CelebracoesLocalData>> watchCelebracoesByGrupo(String grupoId) =>
      (select(celebracoesLocal)
            ..where((t) => t.grupoId.equals(grupoId))
            ..orderBy([(t) => OrderingTerm.desc(t.dataHora)]))
          .watch();

  Future<CelebracoesLocalData?> getCelebracao(String id) =>
      (select(celebracoesLocal)
        ..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertCelebracao(CelebracoesLocalCompanion celebracao) =>
      into(celebracoesLocal).insertOnConflictUpdate(celebracao);

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

  Future<void> deleteItensByCelebracao(String celebracaoId) =>
      (delete(itensCelebracaoLocal)
        ..where((t) => t.celebracaoId.equals(celebracaoId))).go();
}
