import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../songs/presentation/songs_screen.dart';
import '../data/groups_provider.dart';
import '../domain/group_model.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String grupoId;

  const GroupDetailScreen({super.key, required this.grupoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gruposAsync = ref.watch(gruposProvider);
    final theme = Theme.of(context);

    return gruposAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erro: $e'))),
      data: (grupos) {
        final grupo = grupos.where((g) => g.id == grupoId).firstOrNull;
        if (grupo == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Grupo não encontrado.')),
          );
        }
        return _GroupDetailView(grupo: grupo);
      },
    );
  }
}

class _GroupDetailView extends ConsumerStatefulWidget {
  final GrupoModel grupo;
  const _GroupDetailView({required this.grupo});

  @override
  ConsumerState<_GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends ConsumerState<_GroupDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grupo = widget.grupo;

    return Scaffold(
      appBar: AppBar(
        title: Text(grupo.nome),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.music_note), text: 'Hinário'),
            Tab(icon: Icon(Icons.event), text: 'Celebrações'),
          ],
        ),
        actions: [
          if (grupo.isCoordenador)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: 'Gerenciar membros',
              onPressed: () => _showMembrosSheet(context),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SongsScreen(
            grupoId: grupo.id,
            isCoordenador: grupo.isCoordenador,
          ),
          _CelebracoesTab(grupoId: grupo.id, isCoordenador: grupo.isCoordenador),
        ],
      ),
    );
  }

  void _showMembrosSheet(BuildContext context) {
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Adicionar membro',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail do membro',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ref.read(gruposServiceProvider).addMembro(
                        grupoId: widget.grupo.id,
                        email: email,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$email adicionado ao grupo.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebracoesTab extends StatelessWidget {
  final String grupoId;
  final bool isCoordenador;

  const _CelebracoesTab(
      {required this.grupoId, required this.isCoordenador});

  @override
  Widget build(BuildContext context) {
    // Will be implemented in Task 7
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Celebrações — Task 7',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Em desenvolvimento',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}
