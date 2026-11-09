// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersLocalTable extends UsersLocal
    with TableInfo<$UsersLocalTable, UsersLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fotoMeta = const VerificationMeta('foto');
  @override
  late final GeneratedColumn<String> foto = GeneratedColumn<String>(
    'foto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _papelMeta = const VerificationMeta('papel');
  @override
  late final GeneratedColumn<String> papel = GeneratedColumn<String>(
    'papel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('membro'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, nome, email, foto, papel];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsersLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('foto')) {
      context.handle(
        _fotoMeta,
        foto.isAcceptableOrUnknown(data['foto']!, _fotoMeta),
      );
    }
    if (data.containsKey('papel')) {
      context.handle(
        _papelMeta,
        papel.isAcceptableOrUnknown(data['papel']!, _papelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsersLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsersLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      nome:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nome'],
          )!,
      email:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}email'],
          )!,
      foto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto'],
      ),
      papel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}papel'],
          )!,
    );
  }

  @override
  $UsersLocalTable createAlias(String alias) {
    return $UsersLocalTable(attachedDatabase, alias);
  }
}

class UsersLocalData extends DataClass implements Insertable<UsersLocalData> {
  final String id;
  final String nome;
  final String email;
  final String? foto;
  final String papel;
  const UsersLocalData({
    required this.id,
    required this.nome,
    required this.email,
    this.foto,
    required this.papel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || foto != null) {
      map['foto'] = Variable<String>(foto);
    }
    map['papel'] = Variable<String>(papel);
    return map;
  }

  UsersLocalCompanion toCompanion(bool nullToAbsent) {
    return UsersLocalCompanion(
      id: Value(id),
      nome: Value(nome),
      email: Value(email),
      foto: foto == null && nullToAbsent ? const Value.absent() : Value(foto),
      papel: Value(papel),
    );
  }

  factory UsersLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsersLocalData(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      email: serializer.fromJson<String>(json['email']),
      foto: serializer.fromJson<String?>(json['foto']),
      papel: serializer.fromJson<String>(json['papel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'email': serializer.toJson<String>(email),
      'foto': serializer.toJson<String?>(foto),
      'papel': serializer.toJson<String>(papel),
    };
  }

  UsersLocalData copyWith({
    String? id,
    String? nome,
    String? email,
    Value<String?> foto = const Value.absent(),
    String? papel,
  }) => UsersLocalData(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    email: email ?? this.email,
    foto: foto.present ? foto.value : this.foto,
    papel: papel ?? this.papel,
  );
  UsersLocalData copyWithCompanion(UsersLocalCompanion data) {
    return UsersLocalData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      email: data.email.present ? data.email.value : this.email,
      foto: data.foto.present ? data.foto.value : this.foto,
      papel: data.papel.present ? data.papel.value : this.papel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsersLocalData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('foto: $foto, ')
          ..write('papel: $papel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, email, foto, papel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsersLocalData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.email == this.email &&
          other.foto == this.foto &&
          other.papel == this.papel);
}

class UsersLocalCompanion extends UpdateCompanion<UsersLocalData> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String> email;
  final Value<String?> foto;
  final Value<String> papel;
  final Value<int> rowid;
  const UsersLocalCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.email = const Value.absent(),
    this.foto = const Value.absent(),
    this.papel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersLocalCompanion.insert({
    required String id,
    required String nome,
    required String email,
    this.foto = const Value.absent(),
    this.papel = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       email = Value(email);
  static Insertable<UsersLocalData> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? email,
    Expression<String>? foto,
    Expression<String>? papel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (email != null) 'email': email,
      if (foto != null) 'foto': foto,
      if (papel != null) 'papel': papel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String>? email,
    Value<String?>? foto,
    Value<String>? papel,
    Value<int>? rowid,
  }) {
    return UsersLocalCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      foto: foto ?? this.foto,
      papel: papel ?? this.papel,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (foto.present) {
      map['foto'] = Variable<String>(foto.value);
    }
    if (papel.present) {
      map['papel'] = Variable<String>(papel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersLocalCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('email: $email, ')
          ..write('foto: $foto, ')
          ..write('papel: $papel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GruposLocalTable extends GruposLocal
    with TableInfo<$GruposLocalTable, GruposLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GruposLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _criadoPorMeta = const VerificationMeta(
    'criadoPor',
  );
  @override
  late final GeneratedColumn<String> criadoPor = GeneratedColumn<String>(
    'criado_por',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meuPapelMeta = const VerificationMeta(
    'meuPapel',
  );
  @override
  late final GeneratedColumn<String> meuPapel = GeneratedColumn<String>(
    'meu_papel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('membro'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nome,
    descricao,
    criadoPor,
    meuPapel,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grupos_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<GruposLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    }
    if (data.containsKey('criado_por')) {
      context.handle(
        _criadoPorMeta,
        criadoPor.isAcceptableOrUnknown(data['criado_por']!, _criadoPorMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoPorMeta);
    }
    if (data.containsKey('meu_papel')) {
      context.handle(
        _meuPapelMeta,
        meuPapel.isAcceptableOrUnknown(data['meu_papel']!, _meuPapelMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GruposLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GruposLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      nome:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nome'],
          )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      ),
      criadoPor:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}criado_por'],
          )!,
      meuPapel:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}meu_papel'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $GruposLocalTable createAlias(String alias) {
    return $GruposLocalTable(attachedDatabase, alias);
  }
}

class GruposLocalData extends DataClass implements Insertable<GruposLocalData> {
  final String id;
  final String nome;
  final String? descricao;
  final String criadoPor;
  final String meuPapel;
  final DateTime updatedAt;
  const GruposLocalData({
    required this.id,
    required this.nome,
    this.descricao,
    required this.criadoPor,
    required this.meuPapel,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || descricao != null) {
      map['descricao'] = Variable<String>(descricao);
    }
    map['criado_por'] = Variable<String>(criadoPor);
    map['meu_papel'] = Variable<String>(meuPapel);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GruposLocalCompanion toCompanion(bool nullToAbsent) {
    return GruposLocalCompanion(
      id: Value(id),
      nome: Value(nome),
      descricao:
          descricao == null && nullToAbsent
              ? const Value.absent()
              : Value(descricao),
      criadoPor: Value(criadoPor),
      meuPapel: Value(meuPapel),
      updatedAt: Value(updatedAt),
    );
  }

  factory GruposLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GruposLocalData(
      id: serializer.fromJson<String>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      descricao: serializer.fromJson<String?>(json['descricao']),
      criadoPor: serializer.fromJson<String>(json['criadoPor']),
      meuPapel: serializer.fromJson<String>(json['meuPapel']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nome': serializer.toJson<String>(nome),
      'descricao': serializer.toJson<String?>(descricao),
      'criadoPor': serializer.toJson<String>(criadoPor),
      'meuPapel': serializer.toJson<String>(meuPapel),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GruposLocalData copyWith({
    String? id,
    String? nome,
    Value<String?> descricao = const Value.absent(),
    String? criadoPor,
    String? meuPapel,
    DateTime? updatedAt,
  }) => GruposLocalData(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    descricao: descricao.present ? descricao.value : this.descricao,
    criadoPor: criadoPor ?? this.criadoPor,
    meuPapel: meuPapel ?? this.meuPapel,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GruposLocalData copyWithCompanion(GruposLocalCompanion data) {
    return GruposLocalData(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      criadoPor: data.criadoPor.present ? data.criadoPor.value : this.criadoPor,
      meuPapel: data.meuPapel.present ? data.meuPapel.value : this.meuPapel,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GruposLocalData(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('descricao: $descricao, ')
          ..write('criadoPor: $criadoPor, ')
          ..write('meuPapel: $meuPapel, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nome, descricao, criadoPor, meuPapel, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GruposLocalData &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.descricao == this.descricao &&
          other.criadoPor == this.criadoPor &&
          other.meuPapel == this.meuPapel &&
          other.updatedAt == this.updatedAt);
}

class GruposLocalCompanion extends UpdateCompanion<GruposLocalData> {
  final Value<String> id;
  final Value<String> nome;
  final Value<String?> descricao;
  final Value<String> criadoPor;
  final Value<String> meuPapel;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GruposLocalCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.descricao = const Value.absent(),
    this.criadoPor = const Value.absent(),
    this.meuPapel = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GruposLocalCompanion.insert({
    required String id,
    required String nome,
    this.descricao = const Value.absent(),
    required String criadoPor,
    this.meuPapel = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nome = Value(nome),
       criadoPor = Value(criadoPor),
       updatedAt = Value(updatedAt);
  static Insertable<GruposLocalData> custom({
    Expression<String>? id,
    Expression<String>? nome,
    Expression<String>? descricao,
    Expression<String>? criadoPor,
    Expression<String>? meuPapel,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (descricao != null) 'descricao': descricao,
      if (criadoPor != null) 'criado_por': criadoPor,
      if (meuPapel != null) 'meu_papel': meuPapel,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GruposLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? nome,
    Value<String?>? descricao,
    Value<String>? criadoPor,
    Value<String>? meuPapel,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return GruposLocalCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      criadoPor: criadoPor ?? this.criadoPor,
      meuPapel: meuPapel ?? this.meuPapel,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (criadoPor.present) {
      map['criado_por'] = Variable<String>(criadoPor.value);
    }
    if (meuPapel.present) {
      map['meu_papel'] = Variable<String>(meuPapel.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GruposLocalCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('descricao: $descricao, ')
          ..write('criadoPor: $criadoPor, ')
          ..write('meuPapel: $meuPapel, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MusicasLocalTable extends MusicasLocal
    with TableInfo<$MusicasLocalTable, MusicasLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MusicasLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grupoIdMeta = const VerificationMeta(
    'grupoId',
  );
  @override
  late final GeneratedColumn<String> grupoId = GeneratedColumn<String>(
    'grupo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
    'titulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tomOriginalMeta = const VerificationMeta(
    'tomOriginal',
  );
  @override
  late final GeneratedColumn<String> tomOriginal = GeneratedColumn<String>(
    'tom_original',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriasMeta = const VerificationMeta(
    'categorias',
  );
  @override
  late final GeneratedColumn<String> categorias = GeneratedColumn<String>(
    'categorias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _conteudoRawMeta = const VerificationMeta(
    'conteudoRaw',
  );
  @override
  late final GeneratedColumn<String> conteudoRaw = GeneratedColumn<String>(
    'conteudo_raw',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conteudoJsonMeta = const VerificationMeta(
    'conteudoJson',
  );
  @override
  late final GeneratedColumn<String> conteudoJson = GeneratedColumn<String>(
    'conteudo_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    grupoId,
    titulo,
    tomOriginal,
    bpm,
    categorias,
    conteudoRaw,
    conteudoJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'musicas_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<MusicasLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('grupo_id')) {
      context.handle(
        _grupoIdMeta,
        grupoId.isAcceptableOrUnknown(data['grupo_id']!, _grupoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_grupoIdMeta);
    }
    if (data.containsKey('titulo')) {
      context.handle(
        _tituloMeta,
        titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta),
      );
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('tom_original')) {
      context.handle(
        _tomOriginalMeta,
        tomOriginal.isAcceptableOrUnknown(
          data['tom_original']!,
          _tomOriginalMeta,
        ),
      );
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    }
    if (data.containsKey('categorias')) {
      context.handle(
        _categoriasMeta,
        categorias.isAcceptableOrUnknown(data['categorias']!, _categoriasMeta),
      );
    }
    if (data.containsKey('conteudo_raw')) {
      context.handle(
        _conteudoRawMeta,
        conteudoRaw.isAcceptableOrUnknown(
          data['conteudo_raw']!,
          _conteudoRawMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conteudoRawMeta);
    }
    if (data.containsKey('conteudo_json')) {
      context.handle(
        _conteudoJsonMeta,
        conteudoJson.isAcceptableOrUnknown(
          data['conteudo_json']!,
          _conteudoJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conteudoJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MusicasLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MusicasLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      grupoId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}grupo_id'],
          )!,
      titulo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}titulo'],
          )!,
      tomOriginal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tom_original'],
      ),
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      ),
      categorias:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}categorias'],
          )!,
      conteudoRaw:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}conteudo_raw'],
          )!,
      conteudoJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}conteudo_json'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $MusicasLocalTable createAlias(String alias) {
    return $MusicasLocalTable(attachedDatabase, alias);
  }
}

class MusicasLocalData extends DataClass
    implements Insertable<MusicasLocalData> {
  final String id;
  final String grupoId;
  final String titulo;
  final String? tomOriginal;
  final int? bpm;
  final String categorias;
  final String conteudoRaw;
  final String conteudoJson;
  final DateTime updatedAt;
  const MusicasLocalData({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['grupo_id'] = Variable<String>(grupoId);
    map['titulo'] = Variable<String>(titulo);
    if (!nullToAbsent || tomOriginal != null) {
      map['tom_original'] = Variable<String>(tomOriginal);
    }
    if (!nullToAbsent || bpm != null) {
      map['bpm'] = Variable<int>(bpm);
    }
    map['categorias'] = Variable<String>(categorias);
    map['conteudo_raw'] = Variable<String>(conteudoRaw);
    map['conteudo_json'] = Variable<String>(conteudoJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MusicasLocalCompanion toCompanion(bool nullToAbsent) {
    return MusicasLocalCompanion(
      id: Value(id),
      grupoId: Value(grupoId),
      titulo: Value(titulo),
      tomOriginal:
          tomOriginal == null && nullToAbsent
              ? const Value.absent()
              : Value(tomOriginal),
      bpm: bpm == null && nullToAbsent ? const Value.absent() : Value(bpm),
      categorias: Value(categorias),
      conteudoRaw: Value(conteudoRaw),
      conteudoJson: Value(conteudoJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory MusicasLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MusicasLocalData(
      id: serializer.fromJson<String>(json['id']),
      grupoId: serializer.fromJson<String>(json['grupoId']),
      titulo: serializer.fromJson<String>(json['titulo']),
      tomOriginal: serializer.fromJson<String?>(json['tomOriginal']),
      bpm: serializer.fromJson<int?>(json['bpm']),
      categorias: serializer.fromJson<String>(json['categorias']),
      conteudoRaw: serializer.fromJson<String>(json['conteudoRaw']),
      conteudoJson: serializer.fromJson<String>(json['conteudoJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'grupoId': serializer.toJson<String>(grupoId),
      'titulo': serializer.toJson<String>(titulo),
      'tomOriginal': serializer.toJson<String?>(tomOriginal),
      'bpm': serializer.toJson<int?>(bpm),
      'categorias': serializer.toJson<String>(categorias),
      'conteudoRaw': serializer.toJson<String>(conteudoRaw),
      'conteudoJson': serializer.toJson<String>(conteudoJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MusicasLocalData copyWith({
    String? id,
    String? grupoId,
    String? titulo,
    Value<String?> tomOriginal = const Value.absent(),
    Value<int?> bpm = const Value.absent(),
    String? categorias,
    String? conteudoRaw,
    String? conteudoJson,
    DateTime? updatedAt,
  }) => MusicasLocalData(
    id: id ?? this.id,
    grupoId: grupoId ?? this.grupoId,
    titulo: titulo ?? this.titulo,
    tomOriginal: tomOriginal.present ? tomOriginal.value : this.tomOriginal,
    bpm: bpm.present ? bpm.value : this.bpm,
    categorias: categorias ?? this.categorias,
    conteudoRaw: conteudoRaw ?? this.conteudoRaw,
    conteudoJson: conteudoJson ?? this.conteudoJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MusicasLocalData copyWithCompanion(MusicasLocalCompanion data) {
    return MusicasLocalData(
      id: data.id.present ? data.id.value : this.id,
      grupoId: data.grupoId.present ? data.grupoId.value : this.grupoId,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      tomOriginal:
          data.tomOriginal.present ? data.tomOriginal.value : this.tomOriginal,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      categorias:
          data.categorias.present ? data.categorias.value : this.categorias,
      conteudoRaw:
          data.conteudoRaw.present ? data.conteudoRaw.value : this.conteudoRaw,
      conteudoJson:
          data.conteudoJson.present
              ? data.conteudoJson.value
              : this.conteudoJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MusicasLocalData(')
          ..write('id: $id, ')
          ..write('grupoId: $grupoId, ')
          ..write('titulo: $titulo, ')
          ..write('tomOriginal: $tomOriginal, ')
          ..write('bpm: $bpm, ')
          ..write('categorias: $categorias, ')
          ..write('conteudoRaw: $conteudoRaw, ')
          ..write('conteudoJson: $conteudoJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    grupoId,
    titulo,
    tomOriginal,
    bpm,
    categorias,
    conteudoRaw,
    conteudoJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MusicasLocalData &&
          other.id == this.id &&
          other.grupoId == this.grupoId &&
          other.titulo == this.titulo &&
          other.tomOriginal == this.tomOriginal &&
          other.bpm == this.bpm &&
          other.categorias == this.categorias &&
          other.conteudoRaw == this.conteudoRaw &&
          other.conteudoJson == this.conteudoJson &&
          other.updatedAt == this.updatedAt);
}

class MusicasLocalCompanion extends UpdateCompanion<MusicasLocalData> {
  final Value<String> id;
  final Value<String> grupoId;
  final Value<String> titulo;
  final Value<String?> tomOriginal;
  final Value<int?> bpm;
  final Value<String> categorias;
  final Value<String> conteudoRaw;
  final Value<String> conteudoJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MusicasLocalCompanion({
    this.id = const Value.absent(),
    this.grupoId = const Value.absent(),
    this.titulo = const Value.absent(),
    this.tomOriginal = const Value.absent(),
    this.bpm = const Value.absent(),
    this.categorias = const Value.absent(),
    this.conteudoRaw = const Value.absent(),
    this.conteudoJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MusicasLocalCompanion.insert({
    required String id,
    required String grupoId,
    required String titulo,
    this.tomOriginal = const Value.absent(),
    this.bpm = const Value.absent(),
    this.categorias = const Value.absent(),
    required String conteudoRaw,
    required String conteudoJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       grupoId = Value(grupoId),
       titulo = Value(titulo),
       conteudoRaw = Value(conteudoRaw),
       conteudoJson = Value(conteudoJson),
       updatedAt = Value(updatedAt);
  static Insertable<MusicasLocalData> custom({
    Expression<String>? id,
    Expression<String>? grupoId,
    Expression<String>? titulo,
    Expression<String>? tomOriginal,
    Expression<int>? bpm,
    Expression<String>? categorias,
    Expression<String>? conteudoRaw,
    Expression<String>? conteudoJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (grupoId != null) 'grupo_id': grupoId,
      if (titulo != null) 'titulo': titulo,
      if (tomOriginal != null) 'tom_original': tomOriginal,
      if (bpm != null) 'bpm': bpm,
      if (categorias != null) 'categorias': categorias,
      if (conteudoRaw != null) 'conteudo_raw': conteudoRaw,
      if (conteudoJson != null) 'conteudo_json': conteudoJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MusicasLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? grupoId,
    Value<String>? titulo,
    Value<String?>? tomOriginal,
    Value<int?>? bpm,
    Value<String>? categorias,
    Value<String>? conteudoRaw,
    Value<String>? conteudoJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MusicasLocalCompanion(
      id: id ?? this.id,
      grupoId: grupoId ?? this.grupoId,
      titulo: titulo ?? this.titulo,
      tomOriginal: tomOriginal ?? this.tomOriginal,
      bpm: bpm ?? this.bpm,
      categorias: categorias ?? this.categorias,
      conteudoRaw: conteudoRaw ?? this.conteudoRaw,
      conteudoJson: conteudoJson ?? this.conteudoJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (grupoId.present) {
      map['grupo_id'] = Variable<String>(grupoId.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (tomOriginal.present) {
      map['tom_original'] = Variable<String>(tomOriginal.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (categorias.present) {
      map['categorias'] = Variable<String>(categorias.value);
    }
    if (conteudoRaw.present) {
      map['conteudo_raw'] = Variable<String>(conteudoRaw.value);
    }
    if (conteudoJson.present) {
      map['conteudo_json'] = Variable<String>(conteudoJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MusicasLocalCompanion(')
          ..write('id: $id, ')
          ..write('grupoId: $grupoId, ')
          ..write('titulo: $titulo, ')
          ..write('tomOriginal: $tomOriginal, ')
          ..write('bpm: $bpm, ')
          ..write('categorias: $categorias, ')
          ..write('conteudoRaw: $conteudoRaw, ')
          ..write('conteudoJson: $conteudoJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatusLocalTable extends SyncStatusLocal
    with TableInfo<$SyncStatusLocalTable, SyncStatusLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatusLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _grupoIdMeta = const VerificationMeta(
    'grupoId',
  );
  @override
  late final GeneratedColumn<String> grupoId = GeneratedColumn<String>(
    'grupo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _musicasSincronizadoEmMeta =
      const VerificationMeta('musicasSincronizadoEm');
  @override
  late final GeneratedColumn<DateTime> musicasSincronizadoEm =
      GeneratedColumn<DateTime>(
        'musicas_sincronizado_em',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [grupoId, musicasSincronizadoEm];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_status_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStatusLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('grupo_id')) {
      context.handle(
        _grupoIdMeta,
        grupoId.isAcceptableOrUnknown(data['grupo_id']!, _grupoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_grupoIdMeta);
    }
    if (data.containsKey('musicas_sincronizado_em')) {
      context.handle(
        _musicasSincronizadoEmMeta,
        musicasSincronizadoEm.isAcceptableOrUnknown(
          data['musicas_sincronizado_em']!,
          _musicasSincronizadoEmMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {grupoId};
  @override
  SyncStatusLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStatusLocalData(
      grupoId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}grupo_id'],
          )!,
      musicasSincronizadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}musicas_sincronizado_em'],
      ),
    );
  }

  @override
  $SyncStatusLocalTable createAlias(String alias) {
    return $SyncStatusLocalTable(attachedDatabase, alias);
  }
}

class SyncStatusLocalData extends DataClass
    implements Insertable<SyncStatusLocalData> {
  final String grupoId;
  final DateTime? musicasSincronizadoEm;
  const SyncStatusLocalData({
    required this.grupoId,
    this.musicasSincronizadoEm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['grupo_id'] = Variable<String>(grupoId);
    if (!nullToAbsent || musicasSincronizadoEm != null) {
      map['musicas_sincronizado_em'] = Variable<DateTime>(
        musicasSincronizadoEm,
      );
    }
    return map;
  }

  SyncStatusLocalCompanion toCompanion(bool nullToAbsent) {
    return SyncStatusLocalCompanion(
      grupoId: Value(grupoId),
      musicasSincronizadoEm:
          musicasSincronizadoEm == null && nullToAbsent
              ? const Value.absent()
              : Value(musicasSincronizadoEm),
    );
  }

  factory SyncStatusLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStatusLocalData(
      grupoId: serializer.fromJson<String>(json['grupoId']),
      musicasSincronizadoEm: serializer.fromJson<DateTime?>(
        json['musicasSincronizadoEm'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'grupoId': serializer.toJson<String>(grupoId),
      'musicasSincronizadoEm': serializer.toJson<DateTime?>(
        musicasSincronizadoEm,
      ),
    };
  }

  SyncStatusLocalData copyWith({
    String? grupoId,
    Value<DateTime?> musicasSincronizadoEm = const Value.absent(),
  }) => SyncStatusLocalData(
    grupoId: grupoId ?? this.grupoId,
    musicasSincronizadoEm:
        musicasSincronizadoEm.present
            ? musicasSincronizadoEm.value
            : this.musicasSincronizadoEm,
  );
  SyncStatusLocalData copyWithCompanion(SyncStatusLocalCompanion data) {
    return SyncStatusLocalData(
      grupoId: data.grupoId.present ? data.grupoId.value : this.grupoId,
      musicasSincronizadoEm:
          data.musicasSincronizadoEm.present
              ? data.musicasSincronizadoEm.value
              : this.musicasSincronizadoEm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatusLocalData(')
          ..write('grupoId: $grupoId, ')
          ..write('musicasSincronizadoEm: $musicasSincronizadoEm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(grupoId, musicasSincronizadoEm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStatusLocalData &&
          other.grupoId == this.grupoId &&
          other.musicasSincronizadoEm == this.musicasSincronizadoEm);
}

class SyncStatusLocalCompanion extends UpdateCompanion<SyncStatusLocalData> {
  final Value<String> grupoId;
  final Value<DateTime?> musicasSincronizadoEm;
  final Value<int> rowid;
  const SyncStatusLocalCompanion({
    this.grupoId = const Value.absent(),
    this.musicasSincronizadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatusLocalCompanion.insert({
    required String grupoId,
    this.musicasSincronizadoEm = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : grupoId = Value(grupoId);
  static Insertable<SyncStatusLocalData> custom({
    Expression<String>? grupoId,
    Expression<DateTime>? musicasSincronizadoEm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (grupoId != null) 'grupo_id': grupoId,
      if (musicasSincronizadoEm != null)
        'musicas_sincronizado_em': musicasSincronizadoEm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatusLocalCompanion copyWith({
    Value<String>? grupoId,
    Value<DateTime?>? musicasSincronizadoEm,
    Value<int>? rowid,
  }) {
    return SyncStatusLocalCompanion(
      grupoId: grupoId ?? this.grupoId,
      musicasSincronizadoEm:
          musicasSincronizadoEm ?? this.musicasSincronizadoEm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (grupoId.present) {
      map['grupo_id'] = Variable<String>(grupoId.value);
    }
    if (musicasSincronizadoEm.present) {
      map['musicas_sincronizado_em'] = Variable<DateTime>(
        musicasSincronizadoEm.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatusLocalCompanion(')
          ..write('grupoId: $grupoId, ')
          ..write('musicasSincronizadoEm: $musicasSincronizadoEm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CelebracoesLocalTable extends CelebracoesLocal
    with TableInfo<$CelebracoesLocalTable, CelebracoesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CelebracoesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grupoIdMeta = const VerificationMeta(
    'grupoId',
  );
  @override
  late final GeneratedColumn<String> grupoId = GeneratedColumn<String>(
    'grupo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tituloMeta = const VerificationMeta('titulo');
  @override
  late final GeneratedColumn<String> titulo = GeneratedColumn<String>(
    'titulo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataHoraMeta = const VerificationMeta(
    'dataHora',
  );
  @override
  late final GeneratedColumn<DateTime> dataHora = GeneratedColumn<DateTime>(
    'data_hora',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _criadoPorMeta = const VerificationMeta(
    'criadoPor',
  );
  @override
  late final GeneratedColumn<String> criadoPor = GeneratedColumn<String>(
    'criado_por',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    grupoId,
    titulo,
    dataHora,
    criadoPor,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'celebracoes_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<CelebracoesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('grupo_id')) {
      context.handle(
        _grupoIdMeta,
        grupoId.isAcceptableOrUnknown(data['grupo_id']!, _grupoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_grupoIdMeta);
    }
    if (data.containsKey('titulo')) {
      context.handle(
        _tituloMeta,
        titulo.isAcceptableOrUnknown(data['titulo']!, _tituloMeta),
      );
    } else if (isInserting) {
      context.missing(_tituloMeta);
    }
    if (data.containsKey('data_hora')) {
      context.handle(
        _dataHoraMeta,
        dataHora.isAcceptableOrUnknown(data['data_hora']!, _dataHoraMeta),
      );
    } else if (isInserting) {
      context.missing(_dataHoraMeta);
    }
    if (data.containsKey('criado_por')) {
      context.handle(
        _criadoPorMeta,
        criadoPor.isAcceptableOrUnknown(data['criado_por']!, _criadoPorMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoPorMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CelebracoesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CelebracoesLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      grupoId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}grupo_id'],
          )!,
      titulo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}titulo'],
          )!,
      dataHora:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}data_hora'],
          )!,
      criadoPor:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}criado_por'],
          )!,
      updatedAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}updated_at'],
          )!,
    );
  }

  @override
  $CelebracoesLocalTable createAlias(String alias) {
    return $CelebracoesLocalTable(attachedDatabase, alias);
  }
}

class CelebracoesLocalData extends DataClass
    implements Insertable<CelebracoesLocalData> {
  final String id;
  final String grupoId;
  final String titulo;
  final DateTime dataHora;
  final String criadoPor;
  final DateTime updatedAt;
  const CelebracoesLocalData({
    required this.id,
    required this.grupoId,
    required this.titulo,
    required this.dataHora,
    required this.criadoPor,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['grupo_id'] = Variable<String>(grupoId);
    map['titulo'] = Variable<String>(titulo);
    map['data_hora'] = Variable<DateTime>(dataHora);
    map['criado_por'] = Variable<String>(criadoPor);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CelebracoesLocalCompanion toCompanion(bool nullToAbsent) {
    return CelebracoesLocalCompanion(
      id: Value(id),
      grupoId: Value(grupoId),
      titulo: Value(titulo),
      dataHora: Value(dataHora),
      criadoPor: Value(criadoPor),
      updatedAt: Value(updatedAt),
    );
  }

  factory CelebracoesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CelebracoesLocalData(
      id: serializer.fromJson<String>(json['id']),
      grupoId: serializer.fromJson<String>(json['grupoId']),
      titulo: serializer.fromJson<String>(json['titulo']),
      dataHora: serializer.fromJson<DateTime>(json['dataHora']),
      criadoPor: serializer.fromJson<String>(json['criadoPor']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'grupoId': serializer.toJson<String>(grupoId),
      'titulo': serializer.toJson<String>(titulo),
      'dataHora': serializer.toJson<DateTime>(dataHora),
      'criadoPor': serializer.toJson<String>(criadoPor),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CelebracoesLocalData copyWith({
    String? id,
    String? grupoId,
    String? titulo,
    DateTime? dataHora,
    String? criadoPor,
    DateTime? updatedAt,
  }) => CelebracoesLocalData(
    id: id ?? this.id,
    grupoId: grupoId ?? this.grupoId,
    titulo: titulo ?? this.titulo,
    dataHora: dataHora ?? this.dataHora,
    criadoPor: criadoPor ?? this.criadoPor,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CelebracoesLocalData copyWithCompanion(CelebracoesLocalCompanion data) {
    return CelebracoesLocalData(
      id: data.id.present ? data.id.value : this.id,
      grupoId: data.grupoId.present ? data.grupoId.value : this.grupoId,
      titulo: data.titulo.present ? data.titulo.value : this.titulo,
      dataHora: data.dataHora.present ? data.dataHora.value : this.dataHora,
      criadoPor: data.criadoPor.present ? data.criadoPor.value : this.criadoPor,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CelebracoesLocalData(')
          ..write('id: $id, ')
          ..write('grupoId: $grupoId, ')
          ..write('titulo: $titulo, ')
          ..write('dataHora: $dataHora, ')
          ..write('criadoPor: $criadoPor, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, grupoId, titulo, dataHora, criadoPor, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CelebracoesLocalData &&
          other.id == this.id &&
          other.grupoId == this.grupoId &&
          other.titulo == this.titulo &&
          other.dataHora == this.dataHora &&
          other.criadoPor == this.criadoPor &&
          other.updatedAt == this.updatedAt);
}

class CelebracoesLocalCompanion extends UpdateCompanion<CelebracoesLocalData> {
  final Value<String> id;
  final Value<String> grupoId;
  final Value<String> titulo;
  final Value<DateTime> dataHora;
  final Value<String> criadoPor;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CelebracoesLocalCompanion({
    this.id = const Value.absent(),
    this.grupoId = const Value.absent(),
    this.titulo = const Value.absent(),
    this.dataHora = const Value.absent(),
    this.criadoPor = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CelebracoesLocalCompanion.insert({
    required String id,
    required String grupoId,
    required String titulo,
    required DateTime dataHora,
    required String criadoPor,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       grupoId = Value(grupoId),
       titulo = Value(titulo),
       dataHora = Value(dataHora),
       criadoPor = Value(criadoPor),
       updatedAt = Value(updatedAt);
  static Insertable<CelebracoesLocalData> custom({
    Expression<String>? id,
    Expression<String>? grupoId,
    Expression<String>? titulo,
    Expression<DateTime>? dataHora,
    Expression<String>? criadoPor,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (grupoId != null) 'grupo_id': grupoId,
      if (titulo != null) 'titulo': titulo,
      if (dataHora != null) 'data_hora': dataHora,
      if (criadoPor != null) 'criado_por': criadoPor,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CelebracoesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? grupoId,
    Value<String>? titulo,
    Value<DateTime>? dataHora,
    Value<String>? criadoPor,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CelebracoesLocalCompanion(
      id: id ?? this.id,
      grupoId: grupoId ?? this.grupoId,
      titulo: titulo ?? this.titulo,
      dataHora: dataHora ?? this.dataHora,
      criadoPor: criadoPor ?? this.criadoPor,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (grupoId.present) {
      map['grupo_id'] = Variable<String>(grupoId.value);
    }
    if (titulo.present) {
      map['titulo'] = Variable<String>(titulo.value);
    }
    if (dataHora.present) {
      map['data_hora'] = Variable<DateTime>(dataHora.value);
    }
    if (criadoPor.present) {
      map['criado_por'] = Variable<String>(criadoPor.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CelebracoesLocalCompanion(')
          ..write('id: $id, ')
          ..write('grupoId: $grupoId, ')
          ..write('titulo: $titulo, ')
          ..write('dataHora: $dataHora, ')
          ..write('criadoPor: $criadoPor, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItensCelebracaoLocalTable extends ItensCelebracaoLocal
    with TableInfo<$ItensCelebracaoLocalTable, ItensCelebracaoLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItensCelebracaoLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _celebracaoIdMeta = const VerificationMeta(
    'celebracaoId',
  );
  @override
  late final GeneratedColumn<String> celebracaoId = GeneratedColumn<String>(
    'celebracao_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _musicaIdMeta = const VerificationMeta(
    'musicaId',
  );
  @override
  late final GeneratedColumn<String> musicaId = GeneratedColumn<String>(
    'musica_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordemMeta = const VerificationMeta('ordem');
  @override
  late final GeneratedColumn<int> ordem = GeneratedColumn<int>(
    'ordem',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _momentoLiturgicoMeta = const VerificationMeta(
    'momentoLiturgico',
  );
  @override
  late final GeneratedColumn<String> momentoLiturgico = GeneratedColumn<String>(
    'momento_liturgico',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observacaoMeta = const VerificationMeta(
    'observacao',
  );
  @override
  late final GeneratedColumn<String> observacao = GeneratedColumn<String>(
    'observacao',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    celebracaoId,
    musicaId,
    ordem,
    momentoLiturgico,
    observacao,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'itens_celebracao_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItensCelebracaoLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('celebracao_id')) {
      context.handle(
        _celebracaoIdMeta,
        celebracaoId.isAcceptableOrUnknown(
          data['celebracao_id']!,
          _celebracaoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_celebracaoIdMeta);
    }
    if (data.containsKey('musica_id')) {
      context.handle(
        _musicaIdMeta,
        musicaId.isAcceptableOrUnknown(data['musica_id']!, _musicaIdMeta),
      );
    }
    if (data.containsKey('ordem')) {
      context.handle(
        _ordemMeta,
        ordem.isAcceptableOrUnknown(data['ordem']!, _ordemMeta),
      );
    } else if (isInserting) {
      context.missing(_ordemMeta);
    }
    if (data.containsKey('momento_liturgico')) {
      context.handle(
        _momentoLiturgicoMeta,
        momentoLiturgico.isAcceptableOrUnknown(
          data['momento_liturgico']!,
          _momentoLiturgicoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_momentoLiturgicoMeta);
    }
    if (data.containsKey('observacao')) {
      context.handle(
        _observacaoMeta,
        observacao.isAcceptableOrUnknown(data['observacao']!, _observacaoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItensCelebracaoLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItensCelebracaoLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      celebracaoId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}celebracao_id'],
          )!,
      musicaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}musica_id'],
      ),
      ordem:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}ordem'],
          )!,
      momentoLiturgico:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}momento_liturgico'],
          )!,
      observacao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observacao'],
      ),
    );
  }

  @override
  $ItensCelebracaoLocalTable createAlias(String alias) {
    return $ItensCelebracaoLocalTable(attachedDatabase, alias);
  }
}

class ItensCelebracaoLocalData extends DataClass
    implements Insertable<ItensCelebracaoLocalData> {
  final String id;
  final String celebracaoId;
  final String? musicaId;
  final int ordem;
  final String momentoLiturgico;
  final String? observacao;
  const ItensCelebracaoLocalData({
    required this.id,
    required this.celebracaoId,
    this.musicaId,
    required this.ordem,
    required this.momentoLiturgico,
    this.observacao,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['celebracao_id'] = Variable<String>(celebracaoId);
    if (!nullToAbsent || musicaId != null) {
      map['musica_id'] = Variable<String>(musicaId);
    }
    map['ordem'] = Variable<int>(ordem);
    map['momento_liturgico'] = Variable<String>(momentoLiturgico);
    if (!nullToAbsent || observacao != null) {
      map['observacao'] = Variable<String>(observacao);
    }
    return map;
  }

  ItensCelebracaoLocalCompanion toCompanion(bool nullToAbsent) {
    return ItensCelebracaoLocalCompanion(
      id: Value(id),
      celebracaoId: Value(celebracaoId),
      musicaId:
          musicaId == null && nullToAbsent
              ? const Value.absent()
              : Value(musicaId),
      ordem: Value(ordem),
      momentoLiturgico: Value(momentoLiturgico),
      observacao:
          observacao == null && nullToAbsent
              ? const Value.absent()
              : Value(observacao),
    );
  }

  factory ItensCelebracaoLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItensCelebracaoLocalData(
      id: serializer.fromJson<String>(json['id']),
      celebracaoId: serializer.fromJson<String>(json['celebracaoId']),
      musicaId: serializer.fromJson<String?>(json['musicaId']),
      ordem: serializer.fromJson<int>(json['ordem']),
      momentoLiturgico: serializer.fromJson<String>(json['momentoLiturgico']),
      observacao: serializer.fromJson<String?>(json['observacao']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'celebracaoId': serializer.toJson<String>(celebracaoId),
      'musicaId': serializer.toJson<String?>(musicaId),
      'ordem': serializer.toJson<int>(ordem),
      'momentoLiturgico': serializer.toJson<String>(momentoLiturgico),
      'observacao': serializer.toJson<String?>(observacao),
    };
  }

  ItensCelebracaoLocalData copyWith({
    String? id,
    String? celebracaoId,
    Value<String?> musicaId = const Value.absent(),
    int? ordem,
    String? momentoLiturgico,
    Value<String?> observacao = const Value.absent(),
  }) => ItensCelebracaoLocalData(
    id: id ?? this.id,
    celebracaoId: celebracaoId ?? this.celebracaoId,
    musicaId: musicaId.present ? musicaId.value : this.musicaId,
    ordem: ordem ?? this.ordem,
    momentoLiturgico: momentoLiturgico ?? this.momentoLiturgico,
    observacao: observacao.present ? observacao.value : this.observacao,
  );
  ItensCelebracaoLocalData copyWithCompanion(
    ItensCelebracaoLocalCompanion data,
  ) {
    return ItensCelebracaoLocalData(
      id: data.id.present ? data.id.value : this.id,
      celebracaoId:
          data.celebracaoId.present
              ? data.celebracaoId.value
              : this.celebracaoId,
      musicaId: data.musicaId.present ? data.musicaId.value : this.musicaId,
      ordem: data.ordem.present ? data.ordem.value : this.ordem,
      momentoLiturgico:
          data.momentoLiturgico.present
              ? data.momentoLiturgico.value
              : this.momentoLiturgico,
      observacao:
          data.observacao.present ? data.observacao.value : this.observacao,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItensCelebracaoLocalData(')
          ..write('id: $id, ')
          ..write('celebracaoId: $celebracaoId, ')
          ..write('musicaId: $musicaId, ')
          ..write('ordem: $ordem, ')
          ..write('momentoLiturgico: $momentoLiturgico, ')
          ..write('observacao: $observacao')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    celebracaoId,
    musicaId,
    ordem,
    momentoLiturgico,
    observacao,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItensCelebracaoLocalData &&
          other.id == this.id &&
          other.celebracaoId == this.celebracaoId &&
          other.musicaId == this.musicaId &&
          other.ordem == this.ordem &&
          other.momentoLiturgico == this.momentoLiturgico &&
          other.observacao == this.observacao);
}

class ItensCelebracaoLocalCompanion
    extends UpdateCompanion<ItensCelebracaoLocalData> {
  final Value<String> id;
  final Value<String> celebracaoId;
  final Value<String?> musicaId;
  final Value<int> ordem;
  final Value<String> momentoLiturgico;
  final Value<String?> observacao;
  final Value<int> rowid;
  const ItensCelebracaoLocalCompanion({
    this.id = const Value.absent(),
    this.celebracaoId = const Value.absent(),
    this.musicaId = const Value.absent(),
    this.ordem = const Value.absent(),
    this.momentoLiturgico = const Value.absent(),
    this.observacao = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItensCelebracaoLocalCompanion.insert({
    required String id,
    required String celebracaoId,
    this.musicaId = const Value.absent(),
    required int ordem,
    required String momentoLiturgico,
    this.observacao = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       celebracaoId = Value(celebracaoId),
       ordem = Value(ordem),
       momentoLiturgico = Value(momentoLiturgico);
  static Insertable<ItensCelebracaoLocalData> custom({
    Expression<String>? id,
    Expression<String>? celebracaoId,
    Expression<String>? musicaId,
    Expression<int>? ordem,
    Expression<String>? momentoLiturgico,
    Expression<String>? observacao,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (celebracaoId != null) 'celebracao_id': celebracaoId,
      if (musicaId != null) 'musica_id': musicaId,
      if (ordem != null) 'ordem': ordem,
      if (momentoLiturgico != null) 'momento_liturgico': momentoLiturgico,
      if (observacao != null) 'observacao': observacao,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItensCelebracaoLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? celebracaoId,
    Value<String?>? musicaId,
    Value<int>? ordem,
    Value<String>? momentoLiturgico,
    Value<String?>? observacao,
    Value<int>? rowid,
  }) {
    return ItensCelebracaoLocalCompanion(
      id: id ?? this.id,
      celebracaoId: celebracaoId ?? this.celebracaoId,
      musicaId: musicaId ?? this.musicaId,
      ordem: ordem ?? this.ordem,
      momentoLiturgico: momentoLiturgico ?? this.momentoLiturgico,
      observacao: observacao ?? this.observacao,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (celebracaoId.present) {
      map['celebracao_id'] = Variable<String>(celebracaoId.value);
    }
    if (musicaId.present) {
      map['musica_id'] = Variable<String>(musicaId.value);
    }
    if (ordem.present) {
      map['ordem'] = Variable<int>(ordem.value);
    }
    if (momentoLiturgico.present) {
      map['momento_liturgico'] = Variable<String>(momentoLiturgico.value);
    }
    if (observacao.present) {
      map['observacao'] = Variable<String>(observacao.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItensCelebracaoLocalCompanion(')
          ..write('id: $id, ')
          ..write('celebracaoId: $celebracaoId, ')
          ..write('musicaId: $musicaId, ')
          ..write('ordem: $ordem, ')
          ..write('momentoLiturgico: $momentoLiturgico, ')
          ..write('observacao: $observacao, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersLocalTable usersLocal = $UsersLocalTable(this);
  late final $GruposLocalTable gruposLocal = $GruposLocalTable(this);
  late final $MusicasLocalTable musicasLocal = $MusicasLocalTable(this);
  late final $SyncStatusLocalTable syncStatusLocal = $SyncStatusLocalTable(
    this,
  );
  late final $CelebracoesLocalTable celebracoesLocal = $CelebracoesLocalTable(
    this,
  );
  late final $ItensCelebracaoLocalTable itensCelebracaoLocal =
      $ItensCelebracaoLocalTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usersLocal,
    gruposLocal,
    musicasLocal,
    syncStatusLocal,
    celebracoesLocal,
    itensCelebracaoLocal,
  ];
}

typedef $$UsersLocalTableCreateCompanionBuilder =
    UsersLocalCompanion Function({
      required String id,
      required String nome,
      required String email,
      Value<String?> foto,
      Value<String> papel,
      Value<int> rowid,
    });
typedef $$UsersLocalTableUpdateCompanionBuilder =
    UsersLocalCompanion Function({
      Value<String> id,
      Value<String> nome,
      Value<String> email,
      Value<String?> foto,
      Value<String> papel,
      Value<int> rowid,
    });

class $$UsersLocalTableFilterComposer
    extends Composer<_$AppDatabase, $UsersLocalTable> {
  $$UsersLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foto => $composableBuilder(
    column: $table.foto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get papel => $composableBuilder(
    column: $table.papel,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersLocalTable> {
  $$UsersLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foto => $composableBuilder(
    column: $table.foto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get papel => $composableBuilder(
    column: $table.papel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersLocalTable> {
  $$UsersLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get foto =>
      $composableBuilder(column: $table.foto, builder: (column) => column);

  GeneratedColumn<String> get papel =>
      $composableBuilder(column: $table.papel, builder: (column) => column);
}

class $$UsersLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersLocalTable,
          UsersLocalData,
          $$UsersLocalTableFilterComposer,
          $$UsersLocalTableOrderingComposer,
          $$UsersLocalTableAnnotationComposer,
          $$UsersLocalTableCreateCompanionBuilder,
          $$UsersLocalTableUpdateCompanionBuilder,
          (
            UsersLocalData,
            BaseReferences<_$AppDatabase, $UsersLocalTable, UsersLocalData>,
          ),
          UsersLocalData,
          PrefetchHooks Function()
        > {
  $$UsersLocalTableTableManager(_$AppDatabase db, $UsersLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UsersLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UsersLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UsersLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> foto = const Value.absent(),
                Value<String> papel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersLocalCompanion(
                id: id,
                nome: nome,
                email: email,
                foto: foto,
                papel: papel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                required String email,
                Value<String?> foto = const Value.absent(),
                Value<String> papel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersLocalCompanion.insert(
                id: id,
                nome: nome,
                email: email,
                foto: foto,
                papel: papel,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersLocalTable,
      UsersLocalData,
      $$UsersLocalTableFilterComposer,
      $$UsersLocalTableOrderingComposer,
      $$UsersLocalTableAnnotationComposer,
      $$UsersLocalTableCreateCompanionBuilder,
      $$UsersLocalTableUpdateCompanionBuilder,
      (
        UsersLocalData,
        BaseReferences<_$AppDatabase, $UsersLocalTable, UsersLocalData>,
      ),
      UsersLocalData,
      PrefetchHooks Function()
    >;
typedef $$GruposLocalTableCreateCompanionBuilder =
    GruposLocalCompanion Function({
      required String id,
      required String nome,
      Value<String?> descricao,
      required String criadoPor,
      Value<String> meuPapel,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$GruposLocalTableUpdateCompanionBuilder =
    GruposLocalCompanion Function({
      Value<String> id,
      Value<String> nome,
      Value<String?> descricao,
      Value<String> criadoPor,
      Value<String> meuPapel,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$GruposLocalTableFilterComposer
    extends Composer<_$AppDatabase, $GruposLocalTable> {
  $$GruposLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criadoPor => $composableBuilder(
    column: $table.criadoPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meuPapel => $composableBuilder(
    column: $table.meuPapel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GruposLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $GruposLocalTable> {
  $$GruposLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criadoPor => $composableBuilder(
    column: $table.criadoPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meuPapel => $composableBuilder(
    column: $table.meuPapel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GruposLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $GruposLocalTable> {
  $$GruposLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<String> get criadoPor =>
      $composableBuilder(column: $table.criadoPor, builder: (column) => column);

  GeneratedColumn<String> get meuPapel =>
      $composableBuilder(column: $table.meuPapel, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GruposLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GruposLocalTable,
          GruposLocalData,
          $$GruposLocalTableFilterComposer,
          $$GruposLocalTableOrderingComposer,
          $$GruposLocalTableAnnotationComposer,
          $$GruposLocalTableCreateCompanionBuilder,
          $$GruposLocalTableUpdateCompanionBuilder,
          (
            GruposLocalData,
            BaseReferences<_$AppDatabase, $GruposLocalTable, GruposLocalData>,
          ),
          GruposLocalData,
          PrefetchHooks Function()
        > {
  $$GruposLocalTableTableManager(_$AppDatabase db, $GruposLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$GruposLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$GruposLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$GruposLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String?> descricao = const Value.absent(),
                Value<String> criadoPor = const Value.absent(),
                Value<String> meuPapel = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GruposLocalCompanion(
                id: id,
                nome: nome,
                descricao: descricao,
                criadoPor: criadoPor,
                meuPapel: meuPapel,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nome,
                Value<String?> descricao = const Value.absent(),
                required String criadoPor,
                Value<String> meuPapel = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => GruposLocalCompanion.insert(
                id: id,
                nome: nome,
                descricao: descricao,
                criadoPor: criadoPor,
                meuPapel: meuPapel,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GruposLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GruposLocalTable,
      GruposLocalData,
      $$GruposLocalTableFilterComposer,
      $$GruposLocalTableOrderingComposer,
      $$GruposLocalTableAnnotationComposer,
      $$GruposLocalTableCreateCompanionBuilder,
      $$GruposLocalTableUpdateCompanionBuilder,
      (
        GruposLocalData,
        BaseReferences<_$AppDatabase, $GruposLocalTable, GruposLocalData>,
      ),
      GruposLocalData,
      PrefetchHooks Function()
    >;
typedef $$MusicasLocalTableCreateCompanionBuilder =
    MusicasLocalCompanion Function({
      required String id,
      required String grupoId,
      required String titulo,
      Value<String?> tomOriginal,
      Value<int?> bpm,
      Value<String> categorias,
      required String conteudoRaw,
      required String conteudoJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MusicasLocalTableUpdateCompanionBuilder =
    MusicasLocalCompanion Function({
      Value<String> id,
      Value<String> grupoId,
      Value<String> titulo,
      Value<String?> tomOriginal,
      Value<int?> bpm,
      Value<String> categorias,
      Value<String> conteudoRaw,
      Value<String> conteudoJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MusicasLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MusicasLocalTable> {
  $$MusicasLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grupoId => $composableBuilder(
    column: $table.grupoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tomOriginal => $composableBuilder(
    column: $table.tomOriginal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorias => $composableBuilder(
    column: $table.categorias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conteudoRaw => $composableBuilder(
    column: $table.conteudoRaw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conteudoJson => $composableBuilder(
    column: $table.conteudoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MusicasLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MusicasLocalTable> {
  $$MusicasLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grupoId => $composableBuilder(
    column: $table.grupoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tomOriginal => $composableBuilder(
    column: $table.tomOriginal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorias => $composableBuilder(
    column: $table.categorias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conteudoRaw => $composableBuilder(
    column: $table.conteudoRaw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conteudoJson => $composableBuilder(
    column: $table.conteudoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MusicasLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MusicasLocalTable> {
  $$MusicasLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get grupoId =>
      $composableBuilder(column: $table.grupoId, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<String> get tomOriginal => $composableBuilder(
    column: $table.tomOriginal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<String> get categorias => $composableBuilder(
    column: $table.categorias,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conteudoRaw => $composableBuilder(
    column: $table.conteudoRaw,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conteudoJson => $composableBuilder(
    column: $table.conteudoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MusicasLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MusicasLocalTable,
          MusicasLocalData,
          $$MusicasLocalTableFilterComposer,
          $$MusicasLocalTableOrderingComposer,
          $$MusicasLocalTableAnnotationComposer,
          $$MusicasLocalTableCreateCompanionBuilder,
          $$MusicasLocalTableUpdateCompanionBuilder,
          (
            MusicasLocalData,
            BaseReferences<_$AppDatabase, $MusicasLocalTable, MusicasLocalData>,
          ),
          MusicasLocalData,
          PrefetchHooks Function()
        > {
  $$MusicasLocalTableTableManager(_$AppDatabase db, $MusicasLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MusicasLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$MusicasLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$MusicasLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> grupoId = const Value.absent(),
                Value<String> titulo = const Value.absent(),
                Value<String?> tomOriginal = const Value.absent(),
                Value<int?> bpm = const Value.absent(),
                Value<String> categorias = const Value.absent(),
                Value<String> conteudoRaw = const Value.absent(),
                Value<String> conteudoJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MusicasLocalCompanion(
                id: id,
                grupoId: grupoId,
                titulo: titulo,
                tomOriginal: tomOriginal,
                bpm: bpm,
                categorias: categorias,
                conteudoRaw: conteudoRaw,
                conteudoJson: conteudoJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String grupoId,
                required String titulo,
                Value<String?> tomOriginal = const Value.absent(),
                Value<int?> bpm = const Value.absent(),
                Value<String> categorias = const Value.absent(),
                required String conteudoRaw,
                required String conteudoJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MusicasLocalCompanion.insert(
                id: id,
                grupoId: grupoId,
                titulo: titulo,
                tomOriginal: tomOriginal,
                bpm: bpm,
                categorias: categorias,
                conteudoRaw: conteudoRaw,
                conteudoJson: conteudoJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MusicasLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MusicasLocalTable,
      MusicasLocalData,
      $$MusicasLocalTableFilterComposer,
      $$MusicasLocalTableOrderingComposer,
      $$MusicasLocalTableAnnotationComposer,
      $$MusicasLocalTableCreateCompanionBuilder,
      $$MusicasLocalTableUpdateCompanionBuilder,
      (
        MusicasLocalData,
        BaseReferences<_$AppDatabase, $MusicasLocalTable, MusicasLocalData>,
      ),
      MusicasLocalData,
      PrefetchHooks Function()
    >;
typedef $$SyncStatusLocalTableCreateCompanionBuilder =
    SyncStatusLocalCompanion Function({
      required String grupoId,
      Value<DateTime?> musicasSincronizadoEm,
      Value<int> rowid,
    });
typedef $$SyncStatusLocalTableUpdateCompanionBuilder =
    SyncStatusLocalCompanion Function({
      Value<String> grupoId,
      Value<DateTime?> musicasSincronizadoEm,
      Value<int> rowid,
    });

class $$SyncStatusLocalTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatusLocalTable> {
  $$SyncStatusLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get grupoId => $composableBuilder(
    column: $table.grupoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get musicasSincronizadoEm => $composableBuilder(
    column: $table.musicasSincronizadoEm,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatusLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatusLocalTable> {
  $$SyncStatusLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get grupoId => $composableBuilder(
    column: $table.grupoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get musicasSincronizadoEm => $composableBuilder(
    column: $table.musicasSincronizadoEm,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatusLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatusLocalTable> {
  $$SyncStatusLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get grupoId =>
      $composableBuilder(column: $table.grupoId, builder: (column) => column);

  GeneratedColumn<DateTime> get musicasSincronizadoEm => $composableBuilder(
    column: $table.musicasSincronizadoEm,
    builder: (column) => column,
  );
}

class $$SyncStatusLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatusLocalTable,
          SyncStatusLocalData,
          $$SyncStatusLocalTableFilterComposer,
          $$SyncStatusLocalTableOrderingComposer,
          $$SyncStatusLocalTableAnnotationComposer,
          $$SyncStatusLocalTableCreateCompanionBuilder,
          $$SyncStatusLocalTableUpdateCompanionBuilder,
          (
            SyncStatusLocalData,
            BaseReferences<
              _$AppDatabase,
              $SyncStatusLocalTable,
              SyncStatusLocalData
            >,
          ),
          SyncStatusLocalData,
          PrefetchHooks Function()
        > {
  $$SyncStatusLocalTableTableManager(
    _$AppDatabase db,
    $SyncStatusLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$SyncStatusLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SyncStatusLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$SyncStatusLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> grupoId = const Value.absent(),
                Value<DateTime?> musicasSincronizadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatusLocalCompanion(
                grupoId: grupoId,
                musicasSincronizadoEm: musicasSincronizadoEm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String grupoId,
                Value<DateTime?> musicasSincronizadoEm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatusLocalCompanion.insert(
                grupoId: grupoId,
                musicasSincronizadoEm: musicasSincronizadoEm,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatusLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatusLocalTable,
      SyncStatusLocalData,
      $$SyncStatusLocalTableFilterComposer,
      $$SyncStatusLocalTableOrderingComposer,
      $$SyncStatusLocalTableAnnotationComposer,
      $$SyncStatusLocalTableCreateCompanionBuilder,
      $$SyncStatusLocalTableUpdateCompanionBuilder,
      (
        SyncStatusLocalData,
        BaseReferences<
          _$AppDatabase,
          $SyncStatusLocalTable,
          SyncStatusLocalData
        >,
      ),
      SyncStatusLocalData,
      PrefetchHooks Function()
    >;
typedef $$CelebracoesLocalTableCreateCompanionBuilder =
    CelebracoesLocalCompanion Function({
      required String id,
      required String grupoId,
      required String titulo,
      required DateTime dataHora,
      required String criadoPor,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CelebracoesLocalTableUpdateCompanionBuilder =
    CelebracoesLocalCompanion Function({
      Value<String> id,
      Value<String> grupoId,
      Value<String> titulo,
      Value<DateTime> dataHora,
      Value<String> criadoPor,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CelebracoesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $CelebracoesLocalTable> {
  $$CelebracoesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grupoId => $composableBuilder(
    column: $table.grupoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataHora => $composableBuilder(
    column: $table.dataHora,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criadoPor => $composableBuilder(
    column: $table.criadoPor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CelebracoesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $CelebracoesLocalTable> {
  $$CelebracoesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grupoId => $composableBuilder(
    column: $table.grupoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titulo => $composableBuilder(
    column: $table.titulo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataHora => $composableBuilder(
    column: $table.dataHora,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criadoPor => $composableBuilder(
    column: $table.criadoPor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CelebracoesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $CelebracoesLocalTable> {
  $$CelebracoesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get grupoId =>
      $composableBuilder(column: $table.grupoId, builder: (column) => column);

  GeneratedColumn<String> get titulo =>
      $composableBuilder(column: $table.titulo, builder: (column) => column);

  GeneratedColumn<DateTime> get dataHora =>
      $composableBuilder(column: $table.dataHora, builder: (column) => column);

  GeneratedColumn<String> get criadoPor =>
      $composableBuilder(column: $table.criadoPor, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CelebracoesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CelebracoesLocalTable,
          CelebracoesLocalData,
          $$CelebracoesLocalTableFilterComposer,
          $$CelebracoesLocalTableOrderingComposer,
          $$CelebracoesLocalTableAnnotationComposer,
          $$CelebracoesLocalTableCreateCompanionBuilder,
          $$CelebracoesLocalTableUpdateCompanionBuilder,
          (
            CelebracoesLocalData,
            BaseReferences<
              _$AppDatabase,
              $CelebracoesLocalTable,
              CelebracoesLocalData
            >,
          ),
          CelebracoesLocalData,
          PrefetchHooks Function()
        > {
  $$CelebracoesLocalTableTableManager(
    _$AppDatabase db,
    $CelebracoesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$CelebracoesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CelebracoesLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CelebracoesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> grupoId = const Value.absent(),
                Value<String> titulo = const Value.absent(),
                Value<DateTime> dataHora = const Value.absent(),
                Value<String> criadoPor = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CelebracoesLocalCompanion(
                id: id,
                grupoId: grupoId,
                titulo: titulo,
                dataHora: dataHora,
                criadoPor: criadoPor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String grupoId,
                required String titulo,
                required DateTime dataHora,
                required String criadoPor,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CelebracoesLocalCompanion.insert(
                id: id,
                grupoId: grupoId,
                titulo: titulo,
                dataHora: dataHora,
                criadoPor: criadoPor,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CelebracoesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CelebracoesLocalTable,
      CelebracoesLocalData,
      $$CelebracoesLocalTableFilterComposer,
      $$CelebracoesLocalTableOrderingComposer,
      $$CelebracoesLocalTableAnnotationComposer,
      $$CelebracoesLocalTableCreateCompanionBuilder,
      $$CelebracoesLocalTableUpdateCompanionBuilder,
      (
        CelebracoesLocalData,
        BaseReferences<
          _$AppDatabase,
          $CelebracoesLocalTable,
          CelebracoesLocalData
        >,
      ),
      CelebracoesLocalData,
      PrefetchHooks Function()
    >;
typedef $$ItensCelebracaoLocalTableCreateCompanionBuilder =
    ItensCelebracaoLocalCompanion Function({
      required String id,
      required String celebracaoId,
      Value<String?> musicaId,
      required int ordem,
      required String momentoLiturgico,
      Value<String?> observacao,
      Value<int> rowid,
    });
typedef $$ItensCelebracaoLocalTableUpdateCompanionBuilder =
    ItensCelebracaoLocalCompanion Function({
      Value<String> id,
      Value<String> celebracaoId,
      Value<String?> musicaId,
      Value<int> ordem,
      Value<String> momentoLiturgico,
      Value<String?> observacao,
      Value<int> rowid,
    });

class $$ItensCelebracaoLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ItensCelebracaoLocalTable> {
  $$ItensCelebracaoLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get celebracaoId => $composableBuilder(
    column: $table.celebracaoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicaId => $composableBuilder(
    column: $table.musicaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get momentoLiturgico => $composableBuilder(
    column: $table.momentoLiturgico,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observacao => $composableBuilder(
    column: $table.observacao,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ItensCelebracaoLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ItensCelebracaoLocalTable> {
  $$ItensCelebracaoLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get celebracaoId => $composableBuilder(
    column: $table.celebracaoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicaId => $composableBuilder(
    column: $table.musicaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordem => $composableBuilder(
    column: $table.ordem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get momentoLiturgico => $composableBuilder(
    column: $table.momentoLiturgico,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observacao => $composableBuilder(
    column: $table.observacao,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ItensCelebracaoLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItensCelebracaoLocalTable> {
  $$ItensCelebracaoLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get celebracaoId => $composableBuilder(
    column: $table.celebracaoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get musicaId =>
      $composableBuilder(column: $table.musicaId, builder: (column) => column);

  GeneratedColumn<int> get ordem =>
      $composableBuilder(column: $table.ordem, builder: (column) => column);

  GeneratedColumn<String> get momentoLiturgico => $composableBuilder(
    column: $table.momentoLiturgico,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observacao => $composableBuilder(
    column: $table.observacao,
    builder: (column) => column,
  );
}

class $$ItensCelebracaoLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItensCelebracaoLocalTable,
          ItensCelebracaoLocalData,
          $$ItensCelebracaoLocalTableFilterComposer,
          $$ItensCelebracaoLocalTableOrderingComposer,
          $$ItensCelebracaoLocalTableAnnotationComposer,
          $$ItensCelebracaoLocalTableCreateCompanionBuilder,
          $$ItensCelebracaoLocalTableUpdateCompanionBuilder,
          (
            ItensCelebracaoLocalData,
            BaseReferences<
              _$AppDatabase,
              $ItensCelebracaoLocalTable,
              ItensCelebracaoLocalData
            >,
          ),
          ItensCelebracaoLocalData,
          PrefetchHooks Function()
        > {
  $$ItensCelebracaoLocalTableTableManager(
    _$AppDatabase db,
    $ItensCelebracaoLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ItensCelebracaoLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ItensCelebracaoLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ItensCelebracaoLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> celebracaoId = const Value.absent(),
                Value<String?> musicaId = const Value.absent(),
                Value<int> ordem = const Value.absent(),
                Value<String> momentoLiturgico = const Value.absent(),
                Value<String?> observacao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItensCelebracaoLocalCompanion(
                id: id,
                celebracaoId: celebracaoId,
                musicaId: musicaId,
                ordem: ordem,
                momentoLiturgico: momentoLiturgico,
                observacao: observacao,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String celebracaoId,
                Value<String?> musicaId = const Value.absent(),
                required int ordem,
                required String momentoLiturgico,
                Value<String?> observacao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItensCelebracaoLocalCompanion.insert(
                id: id,
                celebracaoId: celebracaoId,
                musicaId: musicaId,
                ordem: ordem,
                momentoLiturgico: momentoLiturgico,
                observacao: observacao,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ItensCelebracaoLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItensCelebracaoLocalTable,
      ItensCelebracaoLocalData,
      $$ItensCelebracaoLocalTableFilterComposer,
      $$ItensCelebracaoLocalTableOrderingComposer,
      $$ItensCelebracaoLocalTableAnnotationComposer,
      $$ItensCelebracaoLocalTableCreateCompanionBuilder,
      $$ItensCelebracaoLocalTableUpdateCompanionBuilder,
      (
        ItensCelebracaoLocalData,
        BaseReferences<
          _$AppDatabase,
          $ItensCelebracaoLocalTable,
          ItensCelebracaoLocalData
        >,
      ),
      ItensCelebracaoLocalData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersLocalTableTableManager get usersLocal =>
      $$UsersLocalTableTableManager(_db, _db.usersLocal);
  $$GruposLocalTableTableManager get gruposLocal =>
      $$GruposLocalTableTableManager(_db, _db.gruposLocal);
  $$MusicasLocalTableTableManager get musicasLocal =>
      $$MusicasLocalTableTableManager(_db, _db.musicasLocal);
  $$SyncStatusLocalTableTableManager get syncStatusLocal =>
      $$SyncStatusLocalTableTableManager(_db, _db.syncStatusLocal);
  $$CelebracoesLocalTableTableManager get celebracoesLocal =>
      $$CelebracoesLocalTableTableManager(_db, _db.celebracoesLocal);
  $$ItensCelebracaoLocalTableTableManager get itensCelebracaoLocal =>
      $$ItensCelebracaoLocalTableTableManager(_db, _db.itensCelebracaoLocal);
}
