import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_provider.dart';
import '../domain/solicitacao_model.dart';

/// Group join requests (issue #41). Online only: every call goes to a
/// Supabase RPC, which enforces all rules (see the spec design).
class SolicitacoesService {
  final Ref _ref;
  SolicitacoesService(this._ref);

  SupabaseClient get _supabase => _ref.read(supabaseProvider);

  // ── Requester ────────────────────────────────────────────────────────────

  Future<List<GrupoAbertoModel>> listarGruposAbertos() async {
    final rows = await _supabase.rpc('listar_grupos_abertos') as List<dynamic>;
    return rows
        .map((row) => GrupoAbertoModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<MinhaSolicitacaoModel>> listarMinhasSolicitacoes() async {
    final rows =
        await _supabase.rpc('listar_minhas_solicitacoes') as List<dynamic>;
    return rows
        .map(
          (row) => MinhaSolicitacaoModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> solicitarEntrada({
    required String grupoId,
    String? mensagem,
  }) async {
    final texto = mensagem?.trim();
    await _supabase.rpc(
      'solicitar_entrada',
      params: {
        'p_grupo_id': grupoId,
        'p_mensagem': texto == null || texto.isEmpty ? null : texto,
      },
    );
  }

  Future<void> cancelarSolicitacao(String solicitacaoId) async {
    await _supabase.rpc(
      'cancelar_solicitacao',
      params: {'p_solicitacao_id': solicitacaoId},
    );
  }

  // ── Coordinator ──────────────────────────────────────────────────────────

  Future<bool> obterAceitaSolicitacoes(String grupoId) async {
    final value = await _supabase.rpc(
      'obter_aceita_solicitacoes',
      params: {'p_grupo_id': grupoId},
    );
    return value == true;
  }

  Future<void> definirAceitaSolicitacoes({
    required String grupoId,
    required bool aceita,
  }) async {
    await _supabase.rpc(
      'definir_aceita_solicitacoes',
      params: {'p_grupo_id': grupoId, 'p_aceita': aceita},
    );
  }

  Future<List<SolicitacaoPendenteModel>> listarPendentes(String grupoId) async {
    final rows =
        await _supabase.rpc(
              'listar_solicitacoes_pendentes',
              params: {'p_grupo_id': grupoId},
            )
            as List<dynamic>;
    return rows
        .map(
          (row) =>
              SolicitacaoPendenteModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// Pending requests per group the current user coordinates.
  Future<Map<String, int>> contarPendentes() async {
    final rows =
        await _supabase.rpc('contar_solicitacoes_pendentes') as List<dynamic>;
    return {
      for (final row in rows.cast<Map<String, dynamic>>())
        row['grupo_id'] as String: (row['total'] as num).toInt(),
    };
  }

  Future<void> decidir({
    required String solicitacaoId,
    required bool aprovar,
  }) async {
    await _supabase.rpc(
      'decidir_solicitacao',
      params: {'p_solicitacao_id': solicitacaoId, 'p_aprovar': aprovar},
    );
  }
}

final solicitacoesServiceProvider = Provider<SolicitacoesService>(
  SolicitacoesService.new,
);

final gruposAbertosProvider =
    FutureProvider.autoDispose<List<GrupoAbertoModel>>(
      (ref) => ref.watch(solicitacoesServiceProvider).listarGruposAbertos(),
    );

final minhasSolicitacoesProvider = FutureProvider.autoDispose<
  List<MinhaSolicitacaoModel>
>((ref) => ref.watch(solicitacoesServiceProvider).listarMinhasSolicitacoes());

final solicitacoesPendentesProvider = FutureProvider.autoDispose
    .family<List<SolicitacaoPendenteModel>, String>(
      (ref, grupoId) =>
          ref.watch(solicitacoesServiceProvider).listarPendentes(grupoId),
    );

final contagemSolicitacoesProvider =
    FutureProvider.autoDispose<Map<String, int>>(
      (ref) => ref.watch(solicitacoesServiceProvider).contarPendentes(),
    );

final aceitaSolicitacoesProvider = FutureProvider.autoDispose
    .family<bool, String>(
      (ref, grupoId) => ref
          .watch(solicitacoesServiceProvider)
          .obterAceitaSolicitacoes(grupoId),
    );

/// Turns an error from this flow into a message for the user.
///
/// The RPCs raise messages written for end users (e.g. "Você já tem uma
/// solicitação pendente para este grupo."), so they are shown as-is. Any other
/// error is most likely a network failure, since the flow is online only.
String mensagemErroSolicitacao(Object error) {
  if (error is PostgrestException && error.message.trim().isNotEmpty) {
    return error.message;
  }
  return 'Não foi possível concluir. Esta função precisa de internet; '
      'verifique a conexão e tente novamente.';
}
