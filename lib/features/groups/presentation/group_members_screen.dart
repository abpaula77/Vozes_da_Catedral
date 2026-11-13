import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/groups_provider.dart';
import '../domain/group_model.dart';
import '../../profile/presentation/user_avatar.dart';
import 'join_requests_widgets.dart';

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
              final header = <Widget>[
                if (grupo.isCoordenador) ...[
                  AceitaSolicitacoesSwitch(grupoId: grupoId),
                  SolicitacoesPendentesSection(grupoId: grupoId),
                ],
              ];
              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...header,
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Este grupo não tem membros.')),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: header.length + items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index < header.length) return header[index];
                  final member = items[index - header.length];
                  return Card(
                    child: ListTile(
                      leading: UserAvatar(nome: member.nome, foto: member.foto),
                      title: Text(member.nome),
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
        // The RPC intentionally does not reveal whether the e-mail exists.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Convite processado. Se houver uma conta com esse e-mail, '
              'ela foi adicionada ao grupo.',
            ),
          ),
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

/// Invites a member by exact e-mail only (issue #24): coordinators can no
/// longer browse the list of registered users.
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _MemberInvitation(_emailController.text.trim(), _papel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar membro'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informe o e-mail completo da conta. A pessoa precisa já '
                'ter se cadastrado no app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Adicionar')),
      ],
    );
  }
}
