import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/user_avatar.dart';
import '../data/groups_provider.dart';
import '../data/solicitacoes_provider.dart';
import '../domain/solicitacao_model.dart';

/// Coordinator switch that opens or closes the group to join requests
/// (issue #41, requirement 1). Shown on the members screen.
class AceitaSolicitacoesSwitch extends ConsumerStatefulWidget {
  final String grupoId;

  const AceitaSolicitacoesSwitch({super.key, required this.grupoId});

  @override
  ConsumerState<AceitaSolicitacoesSwitch> createState() =>
      _AceitaSolicitacoesSwitchState();
}

class _AceitaSolicitacoesSwitchState
    extends ConsumerState<AceitaSolicitacoesSwitch> {
  bool _salvando = false;

  Future<void> _alterar(bool aceita) async {
    setState(() => _salvando = true);
    try {
      await ref
          .read(solicitacoesServiceProvider)
          .definirAceitaSolicitacoes(grupoId: widget.grupoId, aceita: aceita);
      ref.invalidate(aceitaSolicitacoesProvider(widget.grupoId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aceita
                  ? 'O grupo agora aparece em Encontrar grupos.'
                  : 'O grupo não aparece mais em Encontrar grupos. '
                      'As solicitações pendentes continuam aqui.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagemErroSolicitacao(error))));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aceita = ref.watch(aceitaSolicitacoesProvider(widget.grupoId));

    return Card(
      child: aceita.when(
        loading:
            () => const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Aceitar solicitações de entrada'),
            ),
        error:
            (error, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Aceitar solicitações de entrada'),
              subtitle: Text(mensagemErroSolicitacao(error)),
              trailing: TextButton(
                onPressed:
                    () => ref.invalidate(
                      aceitaSolicitacoesProvider(widget.grupoId),
                    ),
                child: const Text('Tentar novamente'),
              ),
            ),
        data:
            (valor) => SwitchListTile(
              secondary: const Icon(Icons.how_to_reg_outlined),
              title: const Text('Aceitar solicitações de entrada'),
              subtitle: const Text(
                'Quando ligado, o grupo aparece em Encontrar grupos.',
              ),
              value: valor,
              onChanged: _salvando ? null : _alterar,
            ),
      ),
    );
  }
}

/// Coordinator list of pending join requests (issue #41, requirement 5).
/// Renders nothing while there are no pending requests.
class SolicitacoesPendentesSection extends ConsumerWidget {
  final String grupoId;

  const SolicitacoesPendentesSection({super.key, required this.grupoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendentes = ref.watch(solicitacoesPendentesProvider(grupoId));

    return pendentes.when(
      loading: () => const SizedBox.shrink(),
      error:
          (error, _) => Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Não foi possível carregar as solicitações'),
              subtitle: Text(mensagemErroSolicitacao(error)),
              trailing: TextButton(
                onPressed:
                    () =>
                        ref.invalidate(solicitacoesPendentesProvider(grupoId)),
                child: const Text('Tentar novamente'),
              ),
            ),
          ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Solicitações pendentes (${items.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final (index, solicitacao) in items.indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  _SolicitacaoPendenteTile(
                    grupoId: grupoId,
                    solicitacao: solicitacao,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SolicitacaoPendenteTile extends ConsumerStatefulWidget {
  final String grupoId;
  final SolicitacaoPendenteModel solicitacao;

  const _SolicitacaoPendenteTile({
    required this.grupoId,
    required this.solicitacao,
  });

  @override
  ConsumerState<_SolicitacaoPendenteTile> createState() =>
      _SolicitacaoPendenteTileState();
}

class _SolicitacaoPendenteTileState
    extends ConsumerState<_SolicitacaoPendenteTile> {
  bool _decidindo = false;

  void _recarregar() {
    ref.invalidate(solicitacoesPendentesProvider(widget.grupoId));
    ref.invalidate(membrosGrupoProvider(widget.grupoId));
    ref.invalidate(contagemSolicitacoesProvider);
  }

  Future<void> _decidir({required bool aprovar}) async {
    final nome = widget.solicitacao.nome;
    if (!aprovar) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Recusar solicitação?'),
              content: Text(
                '$nome só poderá pedir para entrar de novo daqui a 7 dias.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Voltar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Recusar'),
                ),
              ],
            ),
      );
      if (confirmado != true || !mounted) return;
    }

    setState(() => _decidindo = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(solicitacoesServiceProvider)
          .decidir(solicitacaoId: widget.solicitacao.id, aprovar: aprovar);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            aprovar
                ? '$nome agora é membro do grupo.'
                : 'Solicitação de $nome recusada.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(mensagemErroSolicitacao(error))),
      );
    } finally {
      // Reload in both cases: after an error the request may already have
      // been decided by another coordinator.
      if (mounted) {
        _recarregar();
        setState(() => _decidindo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitacao = widget.solicitacao;
    final theme = Theme.of(context);
    final foto = solicitacao.foto;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Handles both Google and uploaded photos (issue #42).
              UserAvatar(nome: solicitacao.nome, foto: foto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(solicitacao.nome, style: theme.textTheme.titleSmall),
                    Text(
                      'Pediu em ${formatarData(solicitacao.criadaEm)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (solicitacao.mensagem case final mensagem?) ...[
            const SizedBox(height: 8),
            Text('"$mensagem"', style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: _decidindo ? null : () => _decidir(aprovar: false),
                child: const Text('Recusar'),
              ),
              FilledButton(
                onPressed: _decidindo ? null : () => _decidir(aprovar: true),
                child: const Text('Aprovar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
