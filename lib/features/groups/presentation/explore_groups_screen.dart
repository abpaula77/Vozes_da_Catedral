import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/groups_provider.dart';
import '../data/solicitacoes_provider.dart';
import '../domain/solicitacao_model.dart';

/// "Encontrar grupos": open groups the user can ask to join, plus the user's
/// own requests (issue #41, requirements 2, 3 and 4). Online only.
class ExploreGroupsScreen extends ConsumerStatefulWidget {
  const ExploreGroupsScreen({super.key});

  @override
  ConsumerState<ExploreGroupsScreen> createState() =>
      _ExploreGroupsScreenState();
}

class _ExploreGroupsScreenState extends ConsumerState<ExploreGroupsScreen> {
  final _filtroController = TextEditingController();
  String _filtro = '';
  bool _sincronizouAprovados = false;

  @override
  void dispose() {
    _filtroController.dispose();
    super.dispose();
  }

  void _recarregar() {
    ref.invalidate(gruposAbertosProvider);
    ref.invalidate(minhasSolicitacoesProvider);
  }

  /// When a request was approved, sync groups so the new group shows up in
  /// "Meus Grupos" right away (requirement 4.3).
  void _sincronizarSeAprovado(List<MinhaSolicitacaoModel> solicitacoes) {
    if (_sincronizouAprovados) return;
    if (!solicitacoes.any((s) => s.status == StatusSolicitacao.aprovada)) {
      return;
    }
    _sincronizouAprovados = true;
    ref.read(gruposServiceProvider).syncGrupos().catchError((_) {
      // "Meus Grupos" syncs again when opened; nothing to show here.
    });
  }

  Future<void> _solicitar(GrupoAbertoModel grupo) async {
    final pedido = await showDialog<_Pedido>(
      context: context,
      builder: (_) => _SolicitarEntradaDialog(nomeGrupo: grupo.nome),
    );
    if (pedido == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(solicitacoesServiceProvider)
          .solicitarEntrada(grupoId: grupo.id, mensagem: pedido.mensagem);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitação enviada. Um coordenador do grupo vai analisar o pedido.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(mensagemErroSolicitacao(error))),
      );
    } finally {
      if (mounted) _recarregar();
    }
  }

  Future<void> _cancelar(MinhaSolicitacaoModel solicitacao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Cancelar solicitação?'),
            content: Text(
              'Seu pedido para entrar em ${solicitacao.grupoNome} será '
              'retirado. Você pode pedir de novo quando quiser.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Cancelar pedido'),
              ),
            ],
          ),
    );
    if (confirmado != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(solicitacoesServiceProvider)
          .cancelarSolicitacao(solicitacao.id);
      messenger.showSnackBar(
        const SnackBar(content: Text('Solicitação cancelada.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(mensagemErroSolicitacao(error))),
      );
    } finally {
      if (mounted) _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grupos = ref.watch(gruposAbertosProvider);
    final minhas = ref.watch(minhasSolicitacoesProvider);
    ref.listen(minhasSolicitacoesProvider, (_, next) {
      next.whenData(_sincronizarSeAprovado);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encontrar grupos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _recarregar,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _recarregar();
          await ref
              .read(gruposAbertosProvider.future)
              .catchError((_) => <GrupoAbertoModel>[]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._minhasSolicitacoes(minhas),
            Text(
              'Grupos abertos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Grupos que estão aceitando novos membros. O pedido é analisado '
              'por um coordenador.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _filtroController,
              decoration: const InputDecoration(
                labelText: 'Buscar pelo nome do grupo',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _filtro = value.trim()),
            ),
            const SizedBox(height: 12),
            ..._gruposAbertos(grupos),
          ],
        ),
      ),
    );
  }

  List<Widget> _minhasSolicitacoes(
    AsyncValue<List<MinhaSolicitacaoModel>> minhas,
  ) {
    final items = minhas.valueOrNull ?? const <MinhaSolicitacaoModel>[];
    if (items.isEmpty) return const [];
    return [
      Text(
        'Minhas solicitações',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      for (final solicitacao in items)
        Card(
          child: ListTile(
            leading: Icon(_iconeStatus(solicitacao.status)),
            title: Text(solicitacao.grupoNome),
            subtitle: Text(_descricaoStatus(solicitacao)),
            trailing:
                solicitacao.podeCancelar
                    ? TextButton(
                      onPressed: () => _cancelar(solicitacao),
                      child: const Text('Cancelar'),
                    )
                    : null,
          ),
        ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _gruposAbertos(AsyncValue<List<GrupoAbertoModel>> grupos) {
    return grupos.when(
      loading:
          () => const [
            Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
      error:
          (error, _) => [
            _Aviso(
              icone: Icons.cloud_off_outlined,
              texto: mensagemErroSolicitacao(error),
              acao: TextButton(
                onPressed: _recarregar,
                child: const Text('Tentar novamente'),
              ),
            ),
          ],
      data: (items) {
        if (items.isEmpty) {
          return const [
            _Aviso(
              icone: Icons.group_off_outlined,
              texto:
                  'Nenhum grupo está aceitando solicitações no momento. '
                  'Você também pode pedir ao coordenador que o convide '
                  'pelo seu e-mail.',
            ),
          ];
        }
        final filtro = _filtro.toLowerCase();
        final filtrados =
            items.where((g) => g.nome.toLowerCase().contains(filtro)).toList();
        if (filtrados.isEmpty) {
          return const [
            _Aviso(
              icone: Icons.search_off,
              texto: 'Nenhum grupo encontrado com esse nome.',
            ),
          ];
        }
        return [
          for (final grupo in filtrados)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.music_note)),
                title: Text(
                  grupo.nome,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle:
                    grupo.descricao == null || grupo.descricao!.trim().isEmpty
                        ? null
                        : Text(grupo.descricao!),
                trailing: _acaoGrupo(grupo),
              ),
            ),
        ];
      },
    );
  }

  Widget _acaoGrupo(GrupoAbertoModel grupo) {
    if (grupo.meuStatus == StatusSolicitacao.pendente) {
      return const Chip(label: Text('Pendente'));
    }
    final fimEspera = grupo.podeSolicitarEm;
    if (!grupo.podeSolicitar() && fimEspera != null) {
      return Tooltip(
        message:
            'Seu pedido foi recusado. Você pode pedir de novo a partir de '
            '${formatarData(fimEspera)}.',
        child: Chip(label: Text('A partir de ${formatarData(fimEspera)}')),
      );
    }
    return FilledButton.tonal(
      onPressed: () => _solicitar(grupo),
      child: const Text('Solicitar'),
    );
  }

  IconData _iconeStatus(StatusSolicitacao status) => switch (status) {
    StatusSolicitacao.pendente => Icons.hourglass_top,
    StatusSolicitacao.aprovada => Icons.check_circle_outline,
    StatusSolicitacao.recusada => Icons.block,
    StatusSolicitacao.cancelada => Icons.cancel_outlined,
  };

  String _descricaoStatus(MinhaSolicitacaoModel solicitacao) {
    switch (solicitacao.status) {
      case StatusSolicitacao.pendente:
        return 'Aguardando um coordenador · pedido em '
            '${formatarData(solicitacao.criadaEm)}';
      case StatusSolicitacao.aprovada:
        return 'Aprovada · o grupo já aparece em Meus Grupos';
      case StatusSolicitacao.recusada:
        final fim = solicitacao.podeSolicitarEm;
        return fim == null
            ? 'Recusada'
            : 'Recusada · você pode pedir de novo a partir de '
                '${formatarData(fim)}';
      case StatusSolicitacao.cancelada:
        return 'Cancelada';
    }
  }
}

class _Aviso extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Widget? acao;

  const _Aviso({required this.icone, required this.texto, this.acao});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(
            icone,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
          if (acao != null) ...[const SizedBox(height: 8), acao!],
        ],
      ),
    );
  }
}

/// Result of the request dialog; null means the user gave up.
class _Pedido {
  final String? mensagem;
  const _Pedido(this.mensagem);
}

class _SolicitarEntradaDialog extends StatefulWidget {
  final String nomeGrupo;

  const _SolicitarEntradaDialog({required this.nomeGrupo});

  @override
  State<_SolicitarEntradaDialog> createState() =>
      _SolicitarEntradaDialogState();
}

class _SolicitarEntradaDialogState extends State<_SolicitarEntradaDialog> {
  final _mensagemController = TextEditingController();

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  void _enviar() {
    final texto = _mensagemController.text.trim();
    Navigator.pop(context, _Pedido(texto.isEmpty ? null : texto));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Entrar em ${widget.nomeGrupo}'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Um coordenador do grupo verá seu nome e sua foto e vai '
              'aprovar ou recusar o pedido.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _mensagemController,
              decoration: const InputDecoration(
                labelText: 'Mensagem (opcional)',
                hintText: 'Ex.: Sou tenor do coral das 19h',
                border: OutlineInputBorder(),
              ),
              maxLength: 280,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _enviar, child: const Text('Enviar pedido')),
      ],
    );
  }
}
