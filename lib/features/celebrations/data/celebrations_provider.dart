import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../auth/presentation/auth_provider.dart';

class CelebracoesService {
  final Ref _ref;

  CelebracoesService(this._ref);

  AppDatabase get _db => _ref.read(databaseProvider);
  dynamic get _supabase => _ref.read(supabaseProvider);

  /// Download a group's celebrations and their liturgical items for offline use.
  Future<int> syncCelebracoes(String grupoId) async {
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

    await _db.transaction(() async {
      for (final row in celebrations) {
        final celebration = row as Map<String, dynamic>;
        await _db.upsertCelebracao(
          CelebracoesLocalCompanion.insert(
            id: celebration['id'] as String,
            grupoId: celebration['grupo_id'] as String,
            titulo: celebration['titulo'] as String,
            dataHora: DateTime.parse(celebration['data_hora'] as String),
            criadoPor: celebration['criado_por'] as String,
            updatedAt:
                DateTime.tryParse(celebration['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
        );
        await _db.deleteItensByCelebracao(celebration['id'] as String);
      }

      for (final row in items) {
        final item = row as Map<String, dynamic>;
        await _db.upsertItemCelebracao(
          ItensCelebracaoLocalCompanion.insert(
            id: item['id'] as String,
            celebracaoId: item['celebracao_id'] as String,
            musicaId: drift.Value(item['musica_id'] as String?),
            ordem: item['ordem'] as int,
            momentoLiturgico: item['momento_liturgico'] as String,
            observacao: drift.Value(item['observacao'] as String?),
          ),
        );
      }
    });

    return celebrations.length;
  }
}

final celebracoesServiceProvider = Provider<CelebracoesService>(
  (ref) => CelebracoesService(ref),
);
