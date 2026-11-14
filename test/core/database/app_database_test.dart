import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vozes_da_catedral/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> semearGrupo(String grupoId) async {
    final agora = DateTime(2026, 1, 1);
    await db.upsertGrupo(
      GruposLocalCompanion.insert(
        id: grupoId,
        nome: 'Grupo $grupoId',
        criadoPor: 'u1',
        updatedAt: agora,
      ),
    );
    await db.upsertMusica(
      MusicasLocalCompanion.insert(
        id: 'm-$grupoId',
        grupoId: grupoId,
        titulo: 'Música',
        conteudoRaw: '',
        conteudoJson: '{}',
        updatedAt: agora,
      ),
    );
    await db.updateMusicasSyncAt(grupoId, agora);
    await db.upsertCelebracao(
      CelebracoesLocalCompanion.insert(
        id: 'c-$grupoId',
        grupoId: grupoId,
        titulo: 'Missa',
        dataHora: agora,
        criadoPor: 'u1',
        updatedAt: agora,
      ),
    );
    await db.upsertItemCelebracao(
      ItensCelebracaoLocalCompanion.insert(
        id: 'i-$grupoId',
        celebracaoId: 'c-$grupoId',
        musicaId: Value('m-$grupoId'),
        ordem: 1,
        momentoLiturgico: 'entrada',
      ),
    );
  }

  group('removerConteudoDoGrupo', () {
    test('remove only the given group and its content', () async {
      await semearGrupo('a');
      await semearGrupo('b');

      await db.removerConteudoDoGrupo('a');

      expect((await db.getGrupos()).map((g) => g.id), ['b']);
      expect(await db.getMusicasByGrupo('a'), isEmpty);
      expect(await db.getCelebracoesByGrupo('a'), isEmpty);
      expect(await db.getItensByCelebracao('c-a'), isEmpty);
      expect(await db.watchMusicasSyncAt('a').first, isNull);

      expect(await db.getMusicasByGrupo('b'), hasLength(1));
      expect(await db.getCelebracoesByGrupo('b'), hasLength(1));
      expect(await db.getItensByCelebracao('c-b'), hasLength(1));
      expect(await db.watchMusicasSyncAt('b').first, isNotNull);
    });
  });

  group('garantirDonoDoCache', () {
    test('first run keeps the content and records the owner', () async {
      await semearGrupo('a');

      await db.garantirDonoDoCache('u1');

      expect(await db.getGrupos(), hasLength(1));
      expect(await db.lerMeta(AppDatabase.chaveDonoCache), 'u1');
    });

    test('same account keeps the content', () async {
      await db.garantirDonoDoCache('u1');
      await semearGrupo('a');

      await db.garantirDonoDoCache('u1');

      expect(await db.getGrupos(), hasLength(1));
      expect(await db.getMusicasByGrupo('a'), hasLength(1));
    });

    test('another account clears everything and becomes the owner', () async {
      await db.garantirDonoDoCache('u1');
      await semearGrupo('a');
      await db.upsertUser(
        UsersLocalCompanion.insert(id: 'u1', nome: 'Ana', email: 'a@x.com'),
      );

      await db.garantirDonoDoCache('u2');

      expect(await db.getGrupos(), isEmpty);
      expect(await db.getMusicasByGrupo('a'), isEmpty);
      expect(await db.getCelebracoesByGrupo('a'), isEmpty);
      expect(await db.getItensByCelebracao('c-a'), isEmpty);
      expect(await db.getUser('u1'), isNull);
      expect(await db.lerMeta(AppDatabase.chaveDonoCache), 'u2');
    });
  });
}
