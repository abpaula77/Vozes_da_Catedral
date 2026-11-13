import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/groups_provider.dart';
import '../data/solicitacoes_provider.dart';
import '../domain/group_model.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncGroups(showSuccess: false);
    });
  }

  Future<void> _syncGroups({bool showSuccess = true}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      await ref.read(gruposServiceProvider).syncGrupos();
      // Refresh the pending-request badges together with the groups.
      if (mounted) ref.invalidate(contagemSolicitacoesProvider);
      if (mounted && showSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Grupos sincronizados.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sincronizar grupos: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gruposAsync = ref.watch(gruposProvider);
    // Badges are optional: if the count fails, they are simply not shown.
    final pendentesPorGrupo =
        ref.watch(contagemSolicitacoesProvider).valueOrNull ??
        const <String, int>{};
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Grupos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: 'Encontrar grupos',
            onPressed: () => context.pushExploreGroups(),
          ),
          IconButton(
            icon:
                _isSyncing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.sync),
            tooltip: 'Sincronizar grupos',
            onPressed: _isSyncing ? null : _syncGroups,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: gruposAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar grupos: $e')),
        data: (grupos) {
          if (grupos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum grupo ainda.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie um grupo ou encontre um para participar.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.pushExploreGroups(),
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Encontrar um grupo'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: grupos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final grupo = grupos[index];
              return _GrupoCard(
                grupo: grupo,
                pendentes: pendentesPorGrupo[grupo.id] ?? 0,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Novo Grupo'),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nomeController = TextEditingController();
    final descController = TextEditingController();
    var isCreating = false;
    String? creationError;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('Novo Grupo'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do grupo',
                          hintText: 'ex: Coral 19h',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      if (creationError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Erro ao criar grupo: $creationError',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isCreating ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed:
                          isCreating
                              ? null
                              : () async {
                                final nome = nomeController.text.trim();
                                if (nome.isEmpty) return;
                                setDialogState(() => isCreating = true);
                                try {
                                  await ref
                                      .read(gruposServiceProvider)
                                      .createGrupo(
                                        nome: nome,
                                        descricao: descController.text.trim(),
                                      );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  ref.invalidate(gruposProvider);
                                } catch (error) {
                                  if (ctx.mounted) {
                                    setDialogState(() {
                                      creationError = error.toString();
                                    });
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setDialogState(() => isCreating = false);
                                  }
                                }
                              },
                      child:
                          isCreating
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Criar'),
                    ),
                  ],
                ),
          ),
    );
  }
}

class _GrupoCard extends StatelessWidget {
  final GrupoModel grupo;

  /// Pending join requests (only reported for groups the user coordinates).
  final int pendentes;

  const _GrupoCard({required this.grupo, this.pendentes = 0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatar = CircleAvatar(
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.music_note,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
    return Card(
      child: ListTile(
        leading:
            pendentes > 0
                ? Tooltip(
                  message:
                      pendentes == 1
                          ? '1 solicitação de entrada pendente'
                          : '$pendentes solicitações de entrada pendentes',
                  child: Badge.count(count: pendentes, child: avatar),
                )
                : avatar,
        title: Text(
          grupo.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: grupo.descricao != null ? Text(grupo.descricao!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoleBadge(papel: grupo.meuPapel),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.goGroupDetail(grupo.id),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final PapelGrupo papel;
  const _RoleBadge({required this.papel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCoordenador = papel.isCoordenador;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color:
            isCoordenador
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCoordenador ? 'Coordenador' : 'Membro',
        style: theme.textTheme.labelSmall?.copyWith(
          color:
              isCoordenador
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
