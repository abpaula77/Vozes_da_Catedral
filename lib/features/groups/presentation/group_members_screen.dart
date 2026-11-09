import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/groups_provider.dart';
import '../domain/group_model.dart';

class GroupMembersScreen extends ConsumerWidget {
  final String grupoId;

  const GroupMembersScreen({super.key, required this.grupoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grupos = ref.watch(gruposProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    return grupos.when(
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Erro ao carregar grupo: $error')),
          ),
      data: (items) {
        final grupo = items.where((item) => item.id == grupoId).firstOrNull;
        if (grupo == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Grupo não encontrado.')),
          );
        }

        final membros = ref.watch(membrosGrupoProvider(grupoId));
        return Scaffold(
          appBar: AppBar(
            title: Text('Membros de ${grupo.nome}'),
            actions: [
              if (grupo.isCoordenador)
                IconButton(
                  tooltip: 'Adicionar membro',
                  onPressed: () => _addMember(context, ref),
                  icon: const Icon(Icons.person_add_alt_1),
                ),
            ],
          ),
          body: membros.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, _) =>
                    Center(child: Text('Erro ao carregar membros: $error')),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('Este grupo não tem membros.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = items[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          member.nome.isEmpty
                              ? '?'
                              : member.nome[0].toUpperCase(),
                        ),
                      ),
                      title: Text(member.nome),
                      subtitle: Text(member.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RoleLabel(papel: member.papel),
                          if (grupo.isCoordenador &&
                              member.userId != currentUserId)
                            IconButton(
                              tooltip: 'Remover membro',
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed:
                                  () => _removeMember(context, ref, member),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final invitation = await showDialog<_MemberInvitation>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
    if (invitation == null || !context.mounted) return;

    try {
      await ref
          .read(gruposServiceProvider)
          .addMembro(
            grupoId: grupoId,
            email: invitation.email,
            papel: invitation.papel.value,
          );
      ref.invalidate(membrosGrupoProvider(grupoId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${invitation.email} adicionado ao grupo.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar membro: $error')),
        );
      }
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    MembroGrupoModel member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Remover membro?'),
            content: Text('${member.nome} perderá acesso a este grupo.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(gruposServiceProvider)
          .removeMembro(grupoId: grupoId, userId: member.userId);
      ref.invalidate(membrosGrupoProvider(grupoId));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover membro: $error')),
        );
      }
    }
  }
}

class _RoleLabel extends StatelessWidget {
  final PapelGrupo papel;

  const _RoleLabel({required this.papel});

  @override
  Widget build(BuildContext context) {
    final isCoordinator = papel.isCoordenador;
    return Chip(
      label: Text(isCoordinator ? 'Coordenador' : 'Membro'),
      visualDensity: VisualDensity.compact,
      backgroundColor:
          isCoordinator
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _MemberInvitation {
  final String email;
  final PapelGrupo papel;

  const _MemberInvitation(this.email, this.papel);
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  PapelGrupo _papel = PapelGrupo.membro;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar membro'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Informe um e-mail válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PapelGrupo>(
              value: _papel,
              decoration: const InputDecoration(
                labelText: 'Papel no grupo',
                border: OutlineInputBorder(),
              ),
              items:
                  PapelGrupo.values
                      .map(
                        (papel) => DropdownMenuItem(
                          value: papel,
                          child: Text(
                            papel.isCoordenador ? 'Coordenador' : 'Membro',
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (papel) {
                if (papel != null) setState(() => _papel = papel);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _MemberInvitation(_emailController.text.trim(), _papel),
            );
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
