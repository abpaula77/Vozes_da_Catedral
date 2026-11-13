import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/group_model.dart';

/// Stream of groups the current user belongs to (from local DB)
final gruposProvider = StreamProvider<List<GrupoModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchGrupos().map(
    (rows) =>
        rows
            .map(
              (r) => GrupoModel(
                id: r.id,
                nome: r.nome,
                descricao: r.descricao,
                criadoPor: r.criadoPor,
                meuPapel: PapelGrupo.fromString(r.meuPapel),
                updatedAt: r.updatedAt,
              ),
            )
            .toList(),
  );
});

final membrosGrupoProvider =
    FutureProvider.family<List<MembroGrupoModel>, String>((ref, grupoId) {
      return ref.watch(gruposServiceProvider).getMembros(grupoId);
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
    final normalizedDescription = descricao?.trim();
    final groupDescription =
        normalizedDescription == null || normalizedDescription.isEmpty
            ? null
            : normalizedDescription;

    final grupoId =
        await _supabase.rpc(
              'create_group',
              params: {'p_nome': nome.trim(), 'p_descricao': groupDescription},
            )
            as String;

    // Persist locally
    await _db.upsertGrupo(
      GruposLocalCompanion.insert(
        id: grupoId,
        nome: nome,
        descricao: drift.Value(groupDescription),
        criadoPor: userId,
        meuPapel: const drift.Value('coordenador'),
        updatedAt: DateTime.now(),
      ),
    );

    return grupoId;
  }

  /// Sync groups from Supabase to local DB for the current user
  Future<void> syncGrupos() async {
    final userId = _userId;
    if (userId == null) return;

    final rows =
        await _supabase
                .from('membros_grupo')
                .select('papel, grupos(*)')
                .eq('user_id', userId)
            as List<dynamic>;

    final syncedGroupIds = <String>{};
    for (final row in rows) {
      final grupo = row['grupos'] as Map<String, dynamic>;
      final grupoId = grupo['id'] as String;
      syncedGroupIds.add(grupoId);
      final papel = row['papel'] as String;
      await _db.upsertGrupo(
        GruposLocalCompanion.insert(
          id: grupoId,
          nome: grupo['nome'] as String,
          descricao: drift.Value(grupo['descricao'] as String?),
          criadoPor: grupo['criado_por'] as String,
          meuPapel: drift.Value(papel),
          updatedAt: DateTime.now(),
        ),
      );
    }

    final localGroups = await _db.getGrupos();
    for (final grupo in localGroups) {
      if (!syncedGroupIds.contains(grupo.id)) {
        await _db.deleteGrupo(grupo.id);
      }
    }
  }

  /// Fetch group members and their profiles.
  Future<List<MembroGrupoModel>> getMembros(String grupoId) async {
    final memberships =
        await _supabase
                .from('membros_grupo')
                .select('user_id, papel')
                .eq('grupo_id', grupoId)
                .order('created_at')
            as List<dynamic>;

    if (memberships.isEmpty) return [];

    final userIds =
        memberships
            .map((row) => (row as Map<String, dynamic>)['user_id'] as String)
            .toList();
    final profiles =
        await _supabase.from('users').select('id, nome').inFilter('id', userIds)
            as List<dynamic>;
    final profilesById = {
      for (final profile in profiles)
        (profile as Map<String, dynamic>)['id'] as String: profile,
    };

    return memberships.map((row) {
      final membership = row as Map<String, dynamic>;
      final userId = membership['user_id'] as String;
      final profile = profilesById[userId];
      if (profile == null) {
        throw StateError('Perfil não encontrado para o membro $userId.');
      }
      return MembroGrupoModel(
        userId: userId,
        nome: profile['nome'] as String,
        papel: PapelGrupo.fromString(membership['papel'] as String),
      );
    }).toList();
  }

  /// Add a member to a group by exact email (Coordenador only).
  /// The RPC does not reveal whether the email belongs to a registered user.
  Future<void> addMembro({
    required String grupoId,
    required String email,
    String papel = 'membro',
  }) async {
    await _supabase.rpc(
      'add_group_member_by_email',
      params: {
        'p_grupo_id': grupoId,
        'p_email': email.trim(),
        'p_papel': papel,
      },
    );
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
