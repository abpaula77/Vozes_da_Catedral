import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/group_model.dart';

/// Stream of groups the current user belongs to (from local DB)
final gruposProvider = StreamProvider<List<GrupoModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchGrupos().map((rows) => rows
      .map((r) => GrupoModel(
            id: r.id,
            nome: r.nome,
            descricao: r.descricao,
            criadoPor: r.criadoPor,
            meuPapel: PapelGrupo.fromString(r.meuPapel),
            updatedAt: r.updatedAt,
          ))
      .toList());
});

/// Service for group CRUD and sync operations
class GruposService {
  final Ref _ref;
  GruposService(this._ref);

  AppDatabase get _db => _ref.read(databaseProvider);
  dynamic get _supabase => _ref.read(supabaseProvider);
  String? get _userId => _ref.read(currentUserIdProvider);

  /// Create a new group (Coordenador only)
  Future<String> createGrupo({required String nome, String? descricao}) async {
    final userId = _userId;
    if (userId == null) throw Exception('Usuário não autenticado');

    final result = await (_supabase.from('grupos').insert({
      'nome': nome,
      'descricao': descricao,
      'criado_por': userId,
    }).select().single()) as Map<String, dynamic>;

    // Add creator as coordenador in membros_grupo
    await _supabase.from('membros_grupo').insert({
      'grupo_id': result['id'],
      'user_id': userId,
      'papel': 'coordenador',
    });

    // Persist locally
    await _db.upsertGrupo(GruposLocalCompanion.insert(
      id: result['id'] as String,
      nome: nome,
      descricao: drift.Value(descricao),
      criadoPor: userId,
      meuPapel: const drift.Value('coordenador'),
      updatedAt: DateTime.now(),
    ));

    return result['id'] as String;
  }

  /// Sync groups from Supabase to local DB for the current user
  Future<void> syncGrupos() async {
    final userId = _userId;
    if (userId == null) return;

    final rows = await _supabase
        .from('membros_grupo')
        .select('papel, grupos(*)')
        .eq('user_id', userId) as List<dynamic>;

    for (final row in rows) {
      final grupo = row['grupos'] as Map<String, dynamic>;
      final papel = row['papel'] as String;
      await _db.upsertGrupo(GruposLocalCompanion.insert(
        id: grupo['id'] as String,
        nome: grupo['nome'] as String,
        descricao: drift.Value(grupo['descricao'] as String?),
        criadoPor: grupo['criado_por'] as String,
        meuPapel: drift.Value(papel),
        updatedAt: DateTime.now(),
      ));
    }
  }

  /// Add a member to a group by email (Coordenador only)
  Future<void> addMembro({
    required String grupoId,
    required String email,
    String papel = 'membro',
  }) async {
    final user = await _supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .maybeSingle() as Map<String, dynamic>?;

    if (user == null) throw Exception('Usuário não encontrado com esse e-mail.');

    await _supabase.from('membros_grupo').upsert({
      'grupo_id': grupoId,
      'user_id': user['id'],
      'papel': papel,
    });
  }

  /// Remove a member from a group (Coordenador only)
  Future<void> removeMembro({
    required String grupoId,
    required String userId,
  }) async {
    await _supabase
        .from('membros_grupo')
        .delete()
        .eq('grupo_id', grupoId)
        .eq('user_id', userId);
  }
}

final gruposServiceProvider = Provider<GruposService>((ref) {
  return GruposService(ref);
});
