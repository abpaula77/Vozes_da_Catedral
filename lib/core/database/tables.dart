import 'package:drift/drift.dart';

/// Local SQLite table for user profile cache
class UsersLocal extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  TextColumn get email => text()();
  TextColumn get foto => text().nullable()();
  TextColumn get papel => text().withDefault(const Constant('membro'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local SQLite table for groups
class GruposLocal extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  TextColumn get descricao => text().nullable()();
  TextColumn get criadoPor => text()();
  TextColumn get meuPapel =>
      text().withDefault(
        const Constant('membro'),
      )(); // papel do usuário logado neste grupo
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local SQLite table for songs (hinário)
class MusicasLocal extends Table {
  TextColumn get id => text()();
  TextColumn get grupoId => text()();
  TextColumn get titulo => text()();
  TextColumn get tomOriginal => text().nullable()();
  IntColumn get bpm => integer().nullable()();
  TextColumn get categorias =>
      text().withDefault(const Constant('[]'))(); // JSON array string
  TextColumn get conteudoRaw => text()();
  TextColumn get conteudoJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Last successful song sync per group.
class SyncStatusLocal extends Table {
  TextColumn get grupoId => text()();
  DateTimeColumn get musicasSincronizadoEm => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {grupoId};
}

/// Local SQLite table for celebrations
class CelebracoesLocal extends Table {
  TextColumn get id => text()();
  TextColumn get grupoId => text()();
  TextColumn get titulo => text()();
  DateTimeColumn get dataHora => dateTime()();
  TextColumn get criadoPor => text()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local SQLite table for celebration items (ordered songs per celebration)
class ItensCelebracaoLocal extends Table {
  TextColumn get id => text()();
  TextColumn get celebracaoId => text()();
  TextColumn get musicaId =>
      text().nullable()(); // nullable: item pode ser só observação
  IntColumn get ordem => integer()();
  TextColumn get momentoLiturgico => text()();
  TextColumn get observacao => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
