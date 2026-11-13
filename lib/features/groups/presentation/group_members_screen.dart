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
      builder: (_) => _AddMemberDialog(grupoId: grupoId),
    );
    if (invitation == null || !context.mounted) return;

    try {
      final service = ref.read(gruposServiceProvider);
      if (invitation.userId case final userId?) {
        await service.addMembroPorId(
          grupoId: grupoId,
          userId: userId,
          papel: invitation.papel.value,
        );
      } else {
        await service.addMembro(
          grupoId: grupoId,
          email: invitation.email!,
          papel: invitation.papel.value,
        );
      }
      ref.invalidate(membrosGrupoProvider(grupoId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              invitation.displayName == null
                  ? 'Solicitação processada. Se a conta estiver cadastrada, foi adicionada ao grupo.'
                  : '${invitation.displayName} foi adicionado ao grupo.',
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
  final String? email;
  final String? userId;
  final String? displayName;
  final PapelGrupo papel;

  const _MemberInvitation.byEmail(this.email, this.papel)
    : userId = null,
      displayName = null;

  const _MemberInvitation.byUser(this.userId, this.displayName, this.papel)
    : email = null;
}

enum _AddMemberMethod { email, registeredUser }

class _AddMemberDialog extends ConsumerStatefulWidget {
  final String grupoId;

  const _AddMemberDialog({required this.grupoId});

  @override
  ConsumerState<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<_AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  PapelGrupo _papel = PapelGrupo.membro;
  _AddMemberMethod _method = _AddMemberMethod.email;
  Future<List<UsuarioDisponivelGrupoModel>>? _usuariosFuture;
  String _query = '';

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectMethod(_AddMemberMethod method) {
    setState(() {
      _method = method;
      if (method == _AddMemberMethod.registeredUser) {
        _usuariosFuture ??= ref
            .read(gruposServiceProvider)
            .getUsuariosDisponiveis(widget.grupoId);
      }
    });
  }

  void _retryUsers() {
    setState(() {
      _usuariosFuture = ref
          .read(gruposServiceProvider)
          .getUsuariosDisponiveis(widget.grupoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar membro'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 480,
          height: 440,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_AddMemberMethod>(
                segments: const [
                  ButtonSegment(
                    value: _AddMemberMethod.email,
                    icon: Icon(Icons.email_outlined),
                    label: Text('Por e-mail'),
                  ),
                  ButtonSegment(
                    value: _AddMemberMethod.registeredUser,
                    icon: Icon(Icons.people_outline),
                    label: Text('Usuário cadastrado'),
                  ),
                ],
                selected: {_method},
                onSelectionChanged:
                    (selection) => _selectMethod(selection.first),
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
              const SizedBox(height: 16),
              Expanded(child: _methodContent()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_method == _AddMemberMethod.email)
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                _MemberInvitation.byEmail(_emailController.text.trim(), _papel),
              );
            },
            child: const Text('Adicionar'),
          ),
      ],
    );
  }

  Widget _methodContent() {
    if (_method == _AddMemberMethod.email) {
      return Align(
        alignment: Alignment.topCenter,
        child: TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty || !email.contains('@')) {
              return 'Informe um e-mail válido.';
            }
            return null;
          },
        ),
      );
    }

    final usersFuture = _usuariosFuture;
    if (usersFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<UsuarioDisponivelGrupoModel>>(
      future: usersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Erro ao carregar usuários: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: _retryUsers,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data ?? const <UsuarioDisponivelGrupoModel>[];
        final query = _query.toLowerCase();
        final filteredUsers =
            users
                .where((user) => user.nome.toLowerCase().contains(query))
                .toList();

        if (users.isEmpty) {
          return const Center(
            child: Text('Não há outros usuários cadastrados para adicionar.'),
          );
        }

        return Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar usuário',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  filteredUsers.isEmpty
                      ? const Center(child: Text('Nenhum usuário encontrado.'))
                      : ListView.separated(
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                user.nome.isEmpty
                                    ? '?'
                                    : user.nome[0].toUpperCase(),
                              ),
                            ),
                            title: Text(user.nome),
                            trailing: const Icon(Icons.person_add_alt_1),
                            onTap:
                                () => Navigator.pop(
                                  context,
                                  _MemberInvitation.byUser(
                                    user.id,
                                    user.nome,
                                    _papel,
                                  ),
                                ),
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}
